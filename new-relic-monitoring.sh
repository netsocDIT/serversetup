#!/bin/bash
echo "This will install New Relic Monitoring Software on this server"
echo "Ensure you have the API from the documentation before continuing"
echo "This will only install system monitoring, not Application monitoring, please see http://newrelic.com"
echo "for more information"

mkdir newrelic-temp
cd newrelic-temp
wget -O /etc/apt/sources.list.d/newrelic.list http://download.newrelic.com/debian/newrelic.list
wget http://download.newrelic.com/548C16BF.gpg
apt-key add 548C16BF.gpg
apt-get update
apt-get install newrelic-sysmond
echo ""
echo ""
echo "Sysmon daemon installed, please enter API key from the docs:"
read key
nrsysmond-config --set license_key=$key
service newrelic-sysmond start
cd ..
rm -rf newrelic-temp