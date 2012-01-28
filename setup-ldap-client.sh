#!/usr/bin/bash

configsTempDir= 'configs-tmp';
configsDir= 'configs';

rm $configsTempDir/*
cp -r $configsDir/ldap $configsTempDir

debconf-set-selections ldap/configs/debconf-defaults
apt-get install libpam-ldapd 





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
sed -i 's/%hostname%/$hostname/g' $configsTempDir/ldap/*
sed -i 's/%sudopassword%/$sudoPassword/g' $configsTempDir/ldap/ldap.conf
sed -i 's/%nslcdpassword%/$nslcdPassword/g' $configsTempDir/ldap/nslcd.conf


cp $configsTempDir/ldap/ca.crt /etc/ldap/ca.crt
cp $configsTempDir/ldap/nslcd.conf /etc/nslcd.conf
cp $configsTempDir/ldap/ldap.conf /etc/ldap/ldap.conf


chmod 700 /etc/ldap/ldap.conf
chmod 700 /etc/nslcd.conf
