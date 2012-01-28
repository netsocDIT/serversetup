#!/usr/bin/perl 
use File::Copy;


#print "Setting up ssh server config + banner";

$configsTempDir = 'configs-tmp';
$configsDir = 'configs';


unless (-d $configsTempDir)
{
	print "Error - tmp directory missing - attempting to create directory \n";
	mkdir $configsTempDir;
}

print "Removing old files from tmp dir\n";
#system("rm $configsTempDir/*");


print "SSH LOGIN ACCESS: (admins) only / (all) users can login\n";
chomp($allowedUsers = <>);


while ($allowedUsers ne "all" && $allowedUsers ne "admins")
{
	print "Invalid input \n";
	print "SSH LOGIN ACCESS: (admins) only / (all) users can login\n";
	chomp($allowedUsers = <>);
}

print "allowedusers: $allowedUsers\n";

if ($allowedUsers eq "all")
{
uncomment #allow-login-all in ssh/sshd_config

}

#replace details of server in sshd_banner



#Copy config files to system
copy ("$configTemp/ssh/sshd_config" "/etc/ssh/sshd_config") or die "Copying of sshd config failed: $!";
copy ("$configTemp/ssh/sshd_banner" "/etc/ssh/sshd_banner") or die "Copying of sshd banner failed: $!";





