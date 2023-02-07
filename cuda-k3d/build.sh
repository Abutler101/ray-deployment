#!/bin/bash

set -euxo pipefail

K3S_TAG=${K3S_TAG:="v1.25.6+k3s1"} # replace + with -, if needed
IMAGE_REPOSITORY=${IMAGE_REPOSITORY:="rancher/k3s"}
IMAGE_TAG="${K3S_TAG//+/-}-cuda"
IMAGE=${IMAGE:="$IMAGE_REPOSITORY:$IMAGE_TAG"}

NVIDIA_CONTAINER_RUNTIME_VERSION=${NVIDIA_CONTAINER_RUNTIME_VERSION:="3.10.0-1"}

echo "IMAGE=$IMAGE"

# due to some unknown reason, copying symlinks fails with buildkit enabled
DOCKER_BUILDKIT=1 docker build \
  --build-arg K3S_TAG=$K3S_TAG \
  --build-arg NVIDIA_CONTAINER_RUNTIME_VERSION=$NVIDIA_CONTAINER_RUNTIME_VERSION \
  -t $IMAGE .
echo "Done!"
