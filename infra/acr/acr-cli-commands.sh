#Fill in these parameters before running this script
rgName=resource-group-name
location=location
acrName=acr-name

# Can use AZ CLI or Bicep to deploy the resources

# Use Bicep to deploy the Azure Container Registry
#az deployment group create --resource-group $rgName --template-file main.bicep --parameters location=$location acrName=$acrName

# Use AZ CLI to create an Azure Container Registry
az acr create --name $acrName --resource-group $rgName --sku Basic --admin-enabled false

# Import a public image into the container registry
az acr import --name $acrName --source fruoccopublic.azurecr.io --image rag-webapp:latest
az acr import --name $acrName --source fruoccopublic.azurecr.io --image rag-adminwebapp:latest
az acr import --name $acrName --source fruoccopublic.azurecr.io --image rag-backend:latest
