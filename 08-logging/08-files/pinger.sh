#!/bin/bash

# Script contains several (more than 1) security issues.
# Find them and fix them to get bonus on exam.
# Problem example: SQL injection.

for t in database_url database_name targets; do
  if ! grep -q "^${t}=" /etc/pinger/pinger.conf; then
    logger "$0 Failed to get $t from config"
    exit 1
  fi
done

which fping > /dev/null || (logger "fping not found"; exit 1)

db_url=$(grep "^database_url=" /etc/pinger/pinger.conf | sed 's/^.*=//')
db_name=$(grep "^database_name=" /etc/pinger/pinger.conf | sed 's/^.*=//')
targets=$(grep "^targets=" /etc/pinger/pinger.conf | sed 's/^.*=//' | sed 's/\(,\|;\)/ /g')

curl -i -XPOST "${db_url}/query" --data-urlencode "q=CREATE DATABASE $db_name" 1>/dev/null 2>/dev/null

while true; do
  result=$(fping -C1 -q $targets 2>&1 | awk '{print "rtt,dst="$1" rtt="$3}')
  curl -i -XPOST "${db_url}/write?db=$db_name" --data-binary "$result" 1>/dev/null 2>/dev/null
 sleep 1
done
