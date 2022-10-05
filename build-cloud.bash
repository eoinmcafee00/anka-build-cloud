#!/usr/bin/env bash

NAMESPACE="anka-build-cloud"
kubectl config set-context --current --namespace="${NAMESPACE}"
NAME="anka-app"

if [[ "${1}" == "delete" ]]; then
  helm uninstall "${NAME}" || true
else
    helm install "${NAME}" build-cloud-chart
fi
