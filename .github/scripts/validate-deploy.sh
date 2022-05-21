#!/usr/bin/env bash

export KUBECONFIG=$(cat .kubeconfig)

oc get nodes
