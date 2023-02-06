SHELL := bash

MK_FILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
ROOT_PATH := $(realpath $(dir $(MK_FILE_PATH)))


.PHONY: cluster-down
cluster-down:
	k3d cluster delete ray-cluster

.PHONY: launch-kubernetes
launch-kubernetes: cluster-down
	k3d cluster create ray-cluster
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
launch-private-img-cluster: launch-kubernetes setup-img-secret
	helm install -f $(ROOT_PATH)/private-image-helm-chart/values.yaml raycluster $(ROOT_PATH)/private-image-helm-chart

expose-ports:
	kubectl port-forward --address 0.0.0.0 svc/raycluster-kuberay-head-svc 8265:8265 &
	kubectl port-forward --address 0.0.0.0 svc/raycluster-kuberay-head-svc 10001:10001 &
