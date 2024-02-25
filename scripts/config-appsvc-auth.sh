#!/bin/bash
set -e

# Ensure the required parameters are present
usage="Usage: ./config-appsvc-auth.sh <rgName> <location> <websiteName> <websiteAdminName>"
rgName=${1:?"Missing rgName. ${usage}"}
location=${2:?"Missing location. ${usage}"}
websiteName=${3:?"Missing websiteName. ${usage}"}
websiteAdminName=${4:?"Missing websiteAdminName. ${usage}"}

# Variables
clientSecretName="easyauthsecret"
tenantId=$(az account show --query tenantId -o tsv)
MSGraphAPI="00000003-0000-0000-c000-000000000000" #UID of Microsoft Graph
Permission="e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope" # ID: Read permission, Type: Scope

# Create Azure AD App Registration with redirect URI
echo "Creating App Registrations"

# Ensure using v2 of auth
echo "Ensure using v2 of auth"
az extension add --name authV2

# Website
app=$(az ad app create --display-name $websiteName --web-redirect-uris "https://$websiteName.azurewebsites.net/.auth/login/aad/callback" --enable-id-token-issuance true)
appId=$(echo $app | jq -r '.appId')
az ad app permission add --id "$appId" --api "$MSGraphAPI" --api-permissions "$Permission"
clientSecret=$(az ad app credential reset --id $appId --display-name $clientSecretName --query password --output tsv)


# Website Admin
adminApp=$(az ad app create --display-name $websiteAdminName --web-redirect-uris "https://$websiteAdminName.azurewebsites.net/.auth/login/aad/callback" --enable-id-token-issuance true)
adminAppId=$(echo $adminApp | jq -r '.appId')
az ad app permission add --id "$adminAppId" --api "$MSGraphAPI" --api-permissions "$Permission"
adminClientSecret=$(az ad app credential reset --id $adminAppId --display-name $clientSecretName --query password --output tsv)

# Configure App Services with the Azure AD App Registration
echo Configure App Service Authentication

az webapp auth microsoft update --name $websiteName --resource-group $rgName \
 --client-id $appId \
 --client-secret $clientSecret \
 --issuer https://sts.windows.net/$tenantId/v2.0 \
 --yes
az webapp auth microsoft update --name $websiteAdminName --resource-group $rgName \
 --client-id $adminAppId \
 --client-secret $adminClientSecret \
 --issuer https://sts.windows.net/$tenantId/v2.0 \
 --yes

az webapp auth update --name $websiteName --resource-group $rgName \
 --enabled true \
 --enable-token-store true \
 --action RedirectToLoginPage \
 --redirect-provider azureActiveDirectory 

az webapp auth update --name $websiteAdminName --resource-group $rgName \
 --enabled true \
 --enable-token-store true \
 --action RedirectToLoginPage \
 --redirect-provider azureActiveDirectory
