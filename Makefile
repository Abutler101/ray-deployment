SHELL := bash

MK_FILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
ROOT_PATH := $(realpath $(dir $(MK_FILE_PATH)))

.PHONY: launch-stock-cluster
launch-stock-cluster: cluster-down
	k3d cluster create ray-cluster
	helm repo add kuberay https://ray-project.github.io/kuberay-helm/
	helm install kuberay-operator kuberay/kuberay-operator --version 0.4.0
	helm install -f $(ROOT_PATH)/stock-helm-chart/values.yaml raycluster $(ROOT_PATH)/stock-helm-chart

expose-ports:
	kubectl port-forward --address 0.0.0.0 svc/raycluster-kuberay-head-svc 8265:8265 &
	kubectl port-forward --address 0.0.0.0 svc/raycluster-kuberay-head-svc 10001:10001 &

.PHONY: cluster-down
cluster-down:
	k3d cluster delete ray-cluster