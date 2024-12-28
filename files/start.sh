#!/bin/sh

# 仅指定已映射的目录
[ -d /hath_cache ] && export HathCache=/hath_cache
[ -d /hath_data ] && export HathData=/hath_data
[ -d /hath_download ] && export HathDownload=/hath_download
[ -d /hath_log ] && export HathLog=/hath_log
[ -d /hath_temp ] && export HathTemp=/hath_temp

# 如未指定 HathClientId 或 HathClientKey，则从 client_login 中读取
[ $HathData ] || HathData=/hath/data
if [ $HathClientId ] && [ $HathClientKey ]; then
	echo -n ''$HathClientId'-'$HathClientKey'' >$HathData/client_login
else
	if [ -f $HathData/client_login ]; then
		export HathClientId=$(cat $HathData/client_login | awk -F '-' '{print$1}')
		export HathClientKey=$(cat $HathData/client_login | awk -F '-' '{print$2}')
	fi
fi
([ $(echo $HathClientId | grep -E '^[0-9]*$') ] && [ $(echo -n $HathClientKey | wc -m) = 20 ]) ||\
(echo H@H 客户端 ID 或密钥不正确 && exit)

# 如未指定 STUN 模式，则直接启动 H@H 客户端
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
	NatmapStart='natmap -s '$StunServer' -h '$StunHttpServer' -b '$StunBindPort' '$StunForward' -e natmap.sh'
	echo $(date) 本次 NATMap 执行命令如下
	echo $(date) $NatmapStart
	$NatmapStart
else
	hath.sh
fi
