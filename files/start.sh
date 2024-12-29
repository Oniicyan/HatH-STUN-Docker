#!/bin/sh

# 仅指定已映射的自定义目录
[ -d /hath_cache ] && export HathCache=/hath_cache && echo [$(date)] 已指定自定义缓存目录
[ -d /hath_data ] && export HathData=/hath_data && echo [$(date)] 已指定自定义数据目录
[ -d /hath_download ] && export HathDownload=/hath_download  && echo [$(date)] 已指定自定义下载目录
[ -d /hath_log ] && export HathLog=/hath_log && echo [$(date)] 已指定自定义日志目录
[ -d /hath_temp ] && export HathTemp=/hath_temp  && echo [$(date)] 已指定自定义临时目录

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
(echo [$(date)] H@H 客户端 ID 或密钥格式不正确 && exit 1)

ADD_UPNP() {
	[ $UpnpAddr ] || UpnpAddr=@
	[ $UpnpUrl ] && UpnpUrl='-u '$UpnpUrl''
	if [ $Stun ]; then
		UpnpInPort=$StunHathPort
		UpnpExPort=$StunBindPort
	else
		if [ ! $UpnpInPort ] || [ ! $UpnpExPort ]; then
			if [ ! $UpnpClientPort ]; then
				ActTime=$(date +%s)
				ActKey=$(echo -n "hentai@home-client_settings--$HathClientId-$ActTime-$HathClientKey" | sha1sum | cut -c -40)
				UpnpClientPort=$(curl -Ls 'http://rpc.hentaiathome.net/15/rpc?clientbuild=169&act=client_settings&add=&cid='$HathClientId'&acttime='$ActTime'&actkey='$ActKey'' | grep port= | grep -oE '[0-9]*')
			fi
			if [ $UpnpClientPort ];then
				[ $UpnpInPort ] || UpnpInPort=$UpnpClientPort
				[ $UpnpExPort ] || UpnpExPort=$UpnpClientPort
			else
				echo [$(date)] 获取端口信息失败，跳过 UPnP
				return 1
			fi
		fi
	fi
	echo [$(date)] 本次 UPnP 规则：转发 外部端口 $UpnpExPort 至 内部端口 $UpnpInPort
	UpnpStart='upnpc -4 -i -e "STUN H@H Client@'$HathClientId'" -a '$UpnpAddr' '$UpnpInPort' '$UpnpExPort' tcp '$UpnpUrl' '$UpnpArgs''
	echo [$(date)] 本次 UPnP 执行命令
	echo [$(date)] $UpnpStart
	$UpnpStart
}

if [ $Stun ]; then
	echo [$(date)] 已启用 STUN 模式，穿透后启动 H@H 客户端
	([ $(echo $StunIpbId | grep -E '^[0-9]*$') ] && [ $(echo -n $StunIpbPass | wc -m) = 32 ]) ||\
	(echo [$(date)] 用户 ID '(ipb_member_id)' 或密钥 '(ipb_pass_hash)' 格式不正确 && exit 1)
	[ $StunServer ] || StunServer=turn.cloudflare.com
	[ $StunHttpServer ] || StunHttpServer=qq.com
	[ $StunBindPort ] || StunBindPort=44377
	[ $StunHathPort ] || StunHathPort=44388
	export HathPort=$StunHathPort
	[ $StunInterval ] || StunInterval=25
	[ $StunInterface ] && StunInterface='-i '$StunInterface''
	if [ $StunForward ]; then
		[ $StunForwardAddr ] || StunForwardAddr=127.0.0.1
		StunForward='-t '$StunForwardAddr' -p '$StunHathPort''
		export HathSkipIpCheck=1
	fi
	[ $Upnp ] && echo [$(date)] 已启用 UPnP，开始执行 && ADD_UPNP
	NatmapStart='natmap -d -4 -s '$StunServer' -h '$StunHttpServer' -b '$StunBindPort' -k '$StunInterval' '$StunInterface' '$StunForward' -e natmap.sh'
	echo [$(date)] 本次 NATMap 执行命令
	echo [$(date)] $NatmapStart
	$NatmapStart
else
	echo [$(date)] 未启用 STUN 模式，直接启动 H@H 客户端
	[ $Upnp ] && echo [$(date)] 已启用 UPnP，开始执行 && ADD_UPNP
	hath.sh
fi
