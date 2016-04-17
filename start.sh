#!/bin/bash
#
NOW=$(date +"%Y-%m-%d_%H-%M-%S")
# Is the webcam connected
if [ -c /dev/video0 ]
then
	echo "webcam connected" >>log/start_$NOW.log
else
	echo "webcam not connected but will used it as soon as connected" >>log/start_$NOW.log
fi
pkill -9 motion
sleep 10
motion -c conf/motion.conf >>log/start_$NOW.log 2>&1
# Check if motion is running already
#if [ -z "$(pgrep motion)" ]
#then
#	motion -c conf/motion.conf >>log/start_$NOW.log 2>&1
#else
#    echo "Motion is running already" >> log/start_$NOW.log
#fi
# xterm -e tail -n 0 -f /var/log/motion/motion.log &

