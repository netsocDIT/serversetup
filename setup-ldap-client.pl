#!/usr/bin/perl

###### Yes i know, a horrible way to do it in perl, however, i just need it to work
## i'll come back and clean it up later and do it properly

$configsTempDir = 'configs-tmp';
$configsDir = 'configs';

system("rm $configsTempDir/*");
system("cp -r $configsDir/ldap $configsTempDir");


#Don't prompt when installing packages
system("debconf-set-selections ldap/configs/debconf-defaults");


#Install packages
system("apt-get install libpam-ldapd") ;
system("chmod 700 /etc/ldap/ldap.conf");
system("apt-get install sudo-ldap rcconf");
system("rcconf -off nscd");
system("/etc/init.d/nscd stop");


print("hostname: ");
chomp($hostname);

print("nslcd password: ");
chomp($nslcdPassword);


print("Sudo user password: ");
chomp($sudoPassword);




#Setup configs
system("sed -i 's/%hostname%/$hostname/g' $configsTempDir/ldap/*")
system("sed -i 's/%sudopassword%/$sudoPassword/g' $configsTempDir/ldap/*")
system("sed -i 's/%nslcdpassword%/$nslcdPassword/g' $configsTempDir/ldap/*")
