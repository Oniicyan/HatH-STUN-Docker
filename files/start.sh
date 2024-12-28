#!/bin/sh

cd /files

if [ $Stun ]; then
	[ $StunServer ] || StunServer=turn.cloudflare.com
	[ $StunHttpServer ] || StunHttpServer=qq.com
	[ $StunBindPort ] || StunBindPort=44377
	[ $StunHathPort ] || StunHathPort=44388
	export HathPort=$StunHathPort
	if [ $StunForward ]; then
		[ $StunForwardAddr ] || StunForwardAddr=127.0.0.1
		StunForward='-t '$StunForwardAddr' -p '$StunHathPort''
		export HathSkipIpCheck=1
	fi
	NatmapStart='natmap -s '$StunServer' -h '$StunHttpServer' -b '$StunBindPort' '$StunForward' -e /files/natmap.sh'
	echo $(date) 本次 NATMap 执行命令如下
	echo $(date) $NatmapStart
	$NatmapStart
else
	hath.sh
fi
