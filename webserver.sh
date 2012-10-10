#/bin/bash
#Setup 
#	Apache2
#	Plugins (like rewrite/headers etc)
#	mysql server (with password create/reset/purge ability)
#	NO SERVICES HERE (like forum/wiki)

if [ `id -u` -ne 0 ]; then
	echo "Must be root to run this script"
	exit 1
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
apt-get -y install pwgen


if dpkg -l | awk '{print $2}' | grep -q ^mysql-server$; then
mysqlinstalled="true"
	echo -e "\n\nmysql-server already installed"
	if [ -f /etc/mysqlrootpassword ]; then
		echo  "Root password saved in /etc/mysqlrootpassword"

		#TODO check if mysql-server is running?
		if [ ! -f /var/run/mysqld/mysqld.pid ]; then
			mysqlserveroffline=yes
			echo "mysql-server is offline. Start it to check if previous saved mysql root password works?"
			echo "You may say no and simply reset the root password later without checking whether the previous one works or not"
			
			echo -n "Start mysql server (y/n)? "
			read  startMysqlServer

			if [ "$startMysqlServer" = "y" ]; then
				/etc/init.d/mysql start
			fi
		fi

		# If server is STILL not running, ask should continue
		if [ "mysqlserveroffline" = "yes" ]; then
			if [ ! -f /var/run/mysqld/mysqld.pid ]; then
				echo -n "mysql server is still offline. continue anyway? (y/n) "
				read continueAnyway
				if [ "$continueAnyway" != "y"]; then exit; fi
			fi
		fi


		if echo exit | mysql -u root -p`cat /etc/mysqlrootpassword` 2> /dev/null ; then
			echo "Saved mysql root password is correct";
		else
			echo "Saved mysql root password is incorrect";
		fi
	else
		echo "Root password missing from /etc/mysqlrootpassword";
	fi

	echo -e "\n\nDo you wish to" 
	echo "(pk) Purge mysql server but keep old mysql root password,"
	echo "(pn) Purge mysql server and create a new password,"
	echo "(r)  Just reset mysql root password"; 
	echo "(n)  Nothing (to mysql server)"
	read nextAction
	if [ "$nextAction" = "pk" -o  "$nextAction" = "pn" -o "$nextAction" = "r" -o "$nextAction" = "n" ]; then 
		echo "i really can't be bothered figuring out how to do ( not (a or b or c)) so this will do " > /dev/null
	else
		echo "Invalid error, exiting";
		exit
	fi

fi

if [ "$nextAction" = "r" -o "$nextAction" = "pn" -o "$mysqlinstalled" != "true" ] ; then

	mysqlrootpassword=`pwgen -s 30 1 | tee /etc/mysqlrootpassword`
	chmod 700 /etc/mysqlrootpassword
fi

if [ "$nextAction" = "pk" ]; then
	mysqlrootpassword=`cat /etc/mysqlrootpassword`
fi


sed -i "s/%mysql-root-password%/$mysqlrootpassword/g" temp/webserver/debconf-defaults


if [ "$nextAction" = "pn" -o "$nextAction" = "pk" ]; then
	mysqlVersion=`dpkg -l | awk '{print $2}'| grep "mysql-server-[0-9]\+\.\?[0-9]*"`
	apt-get -y purge mysql-server $mysqlVersion
fi

if [ "$nextAction" = "r" ]; then
	/etc/init.d/mysql stop
	touch /tmp/reset-mysql-root.sql
	unlink /tmp/reset-mysql-root.sql
	touch /tmp/reset-mysql-root.sql
	chmod 700 /tmp/reset-mysql-root.sql
	chown mysql:mysql /tmp/reset-mysql-root.sql
	cat temp/webserver/reset-mysql-root.sql > /tmp/reset-mysql-root.sql
	sed -i "s/%mysql-root-password%/$mysqlrootpassword/g" /tmp/reset-mysql-root.sql
	mysqld_safe --init-file=/tmp/reset-mysql-root.sql &
	sleep 3;
	kill `cat /var/run/mysqld/mysqld.pid`
	rm -f /tmp/reset-mysql-root.sql
fi

# Update- set mysql root password and install packages
debconf-set-selections < temp/webserver/debconf-defaults
apt-get -y install apache2 mysql-server php5 php5-ldap apache2-mpm-itk php5-mysql php5-mcrypt php5-ldap rsync ca-certificates php5-curl bzip2 php5-imagick php5-gd

mkdir /etc/ssl/netsocWebserver/

# Setup apache virtualhost files
cp temp/webserver/apache/ports.conf /etc/apache2/ports.conf
cp temp/webserver/apache/default /etc/apache2/sites-available/default
cp temp/webserver/apache/chain.pem /etc/ssl/netsocWebserver/chain.pem

a2ensite default
a2enmod ssl
a2enmod rewrite
a2enmod headers
a2enmod expires

/etc/init.d/apache2 restart
/etc/init.d/mysql restart
