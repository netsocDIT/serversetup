#!/usr/bin/bash

configsTempDir= 'configs-tmp';
configsDir= 'configs';

rm $configsTempDir/*
cp -r $configsDir/ldap $configsTempDir

debconf-set-selections ldap/configs/debconf-defaults
apt-get install libpam-ldapd 
chmod 700 /etc/ldap/ldap.conf




#Install packages
system("apt-get install libpam-ldapd") ;
system("chmod 700 /etc/ldap/ldap.conf");
system("apt-get install sudo-ldap rcconf");
system("rcconf -off nscd");
system("/etc/init.d/nscd stop");


echo "Enter Hostname: "
read hostname

echo "Nslcd password: "
read nslcdPassword

echo "Sudo password"
read sudoPassword




#Setup configs
sed -i 's/%hostname%/$hostname/g' $configsTempDir/ldap/*
sed -i 's/%sudopassword%/$sudoPassword/g' $configsTempDir/ldap/*
sed -i 's/%nslcdpassword%/$nslcdPassword/g' $configsTempDir/ldap/*
