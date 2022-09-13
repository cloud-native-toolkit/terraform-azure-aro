#!/usr/bin/env bash

export KUBECONFIG="$(terraform output -raw config_file_path)"

oc get nodes
