# Ray Kubernetes Cluster Management Examples
Provides a make file for launching various Ray CLuster configurations via helm onto a k3d cluster

## Pre-Requisites:
- K3d
- Helm

## Usage:
- From the table below identify the cluster config of interest, and it's corresponding launch command
- Run the launch command for the relevant config
- Run the command to expose the cluster ports `make expose-ports` <- this currently uses manual commands, but
there should be a way to configure the exposure of ports via files or something.
- Use the cluster
- Once finished run `make cluster-down`

## Cluster Configs:
- TBD