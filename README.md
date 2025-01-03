# 介绍

宽松 NAT（锥形 NAT）下，通过 STUN 穿透 TCP 公网端口允许外部访问，自动修改 H@H 客户端的端口信息并启动。

当然，也可以不使用 STUN 穿透，仅作为 H@H 客户端使用。

## 什么情况可以穿透？

请先检测 NAT 类型，可访问以下链接或使用其他工具。

https://mao.fan/mynat

只要不是 **对称型 (Symmetric) NAT**，基本上都可以穿透。

---

### 全锥形 NAT 与 端口受限锥形 NAT 的区别

　*本节内容包括但不限于 H@H 客户端穿透场景*

全锥形 NAT (Fullcone NAT 或叫 **NAT1**) 与 端口受限锥形 NAT（Port-Restricted Cone 或叫 **NAT3**）的 **映射行为 (Mapping behavior)** 是一样的，区别在于防火墙的 **过滤行为 (Filtering behavior)**。

　*受限锥形 NAT（Restricted Cone 或叫 **NAT2**）较为罕见，不作考虑*

 ---

**对于家庭宽带**，防火墙通常配置在用户侧设备，只需要操作用户网关的防火墙即可。

一般推荐的操作方法，优先级从高至底为 **端口映射 > UPnP > DMZ**。

这三个方案的目的都是允许特定端口的入站连接并映射到正确的目标设备上，具体根据场景选择。

　*由于 DMZ 仅映射内外一致的端口，不适用于本场景*

若目标设备已获得 NAT1，则以上操作可省略，但**仍建议使用网关进行 NAT 以实现更高的性能**。

**运营商配置的家庭网关（光猫）** 配置 DMZ 或 UPnP 可能需要超级管理员权限，但**端口映射通常可以通过用户权限进行配置**。

注意，每层网关都要确保端口正确映射。常见的情况是光猫拨号，下面再接一个路由器。这种情况需要光猫与路由器都配置端口映射。

比较推荐的方案是光猫桥接，路由器拨号，次选是光猫配置 DMZ 到路由器。在无法无操作权限配置 DMZ 时，需要为每个服务在光猫上配置单独的端口映射规则，再由路由器映射到目标设备。

Windows 执行 `tracert qq.com`，Linux 执行 `traceroute qq.com` 确认 NAT 层数。

---

**对于学校或单位等公用宽带**，用户很可能无网关的操作权限。

为此，本镜像提供了 UPnP 及 [用户程序转发](https://github.com/Oniicyan/HatH-STUN-Docker#stun)（仅限 NAT1）以协助实现最大限度的穿透可能性。

---

**对于蜂窝移动网络**，防火墙通常配置在运营商侧设备，用户无操作权限，且通常不配置 UPnP IGD / NAT-PMP / PCP 等可供用户请求的接口。

因此，当蜂窝移动网络下 NAT 类型检测结果不为全锥形时，将无法穿透。

实际上，只有少部分地区的蜂窝移动网络未配置防火墙。

　*蜂窝移动网络的 IPv6 入站连接也受运营商侧防火墙限制*

---

### NAT 的优先级

即使同时配置了多种 NAT 手段，由于它们之间有优先级，因此也不会造成冲突。当然，前提是网关有正确地处理。

**连接跟踪 > 端口映射规则 > UPnP 规则 > DMZ > 用户程序转发**

　*用户程序转发 严格来说不是 NAT*

 **连接跟踪** 由操作系统最优先处理；这就是为什么即使 STUN 工具绑定的端口与后续的映射规则一致，也不会被触发映射到其他程序上。

 同理，当连接匹配了 **端口映射规则** 后，即使 **UPnP 规则** 中有一致的项目也不会被触发，**DMZ** 也会被跳过。

 反过来说，当前面所有 NAT 手段都没有被触发，才轮到 **用户程序转发**。

 ---

# 准备工作

在进行配置前，需要获取 H@H 客户端 或 E-Hentai 账号 的鉴权信息

## 获取 H@H 客户端 ID 与密钥

打开 https://e-hentai.org/hentaiathome.php 点击你申请到的 H@H 客户端详情

记下在顶部显示的 `Client ID` 与 `Client Key`

![图片](https://github.com/user-attachments/assets/ebf88a7b-a639-456c-a95a-d2dabbeb210d)

---

## 获取 E-Hentai 账号 Cookie

**仅在启用 STUN 时需要**

登录 E-Hentai 后，按 `F12` 打开浏览器开发人员工具，抓取网络通信

在 E-Hentai 的任意页面按 `Ctrl + R` 键刷新，点击捕获到的请求并下拉

从 `Cookie` 项目中复制 `ipb_member_id` 与 `ipb_pass_hash`

![图片](https://github.com/user-attachments/assets/fe5a99a3-238f-45e2-afdb-426c83a70e9b)

## 端口映射

本镜像内置了 UPnP 及 [用户程序转发](https://github.com/Oniicyan/HatH-STUN-Docker#stun)，此操作不是必要，但为了可靠性，仍希望用户自行配置网关

**以下为 OpenWrt 下，针对 Host 网络配置端口映射的示例，其他路由器原理一致**

![图片](https://github.com/user-attachments/assets/6d547218-5a66-4c0f-9786-2eb33aa7b5e1)

* `地址族限制`：`仅 IPv4`

  仅针对 IPv4 进行穿透，并非所有路由器都有此选项

* `协议`：`TCP`

* `外部端口`：`44377`
  
  本镜像默认使用 `44377` 作为 NATMap 的绑定端口；如需变更，请查看 [STUN 变量](https://github.com/Oniicyan/HatH-STUN-Docker#stun)

* `内部 IP 地址`

  H@H 客户端运行设备的 IPv4 地址，可以是路由器自身的地址（在路由器上运行 Docker）

  **使用 Bridge 网络时，应填写宿主的本地 IP 地址**
  
* `内部端口`：`44388`

  本镜像默认使用 `44388` 作为 H@H 客户端的本地监听端口；如需变更，请查看 [STUN 变量](https://github.com/Oniicyan/HatH-STUN-Docker#stun)

  **使用 Bridge 网络时，应与外部端口一致 (`44377`)**

---

**以下仅限 OpenWrt，其他路由器请忽略**

`目标区域` 与 `内部 IP 地址` 留空则代表路由器自身

![图片](https://github.com/user-attachments/assets/f7c3074c-3f00-4255-9604-839e267301b2)

保存后如下

![图片](https://github.com/user-attachments/assets/7a0582fc-4e5d-4ff8-bbd5-4c6a0548c1ab)

---

## 关于代理

有 3 种场景需要使用代理

1. **STUN**

   部分地区无法直连获取与更新 H@H 客户端设置信息（[测试代理](https://github.com/Oniicyan/HatH-STUN-Docker#测试代理)）

2. **下载画廊**

   部分地区使用 H@H 客户端直连下载画廊 (Gallery) 时的体验较差，有可能缺图或等待时间长

   若请求下载后 168 小时尚未完成，下载将被取消，用户需要从浏览器历史记录等途径追溯下载候选

3. **策略分流**

   有多个互联网接口（如多线接入）时，可利用代理来实现策略分流

---

本镜像考虑以下 3 种代理手段

1. **客户端代理**

   使用 [H@H 客户端内置的代理支持](https://github.com/Oniicyan/HatH-STUN-Docker#hh)，适用于 **下载画廊**

   无需对代理配置额外的规则，但目前 H@H 客户端的代理支持仍处于 [实验性阶段](https://forums.e-hentai.org/index.php?showtopic=234458)，可能无法正确使用

3. **JVM 代理**

   使用 [Java 虚拟机内置的代理支持](https://github.com/Oniicyan/HatH-STUN-Docker#jvm)，适用于 **下载画廊** 与 **策略分流**

   作为下载画廊的手段时，需要绕过 RPC 服务器 IP

   作为策略分流的手段时，需要指定互联网接口

5. **全局代理**

   用户网关或宿主设备上配置 **拦截流量** 的全局代理（非 全局路由）

   **可适用所有场景**，但依赖额外的硬件或软件，并且需要为每种场景配置相应的规则

---

启用 STUN 时，若未配置全局代理，则需要通过 `curl` 命令的 `-x` 参数指定代理`

容器需要配置对应的 [STUN 变量](https://github.com/Oniicyan/HatH-STUN-Docker#stun)

STUN 需要代理的域名为 `e-hentai.org`

---

H@H 客户端在运行时，会与 RPC 服务器通信，服务器检测连接时请求的 IP 作为 H@H 客户端地址

**若与 RPC 服务器通信时使用了代理，则会识别代理服务器的 IP 作为 H@H 客户端地址，导致无法正常提供文件**

在使用 **客户端代理** 时，程序会自动绕过 RPC 服务器通信

在使用 **JVM 代理** 与 **全局代理** 时，需自行配置绕过 **[RPC 服务器 IP](https://oniicyan.pages.dev/rpc_server_ip.txt)** 的规则

　*RPC 服务器 IP 列表会在启动后保存至 `/hath/rpc_server_ip.txt`*

---

策略分流可基于 **源 IP 地址** 或 **目的 IP 地址**

**基于 源 IP 地址 进行策略分流时**，由于 JVM 无法直接通过附加参数指定绑定接口 或 IP，需要利用 JVM 代理

　*未确认，如有对应的附加参数或其他方案，请告知*

**基于 目的 IP 地址 进行策略分流时**，可使用路由表而不是代理来实现，能达到更好的效果

　*RPC 服务器 IP 有多个，可以此区分 目的 IP 地址*

策略分流通常需要同时修改 [H@H 客户端监听端口](https://github.com/Oniicyan/HatH-STUN-Docker#hh) 与 [NATMap 绑定接口](https://github.com/Oniicyan/HatH-STUN-Docker#stun)

只要配置正确，本镜像支持在同一设备下运行多个容器，分别使用不同的互联网接口

---

只要理清楚相互关系，不同场景的代理可以共存

比如用 **JVM 代理** 指定 源 IP 地址，用 **全局代理** 作为 STUN 获取与更新 H@H 客户端设置信息的手段，同时用 **客户端代理** 下载画廊

---

### 测试代理

Windows 或 Linux 终端下执行 `curl` 确认能否直接访问 `https://e-hentai.org`

`curl -m 5 https://e-hentai.org/hentaiathome.php`

该命令不会有任何反馈，无任何报错则表示成功

若提示超时，则表示需要单独配置代理

**注意，即使测试成功，也不代表全局代理涵括 Docker 容器运行设备**

**同时，确保全局代理不会转发 [RPC 服务器 IP](https://oniicyan.pages.dev/rpc_server_ip.txt)，否则将识别代理服务器 IP 作为 H@H 客户端地址**

测试以下命令；**注意代理的协议、地址与端口，这就是配置代理时需要的信息**

`curl -x socks5://127.0.0.1:10808 -m 5 https://e-hentai.org/hentaiathome.php`

部分代理客户端需要添加 `e-hentai.org` 到代理规则

若提示 `curl: (35) schannel: failed to receive handshake, SSL/TLS connection failed`，可尝试使用 **HTTP 代理**

`curl -x http://127.0.0.1:7899 -m 5 https://e-hentai.org/hentaiathome.php`

---

# 配置容器

## 拉取镜像

`docker pull oniicyan99/hentaiathome:latest`

## 网络配置

建议使用 Host 网络，特别是启用 UPnP 时

Bridge 网络下，**可能会影响 NAT 类型**，并需要进行额外的 NAT，尽管绝大部分情况下对性能的损耗可以忽略

Bridge 网络下，[端口映射规则](https://github.com/Oniicyan/HatH-STUN-Docker#端口映射) 与 Host 网络不同

## 目录配置

如无特别需求，只需要创建新目录或把原有 H@H 目录作为工作目录挂载至 `/hath`

`-v /工作目录:/hath`

H@H 客户端会自动创建或使用该目录下的 `cache` `data` `download` `log` `temp` 子目录

---

如需指定自定义目录，请额外挂载以下目标路径

```
-v /缓存目录:/hath_cache
-v /数据目录:/hath_data
-v /下载目录:/hath_download
-v /日志目录:/hath_log
-v /临时目录:/hath_temp
```

## 执行示例

以下是最常用的示例：Host 网络、启用客户端代理、启用 STUN 穿透、启用 UPnP

请替换 **工作目录**、**代理信息** 以及 **鉴权信息**

```
sudo docker run -d \
--name hath \
--net host \
-v /工作目录:/hath \
-e HathClientId='H@H 客户端 ID' \
-e HathClientKey='H@H 客户端 密钥' \
-e HathProxyType='socks' \
-e HathProxyHost='127.0.0.1' \
-e HathProxyPort='10808' \
-e Stun=1 \
-e StunProxy='socks5://127.0.0.1:10808' \
-e StunIpbId='ipb_member_id' \
-e StunIpbPass='ipb_pass_hash' \
-e Upnp=1 \
oniicyan99/hentaiathome
```

若已配置 **[端口映射](https://github.com/Oniicyan/HatH-STUN-Docker#端口映射)**，则可删除 `Upnp` 行

若已配置 **[全局代理](https://github.com/Oniicyan/HatH-STUN-Docker#测试代理)**，则可删除 `HathProxyType` `HathProxyHost` `HathProxyPort` `StunProxy` 行

---

Bridge 网络、启用 JVM 代理 (SOCKS)、启用 STUN 穿透

**请确认已配置 [端口映射](https://github.com/Oniicyan/HatH-STUN-Docker#端口映射)**

**请确认已配置 [绕过 RPC 服务器 IP](https://github.com/Oniicyan/HatH-STUN-Docker#关于代理)**

```
sudo docker run -d \
--name hath \
-p 44377:44388 \
-v /工作目录:/hath \
-e HathClientId='H@H 客户端 ID' \
-e HathClientKey='H@H 客户端 密钥' \
-e JvmSocksHost='127.0.0.1' \
-e JvmSocksPort='10808' \
-e Stun=1 \
-e StunProxy='socks5://127.0.0.1:10808' \
-e StunIpbId='ipb_member_id' \
-e StunIpbPass='ipb_pass_hash' \
oniicyan99/hentaiathome
```

---

若端口更新过程中出错，但 H@H 客户端仍未离线，可执行以下命令刷新状态

`docker exec hath refresh.sh`

**若 H@H 客户端已离线，请重启容器**

# 变量说明

本镜像支持自定义变量，可根据使用场景进行定制

**不启用的变量请留空**；指定任何字符串，即使是 `0` 或 `off`，仍会启用该变量

## H@H

| 名称 | 说明 | 默认 |
| --- | --- | --- |
| HathClientId | H@H 客户端 ID | 读取 `./data/client_login` |
| HathClientKey | H@H 客户端密钥 | 读取 `./data/client_login` |
| HathProxyHost | H@H 客户端代理地址 | 不启用 |
| HathProxyType | H@H 客户端代理类型，可用值为 `socks` 或 `http`  | `socks` |
| HathProxyPort | H@H 客户端代理端口 | `socks` 为 `1080` <br> `http` 为 `8080` |
| HathPort | H@H 客户端监听端口<br>通常在策略分流时指定 | 从 RPC 服务器获取<br>[STUN](https://github.com/Oniicyan/HatH-STUN-Docker#stun) 模式下重写为 `StunHathPort` |
| HathCache | 缓存目录 | `./cache` |
| HathData | 数据目录 | `./data` |
| HathDownload | 下载目录 | `./download` |
| HathLog | 日志目录 | `./log` |
| HathTemp | 临时目录 | `./tmp` |
| HathRpc | [RPC 服务器 IP](https://oniicyan.pages.dev/rpc_server_ip.txt)<br>通常在策略分流时指定 | 自动获取 |
| HathSkipIpCheck | 跳过请求地址检测<br>[用户程序转发](https://github.com/Oniicyan/HatH-STUN-Docker#stun) 时，远程请求的地址会变成本地地址，需要跳过检测 | 不启用<br>`STUN 转发模式` 下自动启用 |
| HathArgs | [H@H 客户端其他参数](https://ehwiki.org/wiki/Hentai@Home#Software)，为避免 `-` 号被解释，建议内容用单引号包围 | 无 |

## STUN

| 名称 | 说明 | 默认 |
| --- | --- | --- |
| Stun | STUN 开关 | 不启用 |
| StunServer | STUN 服务器；[域名列表](https://oniicyan.pages.dev/stun_servers_domain.txt)、[IP 列表](https://oniicyan.pages.dev/stun_servers_ipv4.txt) | `turn.cloudflare.com` |
| StunHttpServer | 穿透通道保活用的 HTTP 服务器 | `qq.com` |
| StunBindPort | NATMap 绑定端口 | `44377` |
| StunHathPort | H@H 客户端监听端口 | `44388` |
| StunInterval | 穿透通道保活间隔（秒） | `25` |
| StunInterface | NATMap 绑定接口或 IP<br>通常在策略分流时指定 | 不启用 |
| StunForward | NATMap 转发开关 | 不启用 |
| StunForwardAddr | NATMap 转发的目的地址（目的端口为 `StunHathPort`）<br>通常在策略分流时指定| `127.0.0.1` |
| StunArgs | [NATMap 其他参数](https://github.com/heiher/natmap#how-to-use)，为避免 `-` 号被解释，建议内容用单引号包围 | 无 |

## UPnP

| 名称 | 说明 | 默认 |
| --- | --- | --- |
| Upnp | UPnP 开关 | 不启用 |
| UpnpAddr | UPnP 规则的目的地址<br>Bridge 网络下请填写宿主的本地 IP 地址 | `@`（自动检测本地地址） |
| UpnpInPort | UPnP 规则的内部端口 | 启用 STUN 时为 `StunHathPort`<br>否则从 RPC 服务器获取 H@H 客户端端口 |
| UpnpExPort | UPnP 规则的外部端口 | 启用 STUN 时为 `StunBindPort`<br>否则从 RPC 服务器获取 H@H 客户端端口 |
| UpnpUrl | UPnP 设备描述文件 (XML) 的 URL<br>用作绕过发现过程，通常在 Bridge 模式下需要 | 无 |
| UpnpArgs | [MiniUPnPc 其他参数](https://manpages.debian.org/unstable/miniupnpc/upnpc.1.en.html)，为避免 `-` 号被解释，建议内容用单引号包围 | 无 |

## JVM

**部分协议可能不支持鉴权，请查阅 [Java Docs](https://docs.oracle.com/javase/8/docs/technotes/guides/net/proxies.html)**

| 名称 | 说明 | 默认 |
| --- | --- | --- |
| JvmHttpHost | Java 虚拟机 HTTP 代理地址 | 无 |
| JvmHttpPort | Java 虚拟机 HTTP 代理端口 | 无 |
| JvmHttpUser | Java 虚拟机 HTTP 代理账号 | 无 |
| JvmHttpPass | Java 虚拟机 HTTP 代理密码 | 无 |
| JvmHttpsHost | Java 虚拟机 HTTPS 代理地址 | 无 |
| JvmHttpsPort | Java 虚拟机 HTTPS 代理端口 | 无 |
| JvmHttpsUser | Java 虚拟机 HTTPS 代理账号 | 无 |
| JvmHttpsPass | Java 虚拟机 HTTPS 代理密码 | 无 |
| JvmSocksHost | Java 虚拟机 SOCKS 代理地址 | 无 |
| JvmSocksPort | Java 虚拟机 SOCKS 代理端口 | 无 |
| JvmSocksUser | Java 虚拟机 SOCKS 代理账号 | 无 |
| JvmSocksPass | Java 虚拟机 SOCKS 代理密码 | 无 |
| JvmArgs | [JVM 其他参数](https://docs.oracle.com/cd/E22289_01/html/821-1274/configuring-the-default-jvm-and-java-arguments.html)，为避免 `-` 号被解释，建议内容用单引号包围 | 无 |
