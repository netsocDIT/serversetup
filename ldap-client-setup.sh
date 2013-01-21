#!/bin/bash
# cd to dir script is run from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

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

#ldap-client dir exists
if [ -d "temp/ldap-client" ]; then

	echo  "Cleaning up old config files"
	rm -r "temp/ldap-client"
fi


cp -r configs/ldap-client/ temp/ldap-client

apt-get update
debconf-set-selections temp/ldap-client/debconf-defaults
apt-get -y install libpam-ldapd libstring-random-perl libdigest-sha1-perl pwgen ldap-utils sudo-ldap php5-cli php5-ldap



systemHostname=`hostname`

echo "Enter Hostname: empty for ($systemHostname)"
read hostname

if [ -z $hostname ]; then
	hostname=$systemHostname
fi

sed -i "s/%hostname%/$hostname/g" temp/ldap-client/*


echo "Would you like to (g)enerate and create ldap account automatically or (e)nter password manually" 
read manualOrGenerate

if [ "$manualOrGenerate" == "g" ] ; then

	ldapserver="ldap.netsoc.dit.ie"
	echo "Ldap server: default $ldapserver"
	read inputldapserver

	if [ $inputldapserver ] ; then
		ldapserver=$inputldapserver
	fi	

	echo "server server selected: " $ldapserver


	echo "Reset password if service/machine account exist? (y/n)" 
	read resetpasswordifneeded

	umaskold=`umask`
	umask 077
	cat /dev/null > temp/ldap-client/sudopassword
	cat /dev/null > temp/ldap-client/nslcdpassword

	echo "Now creating ldap accounts...please enter ldap admin password twice (once for nslcd, once for sudo)"

	while [ "$success1" != true ]; do
		echo "creating nslcd account...";
		if [ "$resetpasswordifneeded" = "y" ]; then
			helpers/machine-manage.php --add-service -s nslcd -m $hostname -h $ldapserver --force > temp/ldap-client/nslcdpassword
		else
			helpers/machine-manage.php --add-service -s nslcd -m $hostname -h $ldapserver  > temp/ldap-client/nslcdpassword
		fi
		if [ "$?" != 0 ];then
			echo "something went wrong. Do you want to try that again (y/n) (if you don't, we'll quit now) "
			read tryagain
			if [ "$tryagain" != "y" ]; then
				exit 1
			fi
		else
			success1=true
			nslcdPassword=`cat temp/ldap-client/nslcdpassword | grep ^password: | sed 's/password: //'`
		fi
	done

	while [ "$success2" != true ]; do
		echo "creating sudo account...";
		if [ "$resetpasswordifneeded" = "y" ]; then
			helpers/machine-manage.php --add-service -s sudo -m $hostname -h $ldapserver --force > temp/ldap-client/sudopassword
		else
			helpers/machine-manage.php --add-service -s sudo -m $hostname -h $ldapserver  > temp/ldap-client/sudopassword
		fi
		if [ "$?" != 0 ];then
			echo "something went wrong. Do you want to try that again (y/n) (if you don't, we'll quit now) "
			read tryagain
			if [ "$tryagain" != "y" ]; then
				exit 1
			fi
		else
			success2=true
			sudoPassword=`cat temp/ldap-client/sudopassword | grep ^password: | sed 's/password: //'`
		fi
	done

else
	if [ "$manualOrGenerate" == "e" ]; then 
		echo "Nslcd password: "
		read nslcdPassword

		echo "Sudo password"
		read sudoPassword
	else
		echo "invalid option, exiting"
		exit 1
	fi
fi



#Setup configs
sed -i "s/%sudopassword%/$sudoPassword/g" temp/ldap-client/ldap.conf
sed -i  "s/%nslcdpassword%/$nslcdPassword/g" temp/ldap-client/nslcd.conf




echo -e  "\nConfigs written to 'temp'"
echo -e "Do you wish to copy files to system? (y/n) \r"
read confirm

if [ $confirm != "y" ]; then
	echo "Your files are in the 'temp' directory, now exiting"
	exit 0
fi


cp temp/ldap-client/ca.crt /etc/ldap/ca.crt
cp temp/ldap-client/nslcd.conf /etc/nslcd.conf
cp temp/ldap-client/ldap.conf /etc/ldap/ldap.conf
cp temp/ldap-client/nsswitch.conf /etc/nsswitch.conf

/etc/init.d/nslcd restart
/etc/init.d/nscd stop
getent passwd
getent group
/etc/init.d/nscd start

chmod 700 /etc/ldap/ldap.conf
chmod 700 /etc/nslcd.conf
