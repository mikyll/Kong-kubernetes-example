#!/bin/bash

NAMESPACE="kong"

for DIR in *
do
  # Check if the file is a DIRectory
  if [[ -d "$DIR" ]]
  then
    
    # Skip DIRectory starting with "_"
    if [[ "$DIR" =~ ^_ ]]
    then
      continue
    fi
    
    # Check if the DIRectory contains the 2 files (handler & schema)
    if [[ -f "${DIR}/handler.lua" ]] && [[ -f "${DIR}/schema.lua" ]]
    then
      # Create configmap manifest
      echo "Creating ConfigMap for ${DIR}..."
      kubectl create configmap "$DIR" --from-file="$DIR" -n "$NAMESPACE" --dry-run=client -o yaml > "${DIR}.yaml"
    else
      echo "Files 'handler.lua' or 'schema.lua' are missing"
    fi
  fi
done

echo ""
read -p "Press any key to continue" x