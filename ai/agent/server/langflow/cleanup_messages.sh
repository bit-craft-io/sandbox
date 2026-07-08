#!/bin/sh
API_KEY="${LANGFLOW_API_KEY}"
BASE_URL="http://host.docker.internal:7860"
RETENTION_DAYS=5

echo "[$(date)] Starting message cleanup (retention: ${RETENTION_DAYS} days)"

cutoff_date=$(date -d "-${RETENTION_DAYS} days" +%Y-%m-%dT%H:%M:%S 2>/dev/null || date -v-${RETENTION_DAYS}d +%Y-%m-%dT%H:%M:%S)

curl -s "${BASE_URL}/api/v1/monitor/messages" -H "x-api-key: ${API_KEY}" | \
  jq -r --arg cutoff "${cutoff_date}" '.[] | select(.timestamp < $cutoff) | .id' | \
  while read -r msg_id; do
    echo "Deleting message: ${msg_id}"
    curl -s -X DELETE "${BASE_URL}/api/v1/monitor/messages/${msg_id}" -H "x-api-key: ${API_KEY}"
  done

echo "[$(date)] Cleanup completed"
