#!/bin/bash

echo "Cleaning the room."

rm -f /etc/pdnssoc/pdnssoc.cron 2> /dev/null
rm -f /etc/pdnssoc/pdnssoc.conf 2> /dev/null
rm -f /usr/local/bin/pdnssoc/ 2> /dev/null
rm -f /etc/pdnssoc/notification_email.html 2> /dev/null
rm -f /etc/cron.hourly/pdnssoc_misp 2> /dev/null
rm -f /etc/td-agent/td-agent.conf 2> /dev/null
sed '/pdnssoc\.rb/d' -i /etc/crontab

echo "Installing system packages."
# Packages installation
yum -y install ruby git jq ruby-devel
cd /tmp/
git clone https://github.com/CERN-CERT/pDNSSOC/
cd pDNSSOC/files

echo "Installing Fluentd."
curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent4.sh | sh
td-agent-gem install fluent-plugin-filter-list --force

echo "Installing Ruby dependencies."
td-agent-gem install parseconfig
td-agent-gem install misp
td-agent-gem install json


echo "Moving pDNSSOC files around."
# Fluentd 
cp td-agent.conf /etc/td-agent/td-agent.conf

# pDNSSOC 
mkdir -p /etc/pdnssoc/
cp notification_email.html /etc/pdnssoc/
mkdir -p /usr/local/bin/pdnssoc/
cp code/*.rb /usr/local/bin/pdnssoc/
cp pdnssoc.conf /etc/pdnssoc/pdnssoc.conf
cp pdnssoc.cron /etc/pdnssoc/pdnssoc.cron

echo "Installing pDNSSOC files."

chmod +x /etc/pdnssoc/pdnssoc.cron
chmod +x /usr/local/bin/pdnssoc/pdnssoc.rb


touch /etc/td-agent/misp_domains.txt
ln -s /etc/pdnssoc/pdnssoc.cron /etc/cron.hourly/pdnssoc_misp

echo  "*/1 * * * * /usr/bin/ruby /usr/local/bin/pdnssoc/pdnssoc.rb" >> /etc/crontab

# An empty line is required at the end of this file for a valid cron file.

# Disabling the local firewall, which obviously nobody should ever do

echo "Disabling the local firewall."
systemctl disable firewalld 
systemctl stop firewalld 

echo "Starting Fluentd."

# Start
systemctl restart td-agent.service

echo "Clearing install files."

cd 
rm -rf /tmp/pDNSSOC
