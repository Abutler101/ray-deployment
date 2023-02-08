SHELL := bash

MK_FILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
ROOT_PATH := $(realpath $(dir $(MK_FILE_PATH)))

.PHONY: build-priv-gpu-img
build-priv-gpu-img:
	DOCKER_BUILDKIT=1 docker build -f $(ROOT_PATH)/custom-image/Dockerfile.gpu -t nexus.dataspartan.com:9443/turintech/ray/ml-gpu-public-deps \
$(ROOT_PATH)/custom-image --secret id=pip-config,src=$(HOME)/.config/pip/pip.conf --secret id=pip-netrc,src=$(HOME)/.netrc

.PHONY: build-priv-cpu-img
build-priv-cpu-img:
	DOCKER_BUILDKIT=1 docker build -f $(ROOT_PATH)/custom-image/Dockerfile.cpu -t nexus.dataspartan.com:9443/turintech/ray/ml-cpu-public-deps \
$(ROOT_PATH)/custom-image --secret id=pip-config,src=$(HOME)/.config/pip/pip.conf --secret id=pip-netrc,src=$(HOME)/.netrc

.PHONY: build-imgs
build-imgs: build-priv-gpu-img build-priv-cpu-img

.PHONY: cluster-down
cluster-down:
	k3d cluster delete ray-cluster

.PHONY: launch-kubernetes
launch-kubernetes: cluster-down
	k3d cluster create ray-cluster
	helm repo add kuberay https://ray-project.github.io/kuberay-helm/
	helm install kuberay-operator kuberay/kuberay-operator --version 0.4.0

.PHONY: build-k3s-cuda
build-k3s-cuda:
	k3d registry delete registry.ray.localhost
	k3d registry create registry.ray.localhost --port 11836
	cd $(ROOT_PATH)/cuda-k3d; ./build.sh
	docker tag docker.io/rancher/k3s:v1.25.6-k3s1-cuda k3d-registry.ray.localhost:11836/k3s-v1.25.6-k3s1-cuda:latest
	docker push k3d-registry.ray.localhost:11836/k3s-v1.25.6-k3s1-cuda:latest

.PHONY: launch-kubernetes-cuda
launch-kubernetes-cuda: cluster-down build-k3s-cuda
	k3d cluster create ray-cluster --image k3s-v1.25.6-k3s1-cuda:latest --registry-use k3d-registry.ray.localhost:11836
	helm repo add kuberay https://ray-project.github.io/kuberay-helm/
	helm install kuberay-operator kuberay/kuberay-operator --version 0.4.0

.PHONY: setup-img-secret
setup-img-secret:
	# registers `regcred` as a secret with the login details for nexus to enable pulling of private images
	kubectl create secret generic regcred --from-file=.dockerconfigjson=$(HOME)/.docker/config.json --type=kubernetes.io/dockerconfigjson

.PHONY: launch-stock-cluster
launch-stock-cluster: launch-kubernetes
	helm install -f $(ROOT_PATH)/stock-helm-chart/values.yaml raycluster $(ROOT_PATH)/stock-helm-chart

.PHONY: launch-public-img-cluster
launch-public-img-cluster: launch-kubernetes
	helm install -f $(ROOT_PATH)/custom-public-image-helm-chart/values.yaml raycluster $(ROOT_PATH)/custom-public-image-helm-chart

.PHONY: launch-private-img-cluster
launch-private-img-cluster: launch-kubernetes-cuda setup-img-secret
	helm install -f $(ROOT_PATH)/private-image-helm-chart/values.yaml raycluster $(ROOT_PATH)/private-image-helm-chart

.PHONY: launch-private-img-cluster-direct
launch-private-img-cluster-direct: launch-kubernetes-cuda setup-img-secret
	kubectl create -f $(ROOT_PATH)/private-img-direct-install/config.yaml

expose-ports:
	kubectl port-forward --address 0.0.0.0 svc/raycluster-kuberay-head-svc 8265:8265 &
	kubectl port-forward --address 0.0.0.0 svc/raycluster-kuberay-head-svc 10001:10001 &

expose-ports-direct-install:
	kubectl port-forward --address 0.0.0.0 svc/raycluster-autoscaler-head-svc 8265:8265 &
	kubectl port-forward --address 0.0.0.0 svc/raycluster-autoscaler-head-svc 10001:10001 &