#!/bin/sh

#################################################################
############################ API Key ############################
#################################################################

eval "$(jq -r '@sh "ES_ENDPOINT=\(.es_endpoint) ES_USERNAME=\(.es_username) ES_PASSWORD=\(.es_password) API_KEY_BODY=\(.api_key_body)"')"

output=$(curl -s -X POST -u "$ES_USERNAME:$ES_PASSWORD" \
   -H 'Content-Type:application/json' -d "$API_KEY_BODY" \
   ${ES_ENDPOINT}/_security/api_key | jq '.')

apiID=$( echo $output | jq -r '.id' )
apiKey=$( echo $output | jq -r '.api_key' )

jq -n --arg apiID "$apiID" --arg apiKey "$apiKey" '{"apiID" : $apiID, "apiKey" : $apiKey}'
