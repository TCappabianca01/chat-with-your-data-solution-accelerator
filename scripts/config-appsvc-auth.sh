#!/bin/bash
set -e

# echo LOCATION: ${AZURE_LOCATION}
# echo TENANT: ${AZURE_TENANT_ID}
# echo ADMINSITE: ${AZURE_ADMINWEBSITE_NAME}
# echo WEBSITE: ${AZURE_WEBSITE_NAME}
# echo RESOURCEGROUP: ${AZURE_RESOURCE_GROUP}

# sleep 5

# Variables
clientSecretName="easyauthsecret"
tenantId=${AZURE_TENANT_ID}
websiteName=${AZURE_WEBSITE_NAME}
websiteAdminName=${AZURE_ADMINWEBSITE_NAME}
rgName=${AZURE_RESOURCE_GROUP}
MSGraphAPI="00000003-0000-0000-c000-000000000000" #UID of Microsoft Graph
Permission="e1fe6dd8-ba31-4d61-89e7-88639da4683d=Scope" # ID: Read permission, Type: Scope

# Create Azure AD App Registration with redirect URI
echo "Creating App Registrations"

# Ensure using v2 of auth
echo "Ensure using v2 of auth"
az extension add --name authV2

# Website
echo "Creating App Registration for $websiteName"
app=$(az ad app create --display-name $websiteName --web-redirect-uris "https://$websiteName.azurewebsites.net/.auth/login/aad/callback" --enable-id-token-issuance true)
appId=$(echo $app | jq -r '.appId')

echo "Adding permissions to $websiteName"
az ad app permission add --id "$appId" --api "$MSGraphAPI" --api-permissions "$Permission"
clientSecret=$(az ad app credential reset --id $appId --display-name $clientSecretName --query password --output tsv)


# Website Admin
echo "Creating App Registration for $websiteAdminName"
adminApp=$(az ad app create --display-name $websiteAdminName --web-redirect-uris "https://$websiteAdminName.azurewebsites.net/.auth/login/aad/callback" --enable-id-token-issuance true)
adminAppId=$(echo $adminApp | jq -r '.appId')

echo "Adding permissions to $websiteAdminName"
az ad app permission add --id "$adminAppId" --api "$MSGraphAPI" --api-permissions "$Permission"
adminClientSecret=$(az ad app credential reset --id $adminAppId --display-name $clientSecretName --query password --output tsv)

# Configure App Services with the Azure AD App Registration
echo "Configure App Service Authentication for $websiteName"

curVersion=$(az webapp auth config-version show -g $rgName -n $websiteName --query configVersion -o tsv)
if [ "$curVersion" == "v1" ]; then
    echo "Upgrading to 2.0"
    az webapp auth config-version upgrade -g $rgName -n $websiteName
fi

az webapp auth microsoft update --name $websiteName --resource-group $rgName \
 --client-id $appId \
 --client-secret $clientSecret \
 --issuer https://sts.windows.net/$tenantId/v2.0 \
 --yes
az webapp auth update --name $websiteName --resource-group $rgName \
 --enabled true \
 --enable-token-store true \
 --action RedirectToLoginPage \
 --redirect-provider azureActiveDirectory 

echo "Configure App Service Authentication for $websiteAdminName"

curVersion=$(az webapp auth config-version show -g $rgName -n $websiteAdminName --query configVersion -o tsv)
if [ "$curVersion" == "v1" ]; then
    echo "Upgrading to 2.0"
    az webapp auth config-version upgrade -g $rgName -n $websiteAdminName
fi

az webapp auth microsoft update --name $websiteAdminName --resource-group $rgName \
 --client-id $adminAppId \
 --client-secret $adminClientSecret \
 --issuer https://sts.windows.net/$tenantId/v2.0 \
 --yes
az webapp auth update --name $websiteAdminName --resource-group $rgName \
 --enabled true \
 --enable-token-store true \
 --action RedirectToLoginPage \
 --redirect-provider azureActiveDirectory
