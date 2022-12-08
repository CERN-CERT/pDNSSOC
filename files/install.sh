#!/bin/bash

echo "Cleaning the room."

rm -f /etc/pdnssoc/pdnssoc.cron 2> /dev/null
rm -f /etc/pdnssoc/pdnssoc.conf 2> /dev/null
rm -f /usr/local/bin/pdnssoc.rb 2> /dev/null
rm -f /etc/pdnssoc/structure_html.txt 2> /dev/null
rm -f /etc/cron.hourly/pdnssoc_misp 2> /dev/null
rm -f /etc/td-agent/td-agent.conf 2> /dev/null

echo "Installing system packages."
# Packages installation
yum -y install ruby git jq
cd /tmp/
git clone https://github.com/CERN-CERT/pDNSSOC/
cd pDNSSOC/files

echo "Installing Fluentd."
curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent4.sh | sh
td-agent-gem install fluent-plugin-filter-list

echo "Installing Ruby dependencies."
gem install parseconfig
gem install misp

echo "Moving pDNSSOC files around."
# Fluentd 
cp td-agent.conf /etc/td-agent/td-agent.conf

# pDNSSOC 
mkdir -p /etc/pdnssoc/
cp structure_html.txt /etc/pdnssoc/structure_html.txt
cp pdnssoc.rb /usr/local/bin/pdnssoc.rb
cp pdnssoc.conf /etc/pdnssoc/pdnssoc.conf
cp pdnssoc.cron /etc/pdnssoc/pdnssoc.cron

echo "Installing pDNSSOC files."

chmod +x /etc/pdnssoc/pdnssoc.cron
chmod +x /usr/local/bin/pdnssoc.rb


touch /etc/td-agent/misp_domains.txt
ln -s /etc/pdnssoc/pdnssoc.cron /etc/cron.hourly/pdnssoc_misp

echo  "*/1 * * * * root /usr/bin/ruby /usr/local/bin/pdnssoc.rb > /dev/null 2>&1" >> /etc/crontab

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
