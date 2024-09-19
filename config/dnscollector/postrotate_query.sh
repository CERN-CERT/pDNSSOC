#!/bin/bash

BACKUP_FOLDER=/var/dnscollector/queries/$(date +%Y-%m-%d)
mkdir -p $BACKUP_FOLDER

FILE_NAME=$(basename $1 .log)

jq -c '. | {timestamp: .dnstap."timestamp-rfc3339ns", query: .dns.qname, client: .network."query-ip", server: .network."response-ip", client_id: .dnstap.identity , answers: .dns."resource-records".an }' $1 > $BACKUP_FOLDER/$FILE_NAME.json && gzip -S .gz_minified $BACKUP_FOLDER/$FILE_NAME.json