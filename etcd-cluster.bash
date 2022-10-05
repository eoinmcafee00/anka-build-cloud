#!/usr/bin/env bash
set -exo pipefail
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
cd "${SCRIPT_DIR}"

kubectl apply -f namespace.yaml

NAMESPACE="anka-build-cloud"
HELM_NAMESPACE="${NAMESPACE}"
kubectl config set-context --current --namespace="${NAMESPACE}"
NAME="etcd"

if [[ "${1}" == "delete" ]]; then
  helm uninstall "${NAME}" || true
  sed -i '' 's/initialClusterState: "existing"/initialClusterState: "new"/g' .res/etcd-values.yaml
  if [[ "${2}" == "full" ]]; then
    sleep 60
    kubectl get pvc | tail -n+2 | awk '{print $1}' | grep "${NAME}" | xargs -I{} kubectl delete pvc/{}
  fi
else
  if helm -n anka-build-cloud list | grep etcd; then
    helm upgrade "${NAME}" bitnami/etcd -f .res/etcd-values.yaml \
      --set auth.rbac.rootPassword="$(kubectl get secret --namespace anka-build-cloud etcd -o jsonpath="{.data.etcd-root-password}" | base64 --decode)"
  else
    helm install "${NAME}" bitnami/etcd -f .res/etcd-values.yaml
    sed -i '' 's/initialClusterState: "new"/initialClusterState: "existing"/g' .res/etcd-values.yaml
  fi
fi