#!/bin/bash

if [ `id -u` -ne 0 ]; then
	echo "Must be root to run this script"
	exit 1
fi


#packages nmap hping3 dnsutils vim less 
apt-get update
apt-get -y install less vim hping3 nmap dnsutils byobu

echo syntax on > ~/.vimrc
