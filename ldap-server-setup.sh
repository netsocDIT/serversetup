#!/bin/bash

if [ "`whoami`" != "root"]; then
	echo "Must be root to run this script"
	exit 1
fi

ldapDir="/var/lib/ldap"
#ldapDir="/var/lib/ldap-netsoc"

#Check for old files + delete
if [ -d $ldapDir ]; then
	echo "WARNING: THIS IS PERMANENT"
	echo "ldap files already installed, do you wish to remove? (y/n)"
	read removeOld

	if [ "$removeOld" == "y" ];then
		rm -rf /var/lib/ldap/*
	fi
fi

#TODO set default options with debconf
apt-get install slapd ldap-utils

ldapadd -H ldapi:/// -Y EXTERNAL -f temp/ldap-server/sudo_schema.ldif
ldapadd -H ldapi:/// -Y EXTERNAL -f temp/ldap-server/tls.ldif
ldapadd -H ldapi:/// -Y EXTERNAL -f temp/ldap-server/disable_anon.ldif
