#!/bin/bash

# Options
ENABLE_DATABASE=""
ENABLE_AUTOSCALING=""
ENABLE_DATABASE=""
ENABLE_CUSTOM_PLUGINS=""

VALUES_PLUGIN="
  # Custom plugins
  plugins:
    configMaps:"
for PLUGIN in 
do
VALUES_PLUGIN="${VALUES_PLUGIN}
    - name: ${PLUGIN}
      pluginName: ${PLUGIN}"
done