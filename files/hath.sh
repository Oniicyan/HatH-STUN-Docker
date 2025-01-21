#!/bin/bash

cd /hath

# 端口参数
[ $HathPort ] && HathPort='--port='$HathPort''

# 目录参数
[ $HathCache ] && HathDirs=''$HathDirs' --cache-dir='$HathCache''
[ $HathData ] && HathDirs=''$HathDirs' --data-dir='$HathData''
[ $HathDownload ] && HathDirs=''$HathDirs' --download-dir='$HathDownload''
[ $HathLog ] && HathDirs=''$HathDirs' --log-dir='$HathLog''
[ $HathTemp ] && HathDirs=''$HathDirs' --temp-dir='$HathTemp''

# 代理参数
[ $HathProxyHost ] && HathProxy=''$HathProxy' --image-proxy-host='$HathProxyHost''
[ $HathProxyType ] && HathProxy=''$HathProxy' --image-proxy-type='$HathProxyType''
[ $HathProxyPort ] && HathProxy=''$HathProxy' --image-proxy-port='$HathProxyPort''

# 其他参数
[ $HathRpc ] && HathArgs=''$HathArgs' --rpc-server-ip='$HathRpc''
[ $HathSkipIpCheck ] && HathArgs=''$HathArgs' --disable-ip-origin-check'

# JVM 参数
[ $JvmHttpHost ] && JvmArgs=''$JvmArgs' -Dhttp.proxyHost='$JvmHttpHost''
[ $JvmHttpPort ] && JvmArgs=''$JvmArgs' -Dhttp.proxyPort='$JvmHttpPort''
[ $JvmHttpUser ] && JvmArgs=''$JvmArgs' -Dhttp.proxyUser='$JvmHttpUser''
[ $JvmHttpPass ] && JvmArgs=''$JvmArgs' -Dhttp.proxyPassword='$JvmHttpPass''
[ $JvmHttpsHost ] && JvmArgs=''$JvmArgs' -Dhttps.proxyHost='$JvmHttpsHost''
[ $JvmHttpsPort ] && JvmArgs=''$JvmArgs' -Dhttps.proxyPort='$JvmHttpsPort''
[ $JvmHttpsUser ] && JvmArgs=''$JvmArgs' -Dhttps.proxyUser='$JvmHttpsUser''
[ $JvmHttpsPass ] && JvmArgs=''$JvmArgs' -Dhttps.proxyPassword='$JvmHttpsPass''
[ $JvmSocksHost ] && JvmArgs=''$JvmArgs' -DsocksProxyHost='$JvmSocksHost''
[ $JvmSocksPort ] && JvmArgs=''$JvmArgs' -DsocksProxyPort='$JvmSocksPort''
[ $JvmSocksUser ] && JvmArgs=''$JvmArgs' -DsocksProxyUser='$JvmSocksUser''
[ $JvmSocksPass ] && JvmArgs=''$JvmArgs' -DsocksProxyPassword='$JvmSocksPass''

# 获取 RPC 服务器 IP
ActTime=$(date +%s)
ActKey=$(echo -n "hentai@home-client_settings--$HathClientId-$ActTime-$HathClientKey" | sha1sum | cut -c -40)
RpcServerIp=$(curl -Ls 'http://rpc.hentaiathome.net/15/rpc?clientbuild='$BUILD'&act=client_settings&add=&cid='$HathClientId'&acttime='$ActTime'&actkey='$ActKey'' | grep rpc_server_ip)
if [ $RpcServerIp ]; then
	echo $RpcServerIp | grep -oE '([0-9]*\.?){4}' >/hath/rpc_server_ip.txt
	echo 获取 RPC 服务器 IP 成功，保存至 rpc_server_ip.txt
else
	echo 获取 RPC 服务器 IP 失败，请留意客户端能否正常启动
fi

# 启动 H@H 客户端
HathStart='java '$JvmArgs' -jar /files/HentaiAtHome.jar '$HathPort' '$HathDirs' '$HathProxy' '$HathArgs''
echo 本次 H@H 客户端执行命令
echo $HathStart
exec $HathStart
