#!/bin/sh

### Read the number of data nodes available in the cluster

number_of_data_nodes=$(curl -s -X GET -u "$ES_USERNAME:$ES_PASSWORD" \
   ${ES_ENDPOINT}/_cluster/health | jq '.number_of_data_nodes')

#################################################################
########################## Input Data ###########################
#################################################################

if [ "$DATA_STREAM_ENABLED" == true ]; then

   ### Create the policy if it doesn't exist

   ds_policy_name="${INPUT_DATA_INDEX}-policy"
   ds_policy_status=$(curl -s -X GET -u "$ES_USERNAME:$ES_PASSWORD" \
      ${ES_ENDPOINT}/_ilm/policy/${ds_policy_name} | jq '.status')

   if [ "${ds_policy_status}" == 404 ]; then

      curl -s -X PUT -u "$ES_USERNAME:$ES_PASSWORD" -H "Content-Type:application/json" \
         "${ES_ENDPOINT}/_ilm/policy/${ds_policy_name}" -d @ds-policy.json

   fi

   ### Create the template if it doesn't exist

   template="${INPUT_DATA_INDEX}-template"
   template_status=$(curl -s -X GET -u "$ES_USERNAME:$ES_PASSWORD" \
      ${ES_ENDPOINT}/_index_template/${template} | jq '.status')

   if [ "${template_status}" == 404 ]; then

      template_body=$(sed -e "s/\${INPUT_DATA_INDEX}/${INPUT_DATA_INDEX}/" -e "s/\${NUMBER_OF_SHARDS}/${number_of_data_nodes}/" -e "s/\${DS_POLICY_NAME}/${ds_policy_name}/" template.json)

      curl -s -X PUT -u "$ES_USERNAME:$ES_PASSWORD" -H "Content-Type:application/json" \
         "${ES_ENDPOINT}/_index_template/${template}" -d "$template_body"

   fi

   ### Create the data stream if it doesn't exist

   ds_status=$(curl -s -X GET -u "$ES_USERNAME:$ES_PASSWORD" \
      ${ES_ENDPOINT}/_data_stream/${INPUT_DATA_INDEX} | jq '.status')

   if [ "${ds_status}" == 404 ]; then

      curl -s -X PUT -u "$ES_USERNAME:$ES_PASSWORD" \
         "${ES_ENDPOINT}/_data_stream/${INPUT_DATA_INDEX}"

   fi

else

   ### Create the index if it doesn't exist

   index_status=$(curl -s -X GET -u "$ES_USERNAME:$ES_PASSWORD" \
      ${ES_ENDPOINT}/${INPUT_DATA_INDEX} | jq '.status')

   if [ "$index_status" == 404 ]; then

      input_data_body=$(sed -e "s/\${NUMBER_OF_SHARDS}/${number_of_data_nodes}/" input-data.json)
   
      curl -s -X PUT -u "$ES_USERNAME:$ES_PASSWORD" -H "Content-Type:application/json" \
         "${ES_ENDPOINT}/${INPUT_DATA_INDEX}" -d "$input_data_body"

   fi

fi

#################################################################
########################### Transform ###########################
#################################################################

if [ "$TRANSFORM_ENABLED" == true ]; then

   ### Create the index if it doesn't exist

   index_status=$(curl -s -X GET -u "$ES_USERNAME:$ES_PASSWORD" \
      ${ES_ENDPOINT}/${SCOREBOARD_INDEX} | jq '.status')

   if [ "$index_status" == 404 ]; then

      scoreboard_body=$(sed -e "s/\${NUMBER_OF_SHARDS}/${number_of_data_nodes}/" scoreboard.json)
   
      curl -s -X PUT -u "$ES_USERNAME:$ES_PASSWORD" -H "Content-Type:application/json" \
         "${ES_ENDPOINT}/${SCOREBOARD_INDEX}" -d "$scoreboard_body"

   fi

   ### Create the transform if it doesn't exist

   transform_status=$(curl -s -X GET -u "$ES_USERNAME:$ES_PASSWORD" \
      ${ES_ENDPOINT}/_transform/${SCOREBOARD_INDEX} | jq '.status')

   if [ "$transform_status" == 404 ]; then

      transform_body=$(sed -e "s/\${INPUT_DATA_INDEX}/${INPUT_DATA_INDEX}/" -e "s/\${SCOREBOARD_INDEX}/${SCOREBOARD_INDEX}/" -e "s/\${TRANSFORM_FREQUENCY}/${TRANSFORM_FREQUENCY}/" -e "s/\${TRANSFORM_DELAY}/${TRANSFORM_DELAY}/" transform.json)
   
      curl -s -X PUT -u "$ES_USERNAME:$ES_PASSWORD" -H "Content-Type:application/json" \
         "${ES_ENDPOINT}/_transform/${SCOREBOARD_INDEX}" -d "$transform_body"

   fi

   ### Start the transform if not running already

   transform_state=$(curl -s -X GET -u "$ES_USERNAME:$ES_PASSWORD" \
      ${ES_ENDPOINT}/_transform/${SCOREBOARD_INDEX}/_stats | jq -r '.transforms[0].state')

   if [ "$transform_state" != "started" ]; then

      curl -s -X POST -u "$ES_USERNAME:$ES_PASSWORD" \
         "${ES_ENDPOINT}/_transform/${SCOREBOARD_INDEX}/_start"

   fi

fi
