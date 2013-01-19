#/bin/bash

if [ `id -u` -ne 0 ]; then
	echo "Must be root to run this script"
	exit 1
fi


if [ -z $3 ] ; then
	echo -e  "\nYou have not specified a backup "
	echo "./webserver-setup.sh /path/to/wp-content /path/to/.htaccess /path/to/sqldump"
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
mysqlwikipassword=`pwgen -s 30 1 | tee /etc/mysqlwikipassword`
chmod 700 /etc/mysqlwikipassword
sed -i "s/%mysql-wiki-password%/$mysqlwikipassword/g" temp/webserver/wiki/LocalSettings.php
sed -i "s/%mysql-wiki-password%/$mysqlwikipassword/g" temp/webserver/mysql-recreate-wiki-db-user.sql

mysql --force -u root -p$mysqlrootpassword < temp/webserver/mysql-recreate-wiki-db-user.sql


# Setup Users
mkdir /var/www/wiki 
useradd wiki -d /var/www/wiki -s /bin/false

# Setup apache virtualhost files
cp temp/webserver/apache/wiki /etc/apache2/sites-available/wiki

a2ensite wiki

a2enmod ssl
a2enmod rewrite
a2enmod headers
a2enmod expires

exit












# Install latest wordpress
wget -4 -O temp/webserver/latest.tar.gz http://wordpress.org/latest.tar.gz
tar -zxf temp/webserver/latest.tar.gz -C temp/webserver/.
cp -r temp/webserver/wordpress/* /var/www/wordpress/.
cp temp/webserver/wordpress/wp-config.php /var/www/wordpress/wp-config.php
echo -e  "<?php\n `wget -4 https://api.wordpress.org/secret-key/1.1/salt/ -O -  -q`\n?>"  > temp/webserver/wordpress/wp-keys.php
if ! grep -q "SECURE_AUTH_SALT" temp/webserver/wordpress/wp-keys.php; then
	echo "Error, donloading of wordpress secret-key salts failed"
	echo "Continue? y/n"
	read continue
	if [ "$continue" != "y" ]; then
		exit
	fi
fi

#Copy over secret key salts to wordpress dir
cp temp/webserver/wordpress/wp-keys.php /var/www/wordpress/wp-keys.php


#Restore mysql restore database
mysql -u wordpress -p$mysqlwordpresspassword wordpress < $sqlrestorepath

if [ -d "$wpcontentpath" ]; then
	echo "Now restoring wp-content - removing default wp-content and copying backup in"
	rm -rf /var/www/wordpress/wp-content
	cp -r $wpcontentpath /var/www/wordpress/.
	echo ...done
else
	echo "ERROR wp-content path: $wpcontentpath doesn't exist/not a directory!"
fi

if [ -f "$htaccesspath" ]; then
	echo "Now restoring .htaccess"
	cp $htaccesspath /var/www/wordpress/.htaccess
	echo ...done
else
	echo "ERROR .htaccess path: $htaccesspath doesn't exist/not a file!"
fi

chown -R wordpress:wordpress /var/www/wordpress
chmod 700 /var/www/wordpress

/etc/init.d/apache2 restart
