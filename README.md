# 介绍

宽松 NAT（锥形 NAT）下，通过 STUN 穿透 TCP 公网端口允许外部访问，自动修改 H@H 客户端的端口信息并启动。

当然，也可以不使用 STUN 穿透，仅作为 H@H 客户端使用。

## 什么情况可以穿透？

请先检测 NAT 类型，可访问以下链接或使用其他工具。

https://mao.fan/mynat

只要不是 **对称型 (Symmetric) NAT**，基本上都可以穿透。

### 全锥形 NAT 与 端口受限锥形 NAT 的区别

全锥形 NAT (Fullcone NAT 或叫 **NAT1**) 与 端口受限锥形 NAT（Port-Restricted Cone 或叫 **NAT3**）的 **映射行为（Mapping behavior）** 是一样的，区别在于防火墙的 **过滤行为（Filtering behavior）**。

*受限锥形 NAT（Restricted Cone 或叫 **NAT2**）较为罕见，不作考虑*

**对于家庭宽带**，防火墙通常配置在用户侧设备，只要需要操作用户网关的防火墙即可。

一般推荐的操作方法，优先级从高至底为 **端口映射（或叫“虚拟服务器”）> UPnP > DMZ**。

这三个方案的目的都是允许特定端口的入站连接并转发到正确的目标设备上，具体根据场景选择。

若目标设备已获得 NAT1，则以上操作可省略，但**仍建议使用网关进行 NAT 以实现更高的性能**。

**对于运营商配置的家庭网关（光猫）**，DMZ 或 UPnP 的配置可能需要超级管理员权限，但**端口映射通常可以通过用户权限进行配置**。

注意，每层网关都要确保端口正确转发。常见的情况是光猫拨号，下面再接一个路由器。这种情况需要光猫与路由器都配置端口转发。

比较推荐的方案是光猫桥接，路由器拨号，次选是光猫配置 DMZ 到路由器。

Windows 执行 `tracert qq.com`，Linux 执行 `traceroute qq.com` 确认 NAT 层数。

**对于蜂窝移动网络**，防火墙通常配置在运营商侧设备，用户无权限操作。因此当检测结果不为 NAT1 时，则无法穿透。

实际上，只有少部分地区的蜂窝移动网络未配置防火墙。

*蜂窝移动网络的 IPv6 入站连接也受运营商侧防火墙限制*

**对于无网关操作权限的**，本方案也提供了 UPnP 及用户程序转发（仅限 NAT1）协助实现最大限度的穿透可能性。

# 准备工作

在进行配置前，需要获取 H@H 客户端或 E-Hentai 账号的鉴权信息

## 获取 H@H 客户端的 ID 与密钥

打开 https://e-hentai.org/hentaiathome.php 点击你申请到的 H@H 客户端详情

记下在顶部显示的 `Client ID` 与 `Client Key`

![图片](https://github.com/user-attachments/assets/ebf88a7b-a639-456c-a95a-d2dabbeb210d)

---

## 获取 E-Hentai 账号 Cookie

**仅在使用 STUN 穿透时需要**

登录 E-Hentai 后，按 `F12` 打开浏览器开发人员工具，抓取网络通信

在 E-Hentai 的任意页面按 `Ctrl + R` 键刷新，点击捕获到的请求并下拉

从 `Cookie` 项目中复制 `ipb_member_id` 与 `ipb_pass_hash`

![图片](https://github.com/user-attachments/assets/fe5a99a3-238f-45e2-afdb-426c83a70e9b)

## 端口映射

本方案内置了 UPnP 及用户程序转发，本操作不是必要，但为了可靠性，仍希望用户自行配置网关

**以下为 OpenWrt 下配置端口映射的示例，其他路由器原理一致**

![图片](https://github.com/user-attachments/assets/6d547218-5a66-4c0f-9786-2eb33aa7b5e1)

* `地址族限制`：`仅 IPv4`

  仅针对 IPv4 进行穿透，并非所有路由器都有此选项

* `协议`：`TCP`

* `外部端口`：`44377`
  
  本方案默认使用 `44377` 作为 NATMap 的绑定端口；如需变更，请查看 [变量](https://github.com/Oniicyan/HatH-STUN-Docker/edit/main/README.md#%E5%8F%98%E9%87%8F)

* `内部 IP 地址`

  H@H 客户端运行设备的 IPv4 地址，可以是路由器自身的地址（在路由器上运行 Docker）
  
* `内部端口`：`44388`

  本方案默认使用 `44388` 作为 H@H 客户端的本地监听端口；如需变更，请查看 [变量](https://github.com/Oniicyan/HatH-STUN-Docker/edit/main/README.md#%E5%8F%98%E9%87%8F)

---

**以下仅限 OpenWrt，其他路由器请忽略**

`目标区域` 与 `内部 IP 地址` 留空则代表路由器自身

![图片](https://github.com/user-attachments/assets/f7c3074c-3f00-4255-9604-839e267301b2)

保存后如下

![图片](https://github.com/user-attachments/assets/7a0582fc-4e5d-4ff8-bbd5-4c6a0548c1ab)

## 测试代理

**代理仅在启用 STUN 穿透时必要**

Windows 或 Linux 终端下执行 `curl` 确认能否直接访问 `https://e-hentai.org`

`curl -m 5 https://e-hentai.org/hentaiathome.php`

该命令不会有任何反馈，无任何报错则表示成功

若提示超时，则表示需要使用代理

**注意，即使测试成功，也不代表透明代理涵括 Docker 运行设备**

**同时，确保透明代理不会转发 [RPC 服务器 IP](https://oniicyan.pages.dev/rpc_server_ip.txt)（后述），否则将提识别理服务器 IP 作为 H@H 客户端**

测试以下命令，注意代理的协议、地址与端口

`curl -x socks5://127.0.0.1:10808 -m 5 https://e-hentai.org/hentaiathome.php`

部分代理客户端需要手动添加 `e-hentai.org` 到代理规则

若提示 `curl: (35) schannel: failed to receive handshake, SSL/TLS connection failed`，可尝试使用 **HTTP 代理**

`curl -x http://127.0.0.1:7899 -m 5 https://e-hentai.org/hentaiathome.php`

### 关于图库代理

除了 STUN 模式下获取与更新端口信息需要使用代理外，也可为 H@H 客户端下载图库时配置代理

H@H 客户端默认直连下载图库，但在部分地区容易出现缺图或等待时间长的现象，建议配置代理

H@H 客户端配置代理有 3 种途径

1. **客户端代理**：使用 H@H 客户端内置的代理支持，首选

3. **JVM 代理**：使用 Java 虚拟机内置的代理支持

5. **全局透明代理**：用户网关或宿主设备上配置了拦截流量的全局代理

H@H 客户端在运行时，会与 RPC 服务器通信，服务器会检测连接时的 IP 作为 H@H 客户端地址

**若与 RPC 服务器通信时使用了代理，则会识别为代理服务器的 IP，导致 H@H 无法正常分发**

在使用 **客户端代理** 时，会自动绕过 RPC 服务器

在使用 **JVM 代理** 与 **全局透明代理** 时，请注意绕过 **[RPC 服务器 IP](https://oniicyan.pages.dev/rpc_server_ip.txt)**，IP 列表会在首次启动后保存至 `/hath/rpc_server_ip.txt`

# 配置 Docker

## 拉取镜像

`docker pull oniicyan99/hentaiathome:latest`

## 网络配置

建议使用 Host 模式，特别是启用 UPnP 时

Bridge 模式下，**可能会影响 NAT 类型**，以及进行额外的 NAT，尽管绝大部分情况下对性能的损耗可以忽略

## 目录配置

大多数情况下，只需要创建新目录或把原有 H@H 目录挂载至 `/hath`

`-v /工作目录:/hath`

H@H 客户端会自动创建或使用该目录下的 `cache` `data` `download` `log` `temp` 子目录

---

如要指定自定义目录，请额外挂载以下目标路径

```
-v /缓存目录:/hath_cache
-v /数据目录:/hath_data
-v /下载目录:/hath_download
-v /日志目录:/hath_log
-v /临时目录:/hath_temp
```

## 执行示例

以下是最常用的示例：Host 网络、启用图库代理、启用 STUN 穿透、启用 UPnP

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

若已配置 **端口映射**，则可删除 `Upnp` 行

若已配置 **全局代理**，则可删除 `HathProxyType` `HathProxyHost` `HathProxyPort` `StunProxy` 行

## 变量说明

本 Docker 为确保灵活性，支持大量自定义变量，可根据使用场景进行定制

## H@H 客户端

| 名称 | 必需 | 说明 | 默认 |
| --- | --- | --- | --- |
| HathClientId | 否 | H@H 客户端 ID | 读取 `./data/client_login` |
| HathClientKey | 否 | H@H 客户端密钥 | 读取 `./data/client_login` |
| HathProxyHost | 否 | 客户端代理地址 | 不启用 |
| HathProxyType | 否 | 客户端代理类型，可用值 `socks` 或 `http`  | `socks` |
| HathProxyPort | 否 | 客户端代理端口 | `socks` 为 `1080` <br> `http` 为 `8080` |
| HathCache | 否 | 缓存目录 | `./cache` |
| HathData | 否 | 数据目录 | `./data` |
| HathDownload | 否 | 下载目录 | `./download` |
| HathLog | 否 | 日志目录 | `./log` |
| HathTemp | 否 | 临时目录 | `./tmp` |
| HathPort | 否 | 监听端口 | 从 RPC 服务器获取端口<br>STUN 模式下重写为 `StunHathPort` |
| HathRpc | 否 | [RPC 服务器 IP](https://oniicyan.pages.dev/rpc_server_ip.txt)，一般用作代理规则 | 自动获取 |
| HathSkipIpCheck | 否 | 跳过请求地址检测<br>用户程序转发时，请求地址会变成 `127.0.0.1` 或 `192.168.1.1`等<br>需要跳过检测 | 不启用<br>使用 `STUN 转发模式` 时自动启用 |
| HathArgs | 否 | 其他参数，请查阅 [EHWiki](https://ehwiki.org/wiki/Hentai@Home#Software)<br>为避免 `-` 号被解释，建议内容用单引号包围 | 无 |
