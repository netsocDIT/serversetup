#/bin/bash
# cd to dir script is run from
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR

if [ `id -u` -ne 0 ]; then
        echo "Must be root to run this script"
        exit 1
fi


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



if [ "$allowedUsers" == "all" ]; then
	sed -i "s/#allowgroups currentMembers/allowgroups currentMembers/g" temp/ssh-server/sshd_config
	echo "test"
fi


echo -e "\nDo you want to allow root login? (y/n)?"
read allowroot

if [ "$allowroot" == "y" ]; then
	sed -i "s/#allowgroups root /allowgroups root/g" temp/ssh-server/sshd_config
fi


systemHostname=`hostname`
echo -e "\nBanner Hostname. Default: $systemHostname"
read hostname

if [ -z $hostname ]; then
	hostname=$systemHostname
fi




echo -e "\nBanner access displayed (eg restricted, all members)"
read bannerAccess

echo -e "\nBanner description (eg, ldap server, main login server)"
read description

echo -e 

bannerip=`ifconfig | egrep -o "inet addr:[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}\.[0-9]{0,3}" | sed 's/^inet addr://'| grep -v 127.0.0.1| head -n 1`

echo "Banner IP  Default:$bannerip"
read bannerIP


echo "Confirmation:"
echo "          Banner hostname: $hostname"
echo "       Banner description: $description"
echo " Banner access displayed : $bannerAccess"
echo "        Banner IP address: $bannerip"
echo "        ssh users allowed: $allowedUsers"
echo "               rootlogins: $allowroot"

echo -e "\nIs this correct? (y/n) \r"
read confirm

if [ "$confirm" != "y" ]; then
	echo "setup aborted"
	exit 1
fi


sed -i "s/%ip%/$bannerip/g" temp/ssh-server/sshd_banner
sed -i "s/%hostname%/$hostname/g" temp/ssh-server/sshd_banner
sed -i "s/%description%/$description/g" temp/ssh-server/sshd_banner
sed -i "s/%bannerAccess%/$bannerAccess/g" temp/ssh-server/sshd_banner

if [ "$allowedUsers" == "admins" ]; then
	sed -i 's/#allow-login-all//' temp/ssh-server/sshd_config
fi

echo -e  "\nConfigs written to 'temp'"
echo -e "Do you wish to copy files to system? (y/n) \r"
read confirm

if [ "$confirm" != "y" ]; then
	echo "Your files are in the 'temp' directory, now exiting"
	exit 0
fi


#Copy temp files to system
cp temp/ssh-server/sshd_config /etc/ssh/sshd_config
cp temp/ssh-server/sshd_banner /etc/ssh/sshd_banner

/etc/init.d/ssh restart



