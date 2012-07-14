#/bin/bash

if [ `id -u` -ne 0 ]; then
	echo "Must be root to run this script"
	exit 1
fi

if [ -z $1 ] ; then
	echo "You have not specified a backup sql file to restore"
	echo "Usage ./website-forum.sh restorefile.sql"
	exit
	
else
	sqlrestorepath=$1
fi


#Config dir exists
if [ ! -d "configs" ]; then
	echo "Main configs dir missing. Can't do anything without it. This contains all the templates to deploy to the system"
	echo "If you have assumed you don't need this, you're wrong. Please put it back"
	exit 1
fi

#Temp dir exists
if [ ! -d "temp" ]; then
	mkdir temp
fi

chmod 700 temp

#temp webserver dir exists
if [ -d "temp/webserver" ]; then

	echo  "Cleaning up old config files"
	rm -r "temp/webserver"
fi

./webserver.sh

# cp config to temp
cp -r configs/webserver temp/webserver

mysqlrootpassword=`cat /etc/mysqlrootpassword`

# Setup Mysql passwords
mysqlforumpassword=`pwgen -s 30 1 | tee /etc/mysqlforumpassword`
chmod 700 /etc/mysqlforumpassword
sed -i "s/%mysql-forum-password%/$mysqlforumpassword/g" temp/webserver/forum/config.php
sed -i "s/%mysql-forum-password%/$mysqlforumpassword/g" temp/webserver/mysql-recreate-forum-db-user.sql

echo "Creating forum user + database and setting up permissions..."
mysql --force -u root -p$mysqlrootpassword < temp/webserver/mysql-recreate-forum-db-user.sql

# Restoring old database
mysql -u forum -p$mysqlforumpassword forum < $sqlrestorepath

netsocadminpassword=`pwgen -s 20 1| tee /etc/forum-netsocadminpassword`
chmod 700 /etc/forum-netsocadminpassword
netsocadminhash=`helpers/phpbbhash.php $netsocadminpassword| tee temp/webserver/forum/netsocadminhash`
sed -i "s#%netsocadmin-hash%#$netsocadminhash#g" temp/webserver/forum/resetnetsocadminlocal.sql


echo "Use ldap or mysql database for authentication?"
echo "If you pick mysql, a username + password will be suplied for you to login with"
echo "(l)ldap or (m)ysql?"

read ldapmethod

mysql -u forum -p$mysqlforumpassword forum < temp/webserver/forum/resetnetsocadminlocal.sql

# Set auth-method to mysql
if [ "$ldapmethod" == "m" ]; then
	sed -i "s/%auth-method%/db/g" temp/webserver/forum/config.sql
else
	sed -i "s/%auth-method%/ldap/g" temp/webserver/forum/config.sql
fi

echo "Now setting up ldap auth (this does not affect your option to use mysql or ldap previously"
echo "If you do not want to setup ldap for some reason, just fill in any/fake data"
echo "Just make sure if you want to enable ldap in the future, you change these values in the forum"

ldapserver="ldap.netsoc.dit.ie"

echo "Ldap server: default $ldapserver"
read inputldapserver

if [ $inputldapserver ] ; then
	ldapserver=$inputldapserver
fi	

echo "Ldap machine accoung login dn:"
read ldapusername

echo "Ldap Password"
read ldappassword


sed -i "s/%ldap-server%/$ldapserver/g" temp/webserver/forum/config.sql
sed -i "s/%ldap-username%/$ldapusername/g" temp/webserver/forum/config.sql
sed -i "s/%ldap-password%/$ldappassword/g" temp/webserver/forum/config.sql


mysql -u forum -p$mysqlforumpassword forum < temp/webserver/forum/config.sql

cp temp/webserver/apache/forum /etc/apache2/sites-available/forum

a2ensite forum

a2enmod ssl
a2enmod rewrite
a2enmod headers
a2enmod expires

mkdir /var/www/forum
useradd forum -d /var/www/forum -s /bin/false
chmod 700 /var/www/forum

# Install phpbb
wget -4 -O temp/webserver/phpbb.tar.bz2 http://www.phpbb.com/files/release/phpBB-3.0.10.tar.bz2
echo "extracting phpbb..."
tar -jxf temp/webserver/phpbb.tar.bz2 -C temp/webserver/.
echo "coping files to /var/www/forum"
cp -r temp/webserver/phpBB3/* /var/www/forum/.
echo "Copying over phpbb config.php file"
cp temp/webserver/forum/config.php /var/www/forum/.

rm -rf /var/www/forum/install

chown -R forum:forum /var/www/forum

/etc/init.d/apache2 restart

# Repeat local user + password we generated
if [ "$ldapmethod" == "m" ]; then
	echo "Generated local mysql user + pass..."
	echo "Username: netsocadmin"
	echo -e "Password: $netsocadminpassword\n\n"
fi

