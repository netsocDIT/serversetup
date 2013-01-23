#/bin/bash
# This sets up iptables to run initially on startup by placing it at the bottom of rc.local
# cd to dir script is run from
cd "$( dirname "${BASH_SOURCE[0]}" )"

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

# temp firewall dir exists
if [ -d "temp/firewall" ]; then

	echo  "Cleaning up old config files"
	rm -r "temp/firewall"
fi


#copy files
cp -r configs/firewall temp/firewall



mkdir /etc/firewall
cp temp/firewall/iptables.sh /etc/firewall/iptables.sh
chmod +x /etc/firewall/iptables.sh

chmod -R  700 /etc/firewall

cp /etc/rc.local temp/firewall/rc.local.orig
sed -i 's#^exit 0$#/etc/firewall/iptables.sh\nexit 0#' /etc/rc.local

echo 'reading out non-commented lines in /etc/rc.local  lines of rc.local to verify iptables line is properly there'
echo 'VERIFY THAT iptables.sh has been successfully added'
cat /etc/rc.local | grep -v '^#'

echo "the original rc.local has been copied to temp/firewall/rc.local.orig. If you're not happy with this new updated file. do NOT rerun this script or it'll overwrite it orig file with the new copy of rc.local that's now there"

echo "Do you wish to run iptables.sh now and enable firewall? (if services are already running, you should add rules for those ports first"
echo "(y/n)"
read runfirewall
if [ "$runfirewall" = "y" ]; then
	echo "running firewall"
	/etc/firewall/iptables.sh
else
	echo "not running firewall. Edit the file in /etc/firewall/iptables.sh and run it when you're done"
fi

