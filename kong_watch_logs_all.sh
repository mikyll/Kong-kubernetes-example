#!/bin/bash

TIMEOUT=5m

timeout $TIMEOUT "C:\Users\mirighi\Programs\Git\git-bash.exe" -c "./kong_watch_logs.sh 1" &

timeout $TIMEOUT "C:\Users\mirighi\Programs\Git\git-bash.exe" -c "./kong_watch_logs.sh 2" &

#read -p "Press any key to continue" x