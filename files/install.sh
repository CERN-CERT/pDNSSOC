#!/bin/bash


# Packages installation
yum -y install ruby
curl -L https://toolbelt.treasuredata.com/sh/install-redhat-td-agent4.sh | sh
td-agent-gem install fluent-plugin-filter-list
gem install parseconfig
gem install misp

# Fluentd 
# /etc/td-agent/td-agent.conf

# pDNSSOC 
# /etc/pdnssoc/structure_html.txt
#/etc/pdnssoc/pdnssoc.conf
#/etc/pdnssoc/pdnssoc.cron

touch /etc/td-agent/misp_domains.txt
ln -s /etc/pdnssoc/pdnssoc.cron /etc/cron.hourly/pdnssoc_misp
/etc/pdnssoc/pdnssoc.cron

# Start
systemctl restart td-agent.service

#/usr/local/bin/pdnssoc.rb
echo  "*/1 * * * * root /usr/bin/ruby /usr/local/bin/pdnssoc.rb > /dev/null 2>&1" >> /etc/crontab
