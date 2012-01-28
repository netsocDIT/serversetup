#!/usr/bin/bash


echo "unfinished + untested"

cp configs/ldap-client temp/ldap-client





debconf-set-selections ldap-client/configs/debconf-defaults
apt-get install libpam-ldap-clientd 



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
sed -i 's/%hostname%/$hostname/g' temp/ldap-client/*
sed -i 's/%sudopassword%/$sudoPassword/g' temp/ldap-client/ldap-client.conf
sed -i 's/%nslcdpassword%/$nslcdPassword/g' temp/ldap-client/nslcd.conf


#debug
exit 0


cp temp/ldap-client/ca.crt /etc/ldap-client/ca.crt
cp temp/ldap-client/nslcd.conf /etc/nslcd.conf
cp temp/ldap-client/ldap-client.conf /etc/ldap-client/ldap-client.conf


chmod 700 /etc/ldap-client/ldap-client.conf
chmod 700 /etc/nslcd.conf
