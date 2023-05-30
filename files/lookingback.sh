#!/bin/sh


temp_file=$(mktemp)
alert_path=`grep alerts_path /etc/pdnssoc/pdnssoc.conf | awk -F "\"" '{print $4}'`

zgrep  -F -f /etc/td-agent/misp_domains.txt /var/log/td-agent/queries.*.log* > ${temp_file}
grep  -w -f /etc/td-agent/misp_domains.txt ${temp_file} >> ${alert_path}pdnssoc-pastlog.log
cat ${temp_file}
rm -f ${temp_file}
