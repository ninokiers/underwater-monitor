#!/usr/bin/env bash

. ./config.env

# Configure AWS credentials
rm -f "/root/.aws/config" "/root/.aws/credentials"

aws configure --profile default set aws_access_key_id "$AWS_ACCESS_KEY"
aws configure --profile default set aws_secret_access_key "$AWS_SECRET_KEY"
aws configure --profile default set region "auto"

cat > "/root/.aws/config" <<EOL
[default]
region = auto
s3 =
    endpoint_url = $AWS_ENDPOINT
EOL
