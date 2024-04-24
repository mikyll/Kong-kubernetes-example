#!/bin/bash

NAMESPACE="kong"

DEPLOYMENT=$(kubectl get deployment -n "$NAMESPACE" --no-headers | grep '[ingress|kong]*gateway*' | cut -f1 -d' ')

winpty kubectl exec -it -n "$NAMESPACE" deployments/"$DEPLOYMENT" -- bash