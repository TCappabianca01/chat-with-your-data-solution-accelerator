#!/bin/bash
set -e

# This file will create the resources for an Azure Open AI Chat with Data solution
# It starts by creating an Azure Container Registry and importing standard images from the public registry
# It then creates needed App Registrations and Service Principals
# It then deploys the resources defined in deployment.bicep

# Ensure the required parameters are present
usage="Usage: ./deploy.sh <rgName> <location> <resourcePrefix>"
rgName=${1:?"Missing rgName. ${usage}"}
location=${2:?"Missing location. ${usage}"}
resourcePrefix=${3:?"Missing resourcePrefix. ${usage}"}

# Variables
acrName="${resourcePrefix}acr"
websiteName="${resourcePrefix}-website"
websiteAdminName="${websiteName}-admin"

# Ensure all the required files are present
required_files=("deployment.bicep" "deployment.bicepparam" "security/role.bicep")
for file in "${required_files[@]}"; do
  if [ ! -f "$file" ]; then
    echo "$file not found"
    exit 1
  fi
done

# Create the Azure Container Registry
az acr create --name $acrName --resource-group $rgName --sku Basic --admin-enabled true

# Import the standard images from the public registry
repositories=("rag-webapp" "rag-adminwebapp" "rag-backend")
repoList=$(az acr repository list --name $acrName)

for repo in "${repositories[@]}"; do
  repoExists=$(echo $repoList | jq -r '.[] | select(. == "'$repo'")' | wc -l)  
  
  if [ $repoExists -eq 0 ]; then
    echo importing $repo
    az acr import --resource-group $rgName --name $acrName --source fruoccopublic.azurecr.io/$repo:latest --image $repo:latest
  else    
    echo "Repo already exists in the Azure Container Registry: $repo"
  fi
done

# Create Azure AD App Registration with redirect URI
echo "Creating App Registrations"
clientSecretName="easyauthsecret"

# Website
app=$(az ad app create --display-name $websiteName --web-redirect-uris "https://$websiteName.azurewebsites.net/.auth/login/aad/callback" --enable-id-token-issuance true)
appId=$(echo $app | jq -r '.appId')
clientSecret=$(az ad app credential reset --id $appId --display-name $clientSecretName --query password --output tsv)

# Website Admin
adminApp=$(az ad app create --display-name $websiteAdminName --web-redirect-uris "https://$websiteAdminName.azurewebsites.net/.auth/login/aad/callback" --enable-id-token-issuance true)
adminAppId=$(echo $adminApp | jq -r '.appId')
adminClientSecret=$(az ad app credential reset --id $adminAppId --display-name $clientSecretName --query password --output tsv)

# Deploy the resources defined in deployment.bicep
echo "Deploying resources"
az deployment group create -g $rgName -f deployment.bicep --parameters deployment.bicepparam \
 --parameters ResourcePrefix=$resourcePrefix Location=$location AzureContainerRegistryName=$acrName \
 WebsiteAppRegistrationClientId="$appId" WebsiteAppRegistrationSecret="$clientSecret" WebsiteAdminAppRegistrationClientId="$adminAppId" WebsiteAdminAppRegistrationSecret="$adminClientSecret"

#--query properties.outputs

# az webapp auth update -g $resourceGroupName -n $appName --enabled true \
#   --action LoginWithAzureActiveDirectory \
#   --aad-allowed-token-audiences https://$appName.azurewebsites.net/.auth/login/aad/callback \
#   --aad-client-id $appId --aad-client-secret $clientSecret \
#   --aad-token-issuer-url https://sts.windows.net/$tenantId/


