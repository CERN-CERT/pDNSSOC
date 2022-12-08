#!/bin/bash


# Packages installation
yum -y install ruby git
cd /tmp/
git clone https://github.com/CERN-CERT/pDNSSOC/
cd pDNSSOC/files

curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent4.sh | sh
td-agent-gem install fluent-plugin-filter-list
gem install parseconfig
gem install misp

# Fluentd 
cp td-agent.conf /etc/td-agent/td-agent.conf

# pDNSSOC 
mkdir -p /etc/pdnssoc/
cp structure_html.txt /etc/pdnssoc/structure_html.txt
cp pdnssoc.rb /usr/local/bin/pdnssoc.rb
cp pdnssoc.conf /etc/pdnssoc/pdnssoc.conf
cp pdnssoc.cron /etc/pdnssoc/pdnssoc.cron


touch /etc/td-agent/misp_domains.txt
ln -s /etc/pdnssoc/pdnssoc.cron /etc/cron.hourly/pdnssoc_misp
/etc/pdnssoc/pdnssoc.cron

# Start
systemctl restart td-agent.service


echo  "*/1 * * * * root /usr/bin/ruby /usr/local/bin/pdnssoc.rb > /dev/null 2>&1" >> /etc/crontab
