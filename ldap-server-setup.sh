#/bin/bash

if [ `id -u` -ne 0 ]; then
	echo "Must be root to run this script"
	exit 1
fi

if [ -z $1 ] ; then
	echo -e  "\nNo backup files specified to restore. If you wish to restore a database, type:"
	echo "./ldap-server-setup2.sh backupfile"
	echo "The backup file is an ldif format that would come from typing something like slapcat -b \"dc=netsoc,dc=dit,dc=ie\" > backupfile.ldif on the ldap server"
	echo "the cn=config file is included within this script and is not needed"
	exit
fi

restoredatabase=$1


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

#temp ldap-server2 dir exists
if [ -d "temp/ldap-server2" ]; then

	echo  "Cleaning up old config files"
	rm -r "temp/ldap-server2"
fi

#copy files
cp -r configs/ldap-server2 temp/ldap-server2



ldapDir="/var/lib/ldap-netsoc"

#Check for old files + delete
if [ -d $ldapDir ]; then
	echo "WARNING: THIS IS PERMANENT"
	echo "ldap files already installed, do you wish to remove? (y/n)"
	read removeOld

	if [ "$removeOld" == "y" ];then
		rm -rf $ldapDir/
	else
		exit
	fi
fi

mkdir $ldapDir

debconf-set-selections < temp/ldap-server2/debconf-defaults
apt-get update
apt-get -y install slapd ldap-utils pwgen

#TODO configure tls ldif file to contain the right location
#TODO handle tls certs/keys


#Restore old database

/etc/init.d/slapd stop
rm -rf /etc/ldap/slapd.d/*

echo "Now restoring cn=config"
slapadd -F /etc/ldap/slapd.d/ -n0 -l  temp/ldap-server2/cn.config.ldif
echo "Adding netsoc user objectClass schema..."
slapadd -n 0 < temp/ldap-server2/netsocuser_schema.ldif
echo "Adding sudo schema..."
slapadd -n 0 < temp/ldap-server2/sudo_schema.ldif

echo "Now restoring database contents"
slapadd -b "dc=netsoc,dc=dit,dc=ie" < $restoredatabase

echo "Fixing permissions..."
chown -R openldap:openldap /var/lib/ldap-netsoc/
chown -R openldap:openldap /etc/ldap/slapd.d/
/etc/init.d/slapd start
