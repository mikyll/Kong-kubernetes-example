#!/bin/bash

# Usage:
#   ./kong_install_gd.sh [kong|ingress]
#
# Installs Kong in Gateway Discovery (GD) mode. Default: kong/ingress chart.
# 

CHART="${1}"
NAMESPACE="kong"
VALUES_DIR="values/"
RESOURCES_DIR="resources/"
CUSTOM_PLUGINS_DIR="${RESOURCES_DIR}custom_plugins/"

# Install Gateway API CRDs
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.0.0/standard-install.yaml

# Create Gateway and GatewayClass instances to be used
kubectl apply -f "${RESOURCES_DIR}gateway.yaml"

# Add chart and Update Kong
helm repo add kong https://charts.konghq.com
helm repo update

if [[ "${CHART}" == "kong" ]]
then
  # Install kong/kong with 2 separate Kong releases:
  # Gateway release
  helm install gateway kong/kong -n "$NAMESPACE" --create-namespace -f "${VALUES_DIR}minimal-kong-gd-gateway.yaml"
  # Controller release
  helm install controller kong/kong -n "$NAMESPACE" -f "${VALUES_DIR}minimal-kong-gd-controller.yaml"
else
  # Add custom plugins
  for PLUGIN in "$CUSTOM_PLUGINS_DIR"*.yaml
  do
    kubectl apply -f "$PLUGIN"
  done

  # Install kong/ingress
  helm install kong kong/ingress -n "$NAMESPACE" -f "${VALUES_DIR}ingress-values.yaml"
fi

# Test Kubernetes resources
kubectl apply -f "${RESOURCES_DIR}echo-test.yaml"

# Wait for Kong to be ready
#echo -e "\nWaiting for Kong to be ready..."
#kubectl wait --for="condition=ready" pods --all -n "$NAMESPACE" --timeout=1m
#echo -e "\nKong is ready!"

echo ""
read -p "Press any key to continue" x