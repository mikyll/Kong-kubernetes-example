#!/bin/bash

RESOURCES_DIR="resources/"

kubectl apply -f "${RESOURCES_DIR}echo-test.yaml"

echo ""
read -p "Press any key to continue" x