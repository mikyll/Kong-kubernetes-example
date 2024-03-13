#!/bin/bash

cleanup() {
  kill $PID_ADMIN && echo "Killed Kong Admin API port-forward process"
  kill $PID_MANAGER && echo "Killed Kong Manager port-forward process"
  exit 0
}

trap "cleanup" SIGINT
trap "cleanup" SIGHUP

kubectl port-forward -n kong services/kong-gateway-admin 8001:8001 2>&1 &
PID_ADMIN=$!
kubectl port-forward -n kong services/kong-gateway-manager 8002:8002 2>&1 &
PID_MANAGER=$!

start http://localhost:8002

echo ""
read -p "Press any key to stop" x
echo ""

cleanup