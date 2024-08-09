# Parameters
IMAGE_NAME=$1
ACR_HOST=$2

IMAGE_TAG=$(date +"%Y%m%d-%H%M%S")
LATEST_TAG="latest"

echo ""
echo "...$IMAGE_NAME..."
echo ""


echo "=> Docker image creation is starting"
docker build -t $IMAGE_NAME:$IMAGE_TAG -t $IMAGE_NAME:$LATEST_TAG -f ./Dockerfile .
if [ $? -ne 0 ]; then
  echo "=> Docker image creation was failed"
  exit 1
else
  echo "=> Docker image creation was completed"
fi

echo "=> Docker image tagging is starting"
docker tag $IMAGE_NAME:$IMAGE_TAG $ACR_HOST/$IMAGE_NAME:$IMAGE_TAG
if [ $? -ne 0 ]; then
  echo "=> Docker image tagging (1) was failed"
  exit 1
fi

docker tag $IMAGE_NAME:$LATEST_TAG $ACR_HOST/$IMAGE_NAME:$LATEST_TAG
if [ $? -ne 0 ]; then
  echo "=> Docker image tagging (2) was failed"
  exit 1
else
  echo "=> Docker image tagging was completed"
fi

echo "=> Docker image pushing is starting"
docker push $ACR_HOST/$IMAGE_NAME:$IMAGE_TAG
if [ $? -ne 0 ]; then
  echo "=> docker image push (1) was failed"
  exit 1
fi
docker push $ACR_HOST/$IMAGE_NAME:$LATEST_TAG
if [ $? -ne 0 ]; then
  echo "=> docker image push (2) was failed"
  exit 1
else
  echo "=> Docker image pushing was completed"
fi