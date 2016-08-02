#!/bin/bash
# This is for use with docker, please ignore otherwise

#Run our meteor app in production mode
export METEOR_SETTINGS=$(cat /shared/settings-production.json)
cd /build/bundle && node main.js
