#!/bin/bash
#
####################
# stop motion
####################
pkill -9 motion
# pkill -SIGKILL motion
#
####################
# post-processing
####################
# What is does:
# - Concatenate videos of today
# - Copy videos and file list to USB (if USB is plugged in)
# - Upload both to server (if server is available)
NOW=$(date +"%Y-%m-%d_%H-%M-%S")
bash util/postprocessing.sh >>log/stop-$NOW.log 2>&1

