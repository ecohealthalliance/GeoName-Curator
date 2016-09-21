#!/bin/bash
meteor test --full-app --driver-package tmeasday:acceptance-test-driver &
APP_PID=$!
sleep 5

chimp=node_modules/chimp/bin/chimp.js

# Run the tests
$chimp  --ddp=http://localhost:13000 \
        --path=tests/ \
        --browser=phantomjs \
        --debug=true \
        --coffee=true \
        --compiler=coffee:coffee-script/register

# Output time elapsed
echo "$(($SECONDS / 60)) minutes and $(($SECONDS % 60)) seconds elapsed"

kill $APP_PID
