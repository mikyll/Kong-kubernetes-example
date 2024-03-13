#!/bin/bash

NAMESPACE="kong"

if [[ $1 -eq 1 ]] || [[ $1 -eq 2 ]]
then
    SELECTION=$1
else
    echo -e "Which logs you want to watch?\n1. Controller\n2. Gateway\n"
    read -p "Selection: " SELECTION
fi

while [[ $SELECTION -ne 1 ]] && [[ $SELECTION -ne 2 ]]
do
    echo -e "Invalid selection, type '1' or '2'\n1. Controller\n2. Gateway\n"
    read -p "Selection: " SELECTION
done

if [[ $SELECTION -eq 1 ]]
then
    printf '\033[8;30;250t'
    printf '\033[3;0;0t'
    DEPLOYMENT=$(kubectl get deployment -n "$NAMESPACE" --no-headers | grep '[ingress|kong]*controller*' | cut -f1 -d' ')
else
    printf '\033[8;30;250t'
    printf '\033[3;0;500t'
    DEPLOYMENT=$(kubectl get deployment -n "$NAMESPACE" --no-headers | grep '[ingress|kong]*gateway*' | cut -f1 -d' ')
fi

kubectl logs -n "$NAMESPACE" -f deployments/"$DEPLOYMENT"

echo ""
read -p "Press any key to continue" x