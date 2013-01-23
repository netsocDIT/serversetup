#/bin/bash
# Security updates installed automatically
# Regular updates just downloaded
cd "$( dirname "${BASH_SOURCE[0]}" )"
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

#temp unattended-upgrades dir exists
if [ -d "temp/unattended-upgrades" ]; then

	echo  "Cleaning up old config files"
	rm -r "temp/unattended-upgrades"
fi

# cp config to temp
cp -r configs/unattended-upgrades temp/unattended-upgrades

debconf-set-selections < temp/unattended-upgrades/debconf-defaults

apt-get update
apt-get -y install unattended-upgrades


cp temp/unattended-upgrades/20auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades
cp temp/unattended-upgrades/50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades
