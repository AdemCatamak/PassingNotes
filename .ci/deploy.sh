#!/bin/bash

# Azure Service Principle Creation Flow
# https://learn.microsoft.com/en-us/training/modules/authenticate-azure-deployment-pipeline-service-principals/?source=recommendations

echo 'Sample Usage => deploy.sh <APP_PRINCIPLE_ID> <APP_PRINCIPLE_KEY> <TENANT_ID> <SUBSCRIPTION_ID> <RESOURCE_GROUP_NAME> <OPTIONAL REGION>'

# Parameters
APP_PRINCIPLE_ID=$1
APP_PRINCIPLE_PASS=$2
TENANT_ID=$3
SUBSCRIPTION_ID=$4
RESOURCE_GROUP_NAME=$5
LOCATION=${6:-westeurope}

PASSING_NOTES_APP_IMAGE_NAME="passing-notes-app"
PASSING_NOTES_APP_PORT=80


echo " "
# LOGIN

echo "=> az login is starting"
az login --service-principal -u $APP_PRINCIPLE_ID -p $APP_PRINCIPLE_PASS --tenant $TENANT_ID
if [ $? -ne 0 ]; then
  echo "=> az login was failed"
  exit 1
fi


echo " "
# REDIS
REDIS_NAME="passing-notes-redis"
REDIS_SKU="Standard"
REDIS_SIZE="c1"

EXISTING_REDIS=$(az redis show --name $REDIS_NAME --resource-group $RESOURCE_GROUP_NAME --query "name" --output tsv)

if [ -z "$EXISTING_REDIS" ]; then
    echo "Redis Cache '$REDIS_NAME' is being created..."
    az redis create \
      --name $REDIS_NAME \
      --resource-group $RESOURCE_GROUP_NAME \
      --location $LOCATION \
      --sku $REDIS_SKU \
      --vm-size $REDIS_SIZE \
      --enable-non-ssl-port
else
    echo "Redis Cache '$REDIS_NAME' already exist... Updating process is being triggered"
    az redis update \
      --name $REDIS_NAME \
      --resource-group $RESOURCE_GROUP_NAME \
      --sku $REDIS_SKU \
      --vm-size $REDIS_SIZE \
      --set "enableNonSslPort"=true
fi

if [ $? -ne 0 ]; then
  echo "=> Redis related process was failed"
  exit 1
fi

REDIS_HOST=$(az redis show --name $REDIS_NAME --resource-group $RESOURCE_GROUP_NAME --query "hostName" --output tsv)
REDIS_PORT=$(az redis show --name $REDIS_NAME --resource-group $RESOURCE_GROUP_NAME --query "port" --output tsv)
REDIS_PRIMARY_KEY=$(az redis list-keys --name $REDIS_NAME --resource-group $RESOURCE_GROUP_NAME --query "primaryKey" --output tsv)


echo " "
# LOG ANALYTICS
LA_WORKSPACE_NAME="passing-notes-la"
LA_RETENTION_DAYS=30

LA_EXISTING_WORKSPACE=$(az monitor log-analytics workspace show --resource-group $RESOURCE_GROUP_NAME --workspace-name $LA_WORKSPACE_NAME --query "name" --output tsv)

if [ -z "$LA_EXISTING_WORKSPACE" ]; then
    echo "Log Analytics Workspace '$LA_WORKSPACE_NAME' is being created..."
    az monitor log-analytics workspace create --resource-group $RESOURCE_GROUP_NAME --workspace-name $LA_WORKSPACE_NAME --location $LOCATION --retention-time $LA_RETENTION_DAYS
else
    echo "Log Analytics Workspace '$LA_WORKSPACE_NAME' already exist... Updating process is being triggered"
    az monitor log-analytics workspace update --resource-group $RESOURCE_GROUP_NAME --workspace-name $LA_WORKSPACE_NAME --set retentionInDays=$LA_RETENTION_DAYS
fi

if [ $? -ne 0 ]; then
  echo "=> Log Analytics related process was failed"
  exit 1
fi

LA_WORKSPACE_ID=$(az monitor log-analytics workspace show --resource-group $RESOURCE_GROUP_NAME --workspace-name $LA_WORKSPACE_NAME --query "customerId" --output tsv)
LA_PRIMARY_KEY=$(az monitor log-analytics workspace get-shared-keys --resource-group $RESOURCE_GROUP_NAME --workspace-name $LA_WORKSPACE_NAME --query "primarySharedKey" --output tsv)

echo " "
# AZURE CONTAINER REGISTERY
ACR_NAME="passingnotesacr"
ACR_SKU="Standard"

EXISTING_ACR=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP_NAME --query "name" --output tsv)

if [ -z "$EXISTING_ACR" ]; then
    echo "Azure Container Registry '$ACR_NAME' is being created..."
    az acr create \
      --resource-group $RESOURCE_GROUP_NAME \
      --name $ACR_NAME \
      --location $LOCATION \
      --sku $ACR_SKU \
      --admin-enabled true
else
    echo "Azure Container Registry '$ACR_NAME' already exist... Updating process is being triggered"
    az acr update \
      --name $ACR_NAME \
      --resource-group $RESOURCE_GROUP_NAME \
      --sku $ACR_SKU \
      --admin-enabled true
fi

if [ $? -ne 0 ]; then
  echo "=> Azure Container Registry related process was failed"
  exit 1
fi

ACR_LOGIN_SERVER=$(az acr show --name $ACR_NAME --resource-group $RESOURCE_GROUP_NAME --query "loginServer" --output tsv)
ACR_ADMIN_USERNAME=$(az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP_NAME --query "username" --output tsv)
ACR_ADMIN_PASSWORD=$(az acr credential show --name $ACR_NAME --resource-group $RESOURCE_GROUP_NAME --query "passwords[0].value" --output tsv)

echo "=> Azure Container Registery login is starting"
az acr login -n $ACR_NAME
if [ $? -ne 0 ]; then
  echo "=> Azure Container Registery login was failed"
  exit 1
fi

echo " "
# DEPLOY PN APP IMAGE
bash ./.ci/pn-app-image-deploy.sh $PASSING_NOTES_APP_IMAGE_NAME $ACR_LOGIN_SERVER
if [ $? -ne 0 ]; then
    echo "=> Azure Container Registry related process was failed"
    exit 1
fi


echo " "
# AZURE CONTAINER INSTANCE
ACI_NAME="passing-notes-app"
ACI_IMAGE="$ACR_LOGIN_SERVER/$PASSING_NOTES_APP_IMAGE_NAME:latest"

echo "Azure Container Instance '$ACI_NAME' deployment is starting..."
az container create \
  --resource-group $RESOURCE_GROUP_NAME \
  --name $ACI_NAME \
  --image $ACI_IMAGE \
  --location $LOCATION \
  --ports $PASSING_NOTES_APP_PORT \
  --dns-name-label $PASSING_NOTES_APP_IMAGE_NAME \
  --cpu 1 --memory 2 \
  --registry-login-server $ACR_LOGIN_SERVER \
  --registry-username $ACR_ADMIN_USERNAME \
  --registry-password $ACR_ADMIN_PASSWORD \
  --environment-variables REDIS_HOST="${REDIS_HOST}:${REDIS_PORT}" \
  --secure-environment-variables REDIS_PASS=$REDIS_PRIMARY_KEY \
  --log-analytics-workspace $LA_WORKSPACE_ID \
  --log-analytics-workspace-key $LA_PRIMARY_KEY


if [ $? -ne 0 ]; then
  echo "=> Azure Container Instance related process was failed"
  exit 1
fi

ACI_FQDN=$(az container show --name $ACI_NAME --resource-group $RESOURCE_GROUP_NAME --query "ipAddress.fqdn" --output tsv)
echo "Container Instance FQDN: $ACI_FQDN"
