#!/bin/bash

filename=elastic.settings
if [ -f "$filename" ]; then
  source $filename
else
  echo "The file '$filename' doesn't exist."
  exit 0
fi

filename=provider.settings
if [ -f "$filename" ]; then
  source $filename
else
  echo "The file '$filename' doesn't exist."
  exit 0
fi

filename=general.settings
if [ -f "$filename" ]; then
  source $filename
fi

# Validations

if [ -z "${ES_ENDPOINT}" ]; then
  echo "The variable 'ES_ENDPOINT' has not been set."
  exit 0
fi

if [ -z "${ES_USERNAME}" ]; then
  echo "The variable 'ES_USERNAME' has not been set."
  exit 0
fi

if [ -z "${ES_PASSWORD}" ]; then
  echo "The variable 'ES_PASSWORD' has not been set."
  exit 0
fi

if [ -z "${APP_NAME}" ]; then
  echo "The variable 'APP_NAME' has not been set."
  exit 0
fi

# Initial discovery

readarray -d . -t endpointParts <<< "$ES_ENDPOINT"

provider="${endpointParts[2]}"
region="${endpointParts[1]}"

if [ "$provider" == "aws" ]; then

  export AWS_DEFAULT_REGION=$region
  cd terraform/aws

elif [ "$provider" == "gcp" ]; then

  export GOOGLE_CLOUD_KEYFILE_JSON=$GOOGLE_CLOUD_KEYFILE_JSON
  export GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT
  export TF_VAR_google_region=$region
  cd terraform/gcp

elif [ "$provider" == "azure" ]; then

  export ARM_SKIP_PROVIDER_REGISTRATION=true
  export ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID
  export ARM_TENANT_ID=$ARM_TENANT_ID
  export ARM_CLIENT_ID=$ARM_CLIENT_ID
  export TF_VAR_resource_group_name=$ARM_RESOURCE_GROUP
  export TF_VAR_location=$region
  cd terraform/azr

fi

# Undeploying

export TF_VAR_es_endpoint=$ES_ENDPOINT
export TF_VAR_es_username=$ES_USERNAME
export TF_VAR_es_password=$ES_PASSWORD

export TF_VAR_app_name=$APP_NAME
export TF_VAR_display_count=$DISPLAY_COUNT

export TF_VAR_data_stream_enabled=$DATA_STREAM_ENABLED
export TF_VAR_transform_enabled=$TRANSFORM_ENABLED
export TF_VAR_transform_frequency=$TRANSFORM_FREQUENCY
export TF_VAR_transform_delay=$TRANSFORM_DELAY

terraform destroy -auto-approve
