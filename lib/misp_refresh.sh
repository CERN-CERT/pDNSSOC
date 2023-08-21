#!/bin/sh
#
# CRON file for pDNSSOC

# Downloading MISP events

pull_misp_data(){
jq  --raw-output '.misp_servers[] | "\(.api_key)|\(.domain)|\(.'$1')"' /etc/pdnssoc/pdnssoc.conf |
while IFS="|" read -r api_key domain parameter; do
         printf -v mycurl 'curl -k -qsS --header "Authorization: %s" "%s%s"\n' "$api_key" "https://$domain/" "$parameter"
         raw_data=$( eval ${mycurl})
         sorted_data=$(printf "$raw_data\n"|sort -u)
         echo "$sorted_data\n" > /etc/td-agent/$2

    done
}

pull_misp_data "parameter_domains" "misp_domains.txt"
pull_misp_data "parameter_ips" "misp_ips.txt"

# Add something below to send an alert to the security contact if misp_domains.txt is empty


# Reload the configuration file for fluentd

kill -1 `cat /var/run/td-agent/td-agent.pid`
