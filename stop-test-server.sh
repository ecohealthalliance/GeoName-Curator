#!/bin/bash

# stops the test server if it is running and removes the pid file

pwd=$(pwd)
pid_file=$pwd/tests/eidr-connect-test-server.pid
log_file=$pwd/tests/log/eidr-connect-test-server.log

if [ -f "${pid_file}" ]; then
  PID=`cat ${pid_file}`
  if ps -p $PID > /dev/null
  then
    echo $'\nStopping the test server'
    kill -9 $PID
    rm $pid_file
  fi
fi
