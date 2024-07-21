#!/bin/bash

INTPUT_LUA="$1"
OUTPUT_LUA="$2"

if [ ! -f $INPUT_LUA ]; then
	echo "ERROR: Input file is missing"
	exit 1
fi

if [ -f $OUTPUT_LUA ]; then
	cp $OUTPUT_LUA ${OUTPUT_LUA}_$(date +'%F_%H-%M-%S').backup
fi

cat $INTPUT_LUA > $OUTPUT_LUA
