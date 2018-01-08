#!/bin/sh

#aws route53 list-hosted-zones | jq '.HostedZones | map(select(.Name == "wakewaka.me."))[] | .Id '
MY_HOSTNAME={{ host_name }}
MY_DOMAIN={{ domain }}

HOSTED_ZONEID=`aws route53 list-hosted-zones | jq -r ".HostedZones | map(select(.Name == \"${MY_HOSTNAME}.\"))[] | .Id " | sed "s/^.*\///g"`

MY_PUBLIC_IP=`curl -s ifconfig.me`
MY_DDNS_RECORD=${MY_HOSTNAME}.${MY_DOMAIN}


if [ -z $MY_PUBLIC_IP ] ;  then
    MY_PUBLIC_IP=`curl -s ipinfo.io | jq -r '.ip'`
fi

if [ -z $MY_PUBLIC_IP ] ;  then
  echo "failed to get global IP address"
  exit 1
fi

cat <<EOT > /tmp/recordset.json
{
  "Comment": "create A record",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "${MY_DDNS_RECORD}",
        "Type": "A",
        "TTL": 3600 ,
        "ResourceRecords": [
          {
          "Value": "${MY_PUBLIC_IP}"
          }
        ]
      }
    }
  ]
}
EOT

aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONEID --change-batch file:///tmp/recordset.json 

rm -rf /tmp/recordset.json
