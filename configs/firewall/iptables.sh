#!/bin/bash

#########################
#                       #
# Clear iptables and    #
# set default to allow  #
#                       #
#########################
iptables -F -t nat
#no ip6tables nat

iptables -F -t mangle
ip6tables -F -t mangle

iptables -F -t filter
ip6tables -F -t filter

iptables -P INPUT ACCEPT
ip6tables -P INPUT ACCEPT

iptables -P FORWARD ACCEPT
ip6tables -P FORWARD ACCEPT

iptables -P OUTPUT ACCEPT
ip6tables -P OUTPUT ACCEPT


#########################
#                       #
# Allow established +   #
# localhost connections #
#                       #
#########################
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
ip6tables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT

iptables -A INPUT -i lo -j ACCEPT
ip6tables -A INPUT -i lo -j ACCEPT

iptables -A INPUT -d 127.0.0.0/8 ! -i lo -j REJECT --reject-with icmp-port-unreachable



#########################
#                       #
#    Incoming Ports     #
#                       #
#########################

# SSH
iptables -A INPUT -p tcp -m state --state NEW --dport 22 -j ACCEPT
ip6tables -A INPUT -p tcp -m state --state NEW --dport 22 -j ACCEPT






# REJECT
iptables -A INPUT -j REJECT --reject-with icmp-port-unreachable
ip6tables -A INPUT -j REJECT --reject-with icmp6-port-unreachable




