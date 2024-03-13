#!/bin/bash

NAMESPACE="kong"
RESOURCES_DIR="resources/"
CUSTOM_PLUGINS_DIR="${RESOURCES_DIR}custom_plugins/"

N_RELEASES=0
for RELEASE in $(helm list -n "$NAMESPACE" --short)
do
  N_RELEASES=$(expr $N_RELEASES + 1)
done

if [[ N_RELEASES -ne 0 ]]
then
  for RELEASE in $(helm list -n kong --short)
  do
    helm uninstall -n "$NAMESPACE" "$RELEASE"
  done
else
  echo "No releases were found for namespace \'${NAMESPACE}\'."
fi
  
kubectl delete -f "${RESOURCES_DIR}gateway.yaml"
kubectl delete -f "${RESOURCES_DIR}echo-test.yaml"

for PLUGIN in "${CUSTOM_PLUGINS_DIR}"*.yaml
do
  kubectl delete -f "${PLUGIN}"
done

echo ""
read -p "Press any key to continue" x