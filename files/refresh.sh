#!/bin/bash

[ $Stun ] ||\
(echo 未启用 STUN 模式，不执行刷新 && exit 1)

ps aux | grep natmap | grep -v grep ||\
(echo NATMap 未在运行，请重启容器 && exit 1)

[ -f /files/WANPORT ] ||\
(echo 未检测到公网端口，请检查 STUN 服务器 && exit 1)

echo 开始刷新 Hentai@Home with STUN

[ $HathData ] || HathData=/hath/data
HATHCID=$HathClientId
HATHKEY=$HathClientKey
EHIPBID=$(awk -F '-' '{print$1}' $HathData/client_login)
EHIPBPW=$(awk -F '-' '{print$2}' $HathData/client_login)
WANPORT=$(cat /files/WANPORT)

[ $StunProxy ] || echo STUN 模式未配置代理，请留意 H@H 客户端设置信息能否获取与更新
[ $StunProxy ] && PROXY='-x '$StunProxy''

# 获取 H@H 客户端设置信息
while [ -z $f_cname ]; do
	let GET++
 	[ $GET -gt 3 ] && echo 获取 H@H 客户端设置信息失败，请检查代理 && exit 1
 	[ $GET -ne 1 ] && echo 获取 H@H 客户端设置信息失败，15 秒后重试 && sleep 15
	HATHPHP=/tmp/settings.php
	>$HATHPHP
	curl $PROXY -Ls -m 15 \
	-b 'ipb_member_id='$EHIPBID'; ipb_pass_hash='$EHIPBPW'' \
	-o $HATHPHP \
	'https://e-hentai.org/hentaiathome.php?cid='$HATHCID'&act=settings'
	f_cname=$(grep f_cname $HATHPHP | awk -F '"' '{print$6}' | sed 's/[ ]/+/g')
	f_throttle_KB=$(grep f_throttle_KB $HATHPHP | awk -F '"' '{print$6}')
	f_disklimit_GB=$(grep f_disklimit_GB $HATHPHP | awk -F '"' '{print$6}')
	p_mthbwcap=$(grep p_mthbwcap $HATHPHP | awk -F '"' '{print$6}')
	f_diskremaining_MB=$(grep f_diskremaining_MB $HATHPHP | awk -F '"' '{print$6}')
	f_enable_bwm=$(grep f_enable_bwm $HATHPHP | grep checked)
	f_disable_logging=$(grep f_disable_logging $HATHPHP | grep checked)
	f_use_less_memory=$(grep f_use_less_memory $HATHPHP | grep checked)
	f_is_hathdler=$(grep f_is_hathdler $HATHPHP | grep checked)
done

# 检测是否需要更改端口
[ "$(grep f_port $HATHPHP | awk -F '"' '{print$6}')" = $WANPORT ] && \
echo 外部端口 $WANPORT/tcp 未发生变化 && SKIP=1

# 定义与 RPC 服务器交互的函数
# 访问 http://rpc.hentaiathome.net/15/rpc?clientbuild=169&act=server_stat 查询当前支持的 client_build
ACTION() {
	ACT=$1
	ACTTIME=$(date +%s)
	ACTKEY=$(echo -n "hentai@home-$ACT--$HATHCID-$ACTTIME-$HATHKEY" | sha1sum | cut -c -40)
	curl -Ls 'http://rpc.hentaiathome.net/15/rpc?clientbuild=169&act='$ACT'&add=&cid='$HATHCID'&acttime='$ACTTIME'&actkey='$ACTKEY''
}

# 发送 client_suspend 后，更新端口信息
# 更新后，发送 client_settings 验证端口
[ $SKIP ] || ACTION client_suspend >/dev/null
while [ ! $SKIP ]; do
	let SET++
 	[ $SET -gt 3 ] && echo 更新 H@H 客户端设置信息失败，请检查代理 && exit 1
	[ $SET -ne 1 ] && echo 更新 H@H 客户端设置信息失败，15 秒后重试 && sleep 15
	DATA='settings=1&f_port='$WANPORT'&f_cname='$f_cname'&f_throttle_KB='$f_throttle_KB'&f_disklimit_GB='$f_disklimit_GB''
	[ "$p_mthbwcap" = 0 ] || DATA=''$DATA'&p_mthbwcap='$p_mthbwcap''
	[ "$f_diskremaining_MB" = 0 ] || DATA=''$DATA'&f_diskremaining_MB='$f_diskremaining_MB''
	[ $f_enable_bwm ] && DATA=''$DATA'&f_enable_bwm=on'
	[ $f_disable_logging ] && DATA=''$DATA'&f_disable_logging=on'
	[ $f_use_less_memory ] && DATA=''$DATA'&f_use_less_memory=on'
	[ $f_is_hathdler ] && DATA=''$DATA'&f_is_hathdler=on'
	curl $PROXY -Ls -m 15 \
	-b 'ipb_member_id='$EHIPBID'; ipb_pass_hash='$EHIPBPW'' \
	-o $HATHPHP \
	-d ''$DATA'' \
	'https://e-hentai.org/hentaiathome.php?cid='$HATHCID'&act=settings'
	[ $(ACTION client_settings | grep port=$WANPORT) ] && \
	echo 外部端口 $WANPORT/tcp 更新成功 && break
done

# 发送 client_start 后，检测是否需要启动 H@H 客户端
# 若客户端已启动，则自动恢复连接，无需重启
# 若客户端未启动，client_suspend 与 client_start 不会造成实质影响
[ $SKIP ] || ACTION client_start >/dev/null
# ps aux | grep HentaiAtHome | grep -v grep >/dev/null || hath.sh
