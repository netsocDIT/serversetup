#/bin/bash

echo "finished, untested"

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


#temp ssh-server dir exists
if [ -d "temp/ssh-server" ]; then

	echo  "Cleaning up old config files"
	rm -r "temp/ssh-server"
fi


#copy files
cp -r configs/ssh-server temp/ssh-server



echo -e "\nSSH access? (admins) only / (all) users"
read allowedUsers


echo allowedusers: $allowedUsers



if [ $allowedUsers == "all" ]; then

	#uncomment #allow-login-all in ssh-server/ssh-serverd_config
	echo "test"
fi



systemHostname=`hostname`
echo -e "\nBanner Hostname. press enter for ($systemHostname)"
read hostname

if [ -z $hostname ]; then
	hostname=$systemHostname
fi




echo -e "\nBanner access (eg restricted, all members)"
read bannerAccess

echo -e "\nBanner description (eg, ldap server, main login server)"
read description

echo -e 

bannerip=`ifconfig | egrep -o "inet addr:[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}" | sed 's/^inet addr://'| grep -v 127.0.0.1| head -n 1`

echo "Banner IP (empty for $bannerip)"
read bannerIP


echo "Confirmation:"
echo "    ssh-server users allowed: $allowedUsers"
echo "      Banner hostname: $hostname"      
echo "   Banner description: $description"
echo "    Banner IP address: $bannerip"

echo -e "\nIs this correct? (y/n) \r"
read confirm

if [ $confirm != "y" ]; then
	echo "setup aborted"
	exit 1
fi


sed -i "s/%ip%/$bannerip/g" temp/ssh-server/ssh-serverd_banner
sed -i "s/%hostname%/$hostname/g" temp/ssh-server/ssh-serverd_banner
sed -i "s/%description%/$description/g" temp/ssh-server/ssh-serverd_banner
sed -i "s/%bannerAccess%/$bannerAccess/g" temp/ssh-server/ssh-serverd_banner

if [ $allowedUsers == "admins" ]; then
	sed -i 's/#allow-login-all//' temp/ssh-server/ssh-serverd_config
fi


echo "debug enabled, not copying files"
exit 1

#Copy temp files to system
cp $temp/ssh-server/ssh-serverd_config /etc/ssh-server/ssh-serverd_config
cp $temp/ssh-server/ssh-serverd_banner /etc/ssh-server/ssh-serverd_banner

/etc/init.d/ssh restart


