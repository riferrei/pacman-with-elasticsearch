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

if [ -z "${EC_API_KEY}" ]; then
  echo "The variable 'EC_API_KEY' has not been set."
  exit 0
fi

if [ -z "${SELECTED_PROVIDER}" ]; then
  echo "The variable 'SELECTED_PROVIDER' has not been set."
  exit 0
fi

if [ -z "${SELECTED_REGION}" ]; then
  echo "The variable 'SELECTED_REGION' has not been set."
  exit 0
fi

if [ -z "${APP_NAME}" ]; then
  echo "The variable 'APP_NAME' has not been set."
  exit 0
fi

# Initial discovery

provider="${SELECTED_PROVIDER}"
region="${SELECTED_REGION}"

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

export EC_API_KEY=$EC_API_KEY
export TF_VAR_ec_region=$region

export TF_VAR_app_name=$APP_NAME
export TF_VAR_display_count=$DISPLAY_COUNT
export TF_VAR_data_stream_enabled=$DATA_STREAM_ENABLED
export TF_VAR_transform_enabled=$TRANSFORM_ENABLED
export TF_VAR_transform_frequency=$TRANSFORM_FREQUENCY
export TF_VAR_transform_delay=$TRANSFORM_DELAY

terraform destroy -auto-approve
