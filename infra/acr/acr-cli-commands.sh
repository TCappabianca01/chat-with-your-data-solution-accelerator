#Fill in these parameters before running this script
rgName=rg-testacrscript
location=eastus
acrName=cmwacrtestscript

# Can use AZ CLI or Bicep to deploy the resources

# Use Bicep to deploy the Azure Container Registry
az deployment group create --resource-group $rgName --template-file main.bicep --parameters location=$location acrName=$acrName

# Use AZ CLI to create an Azure Container Registry
#az acr create --name $acrName --resource-group $rgName --sku Basic --admin-enabled false

# Import a public image into the container registry
az acr import --resource-group $rgName --name $acrName --source fruoccopublic.azurecr.io/rag-webapp:latest --image rag-webapp:latest
az acr import --resource-group $rgName --name $acrName --source fruoccopublic.azurecr.io/rag-adminwebapp:latest --image rag-adminwebapp:latest
az acr import --resource-group $rgName --name $acrName --source fruoccopublic.azurecr.io/rag-backend:latest --image rag-backend:latest
