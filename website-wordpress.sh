#/bin/bash
# cd to dir script is run from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

if [ `id -u` -ne 0 ]; then
        echo "Must be root to run this script"
        exit 1
fi


if [ `id -u` -ne 0 ]; then
	echo "Must be root to run this script"
	exit 1
fi


if [ -z $3 ] ; then
	echo -e  "\nYou have not specified a wp-content directory, .htaccess file and mysqldump file to restore. Please specify "
	echo "./webserver-setup.sh /path/to/wp-content /path/to/.htaccess /path/to/sqldump"
	exit
	
else
	wpcontentpath=$1
	htaccesspath=$2
	sqlrestorepath=$3
fi


# Check if wp-content is in the wpcontentpath
if ! echo $wpcontentpath | grep -q wp-content
then
	echo "WARNING: The string 'wp-content' was not detected in the wp-content path"
	echo "Your wp-content path is $wpcontentpath are you sure this is right?"
	echo "continue? (y/n)"
	read continueAnyway

	if [ "$continueAnyway" != "y" ]; then
		exit 1
	fi
	
fi

# Check if .htaccess is in the htaccesspath
if ! echo $htaccesspath | grep -q htaccess
then
	echo "WARNING: The string 'htaccess' was not detected in the htaccess path"
	echo "Your htaccess path is $htaccesspath are you sure this is right?"
	echo "continue? (y/n)"
	read continueAnyway

	if [ "$continueAnyway" != "y" ]; then
		exit 1
	fi
	
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
mysqlwordpresspassword=`pwgen -s 30 1 | tee /etc/mysqlwordpresspassword`
chmod 700 /etc/mysqlwordpresspassword
sed -i "s/%mysql-wordpress-password%/$mysqlwordpresspassword/g" temp/webserver/wordpress/wp-config.php
sed -i "s/%mysql-wordpress-password%/$mysqlwordpresspassword/g" temp/webserver/mysql-recreate-wordpress-db-user.sql

mysql --force -u root -p$mysqlrootpassword < temp/webserver/mysql-recreate-wordpress-db-user.sql


# Setup Users
mkdir /var/www/wordpress 
useradd wordpress -d /var/www/wordpress -s /bin/false

# Setup apache virtualhost files
cp temp/webserver/apache/wordpress /etc/apache2/sites-available/wordpress

a2ensite wordpress

a2enmod ssl
a2enmod rewrite
a2enmod headers
a2enmod expires

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
