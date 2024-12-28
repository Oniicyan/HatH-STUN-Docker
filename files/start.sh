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
		export HathClientId=$(awk -F '-' '{print$1}' $HathData/client_login)
		export HathClientKey=$(awk -F '-' '{print$2}' $HathData/client_login)
	fi
fi
([ $(echo $HathClientId | grep -E '^[0-9]*$') ] && [ $(echo -n $HathClientKey | wc -m) = 20 ]) ||\
(echo H@H 客户端 ID 或密钥格式不正确 && exit 1)

# 如未指定 STUN 模式，则直接启动 H@H 客户端
if [ $Stun ]; then
	([ $(echo $StunIpbId | grep -E '^[0-9]*$') ] && [ $(echo -n $StunIpbPass | wc -m) = 32 ]) ||\
	(echo 用户 ID（ipb_member_id）或密钥（ipb_pass_hash）格式不正确 && exit 1)
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
