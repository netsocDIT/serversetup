#!/bin/bash


if [ "`whoami`" != "root" ]; then
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


#ldap-client dir exists
if [ -d "temp/ldap-client" ]; then

	echo  "Cleaning up old config files"
	rm -r "temp/ldap-client"
fi


cp -r configs/ldap-client/ temp/ldap-client





debconf-set-selections temp/ldap-client/debconf-defaults
apt-get -y install libpam-ldapd 



systemHostname=`hostname`

echo "Enter Hostname: empty for ($systemHostname)"
read hostname

if [ -z $hostname ]; then
	hostname=$systemHostname
fi

echo "Nslcd password: "
read nslcdPassword

echo "Sudo password"
read sudoPassword




#Setup configs
sed -i "s/%hostname%/$hostname/g" temp/ldap-client/*
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

chmod 700 /etc/ldap/ldap.conf
chmod 700 /etc/nslcd.conf
