#!/bin/sh

if [ $Stun ]; then
	natmap.sh
else
	hath.sh
fi
