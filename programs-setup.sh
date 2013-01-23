#!/bin/bash

#packages nmap hping3 dnsutils vim less 
sudo apt-get update
sudo apt-get -y install less vim hping3 nmap dnsutils byobu

echo syntax on > ~/.vimrc
