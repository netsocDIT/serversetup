#/bin/bash

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

ln -s /etc/firewall/iptables.sh /etc/network/if-up.d/iptables.sh

/etc/firewall/iptables.sh

