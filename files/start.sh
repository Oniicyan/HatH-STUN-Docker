#!/bin/sh

echo 开始执行 Hentai@Home with STUN

mount | grep '/hath ' >/dev/null || (
echo 未挂载工作目录
echo 将在容器层上进行读写，性能较低且数据不持久
mkdir -p /hath )

# 仅指定已挂载的自定义目录
[ -d /hath_cache ] && export HathCache=/hath_cache && echo 已挂载并指定自定义缓存目录
[ -d /hath_data ] && export HathData=/hath_data && echo 已挂载并指定自定义数据目录
[ -d /hath_download ] && export HathDownload=/hath_download  && echo 已挂载并指定自定义下载目录
[ -d /hath_log ] && export HathLog=/hath_log && echo 已挂载并指定自定义日志目录
[ -d /hath_temp ] && export HathTemp=/hath_temp  && echo 已挂载并指定自定义临时目录

# 如未指定 HathClientId 或 HathClientKey，则从 client_login 中读取
[ $HathData ] || HathData=/hath/data
mkdir -p $HathData
if [ $HathClientId ] && [ $HathClientKey ]; then
	echo -n ''$HathClientId'-'$HathClientKey'' >$HathData/client_login
else
	if [ -f $HathData/client_login ]; then
		export HathClientId=$(awk -F '-' '{print$1}' $HathData/client_login)
		export HathClientKey=$(awk -F '-' '{print$2}' $HathData/client_login)
	fi
fi
([ $(echo $HathClientId | grep -E '^[0-9]*$') ] && [ $(echo -n $HathClientKey | wc -m) = 20 ]) || \
(echo H@H 客户端 ID 或密钥格式不正确)

ADD_UPNP() {
	[ $UpnpInterface ] && UpnpInterface='-m '$UpnpInterface''
	[ $UpnpUrl ] && UpnpUrl='-u '$UpnpUrl''
	[ $UpnpAddr ] || UpnpAddr=@
	if [ $Stun ]; then
		UpnpInPort=$StunHathPort
		UpnpExPort=$StunBindPort
	else
		if [ ! $UpnpInPort ] || [ ! $UpnpExPort ]; then
			if [ ! $UpnpClientPort ]; then
				ActTime=$(date +%s)
				ActKey=$(echo -n "hentai@home-client_settings--$HathClientId-$ActTime-$HathClientKey" | sha1sum | cut -c -40)
				UpnpClientPort=$(curl -Ls 'http://rpc.hentaiathome.net/15/rpc?clientbuild='$BUILD'&act=client_settings&add=&cid='$HathClientId'&acttime='$ActTime'&actkey='$ActKey'' | grep port= | grep -oE '[0-9]*')
			fi
			if [ $UpnpClientPort ];then
				[ $UpnpInPort ] || UpnpInPort=$UpnpClientPort
				[ $UpnpExPort ] || UpnpExPort=$UpnpClientPort
			else
				echo 获取端口信息失败，跳过 UPnP
				return 1
			fi
		fi
	fi
	echo 本次 UPnP 规则：转发 外部端口 $UpnpExPort 至 内部端口 $UpnpInPort
	UpnpStart='upnpc '$UpnpArgs' '$UpnpInterface' '$UpnpUrl' -i -e "STUN H@H Client@'$HathClientId'" -a '$UpnpAddr' '$UpnpInPort' '$UpnpExPort' tcp'
	echo 本次 UPnP 执行命令
	echo $UpnpStart
	$UpnpStart
}

rm -f /hath/WANPORT
if [ $Stun ]; then
	echo 已启用 STUN，穿透后启动 H@H 客户端
	([ $(echo $StunIpbId | grep -E '^[0-9]*$') ] && [ $(echo -n $StunIpbPass | wc -m) = 32 ]) || \
	(echo 用户 ID '(ipb_member_id)' 或密钥 '(ipb_pass_hash)' 格式不正确 && exit 1)
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
		echo 已启用 STUN 转发，目标为 $StunForwardAddr:$StunHathPort；跳过请求地址检测
	fi
	[ $Upnp ] && echo 已启用 UPnP，开始执行 && ADD_UPNP
	NatmapStart='natmap '$StunArgs' -4 -s '$StunServer' -h '$StunHttpServer' -b '$StunBindPort' -k '$StunInterval' '$StunInterface' '$StunForward' -e /files/natmap.sh'
	echo 本次 NATMap 执行命令
	echo $NatmapStart
	exec $NatmapStart
else
	echo 未启用 STUN，直接启动 H@H 客户端
	[ $Upnp ] && echo 已启用 UPnP，开始执行 && ADD_UPNP
	exec hath.sh
fi
