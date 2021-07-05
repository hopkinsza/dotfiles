#!/bin/sh

printf -- 'starting in 5 seconds...'
sleep 5
printf -- ' [ ok ]\n'

while :; do
	# init conversation
	xdotool keydown e
	sleep 2
	xdotool keyup e

	# wait for dialogue to appear, then choose option
	sleep 2

	xdotool mousedown 1
	sleep 2
	xdotool mouseup 1

	# skip through all of the shit that he might say
	for x in 1 2 3; do
		sleep 1
		xdotool mousedown 1
		sleep 3
		xdotool mouseup 1
		sleep 0.2
		xdotool click 1
	done
done
