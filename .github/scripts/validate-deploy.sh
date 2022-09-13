#!/usr/bin/env bash

# Below is due to file length error with oc when running on github runner
cat $(terraform output -raw config_file_path) > /tmp/kubeconfig

export KUBECONFIG="/tmp/kubeconfig"

oc get nodes

rm /tmp/kubeconfig
