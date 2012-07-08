#/bin/bash

if [ `id -u` -ne 0 ]; then
	echo "Must be root to run this script"
	exit 1
fi


if [ -z $3 ] ; then
	echo -e  "\nYou have not specified a wp-content directory, .htaccess file and mysqldump file to restore. Please specify "
	echo "./webserver-setup.sh /path/to/wp-content /path/to/.htaccess /path/to/sqldump"
	echo "Do you want to continue anyway? (y/n)"
	read continueWithoutBackupFiles
	
	if [ "$continueWithoutBackupFiles" != "y" ]; then
		exit 1
	fi
	
else
	wpcontentpath=$1
	htaccesspath=$2
	sqlrestorepath=$3
fi


# Check is wp-content keyword in the .htaccess path (incase they mixed up which one goes first)
if echo $htaccesspath | grep -q wp-content
then
	echo "WARNING: 'wp-content' detected in the .htaccecss path, did you switch your options around?"
	echo "Your .htaccess path is $htaccesspath "
	echo "continue? (y/n)"
	read continueAnyway

	if [ "$continueAnyway" != "y" ]; then
		exit 1
	fi
	
fi


# Check is htaccess keyword in the wp-content path (incase they mixed up which one goes first)
if echo $wpcontentpath | grep -q htaccess
then
	echo "WARNING: 'htaccess' detected in the wp-content path, did you switch your options around?"
	echo "Your wp-content path is $wpcontentpath"
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

# cp config to temp
cp -r configs/webserver temp/webserver

apt-get update
apt-get install pwgen

# Setup Mysql passwords - important to preseed the mysql root password for install
mysqlwordpresspassword=`pwgen -s 30 1 | tee /etc/mysqlwordpresspassword`
chmod 700 /etc/mysqlwordpresspassword
sed -i "s/%mysql-wordpress-password%/$mysqlwordpresspassword/g" temp/webserver/wordpress/wp-config.php
sed -i "s/%mysql-wordpress-password%/$mysqlwordpresspassword/g" temp/webserver/wordpress.sql

mysqlrootpassword=`pwgen -s 30 1 | tee /etc/mysqlrootpassword`
chmod 700 /etc/mysqlrootpassword
sed -i "s/%mysql-root-password%/$mysqlrootpassword/g" temp/webserver/debconf-defaults


# Update- set mysql root password and install packages
debconf-set-selections < temp/webserver/debconf-defaults
apt-get -y install apache2 mysql-server php5 phpmyadmin php5-ldap apache2-mpm-itk php5-mysql php5-mcrypt php5-ldap rsync ca-certificates



# Setup Users
mkdir /var/www/wordpress /var/www/forum /var/www/wiki
useradd wordpress -d /var/www/wordpress -s /bin/false
useradd forum -d /var/www/forum -s /bin/false
useradd wiki -d /var/www/wiki -s /bin/false

# Setup apache virtualhost files
cp temp/webserver/apache/ports.conf /etc/apache2/ports.conf
cp temp/webserver/apache/phpmyadmin.conf /etc/apache2/conf.d/phpmyadmin.conf
rm /etc/apache2/sites-available/*
cp temp/webserver/apache/default /etc/apache2/sites-available/default
cp temp/webserver/apache/wordpress /etc/apache2/sites-available/wordpress
#cp temp/webserver/apache/forum /etc/apache2/sites-available/forum
#cp temp/webserver/apache/wiki /etc/apache2/sites-available/wiki
a2ensite default
a2ensite wordpress
#a2ensite forum
#a2ensite wiki

a2enmod ssl
a2enmod rewrite
a2enmod headers
a2enmod expires

# Install latest wordpress
wget -4 -O temp/webserver/latest.tar.gz http://wordpress.org/latest.tar.gz
tar -zxvf temp/webserver/latest.tar.gz -C temp/webserver/.
cp -r temp/webserver/wordpress/* /var/www/wordpress/.
cp temp/webserver/wordpress/wp-config.php /var/www/wordpress/wp-config.php
echo -e  "<?php\n `wget -4 https://api.wordpress.org/secret-key/1.1/salt/ -O -  -q`\n?>"  > temp/webserver/wordpress/wp-keys.php
cp temp/webserver/wordpress/wp-keys.php /var/www/wordpress/wp-keys.php

mysql -u root -p$mysqlrootpassword < temp/webserver/wordpress.sql
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
chown -R wiki:wiki /var/www/wiki
chown -R forum:forum /var/www/forum
chmod 700 /var/www/forum
chmod 700 /var/www/wordpress
chmod 700 /var/www/wiki
/etc/init.d/apache2 restart
