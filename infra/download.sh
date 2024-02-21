#!/bin/bash
set -e

# This file will download the required files to deploy the Azure Open AI Chat with Data solution
# It starts by downloading the deployment.bicep and deployment.bicep.param files
# It then downloads the required security files
# Download deployment.bicep file
curl -o deployment.bicep https://raw.githubusercontent.com/TCappabianca01/chat-with-your-data-solution-accelerator/main/infra/deployment.bicep
# Download role.bicep file
mkdir -p security
curl -o security/role.bicep https://raw.githubusercontent.com/TCappabianca01/chat-with-your-data-solution-accelerator/main/infra/security/role.bicep
# Download the deploy script
curl -o deploy.sh https://raw.githubusercontent.com/TCappabianca01/chat-with-your-data-solution-accelerator/main/infra/deploy.sh


