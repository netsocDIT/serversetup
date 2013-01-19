#!/bin/bash


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
apt-get -y install libpam-ldapd libstring-random-perl libdigest-sha1-perl pwgen ldap-utils sudo-ldap



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
	umaskold=`umask`
	umask 077
	touch temp/ldap-client/sudopassword
	touch temp/ldap-client/nsspassword
	nssPassword=`pwgen -s 20 1| tee temp/ldap-client/nsspassword`
	sudoPassword=`pwgen -s 20 1| tee temp/ldap-client/sudopassword`
	umask $umaskold
	
	nssssha=`cat temp/ldap-client/nsspassword | helpers/ssha-generate.pl | base64`
	sudossha=`cat temp/ldap-client/sudopassword | helpers/ssha-generate.pl | base64`
	sed -i "s/%password%/$nssssha/g" temp/ldap-client/nssuser.ldif
	sed -i "s/%password%/$sudossha/g" temp/ldap-client/sudouser.ldif

	echo "Do you wish to create ldap accounts now? (y/n)"
	read confirm

	if [ "$confirm" != "y" ]; then
		exit 1
	fi

	ldapserver="ldap.netsoc.dit.ie"
	#ldapserver="192.168.1.48"

	echo "Ldap server: default $ldapserver"
	read inputldapserver

	if [ $inputldapserver ] ; then
		ldapserver=$inputldapserver
	fi	

	echo "server server selected: " $ldapserver

	echo "Now creating ldap accounts...please enter ldap admin password"
	cat temp/ldap-client/nssuser.ldif temp/ldap-client/sudouser.ldif | ldapadd -v  -D "cn=admin,dc=netsoc,dc=dit,dc=ie" -x -W -H ldap://$ldapserver

else
	if [ "$manualOrGenerate" == "e" ]; then 
		echo "Nslcd password: "
		read nssPassword

		echo "Sudo password"
		read sudoPassword
	else
		echo "invalid option, exiting"
		exit 1
	fi
fi



#Setup configs
sed -i "s/%sudopassword%/$sudoPassword/g" temp/ldap-client/ldap.conf
sed -i  "s/%nslcdpassword%/$nssPassword/g" temp/ldap-client/nslcd.conf




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
