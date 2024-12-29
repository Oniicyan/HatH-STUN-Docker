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

**对于运营商配置的家庭网关**，DMZ 或 UPnP 的配置可能需要超级管理员权限，但**端口映射通常可以通过用户权限进行配置**。

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

本方案内置了 UPnP 及用户程序转发，本操作不是必要，但为了可靠性，仍希望用户自行配置网关。

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

# 配置 Docker

## 拉取镜像

`docker pull oniicyan99/hentaiathome:latest`

## 网络配置

建议使用 Host 模式，特别是启用 UPnP 时。

Bridge 模式下，**可能会影响 NAT 类型**，以及进行额外的 NAT，尽管绝大部分情况下对性能的损耗可以忽略。

## 目录配置

大多数情况下，只需要创建新目录或把原有 H@H 目录挂载至 `/hath`，H@H 客户端会自动创建或使用该目录下的 `cache` `data` `download` `log` `temp` 子目录。

`-v /工作目录:/hath`

如要指定自定义目录，请额外挂载以下目标路径

```
-v /缓存目录:/hath_cache
-v /数据目录:/hath_data
-v /下载目录:/hath_download
-v /日志目录:/hath_log
-v /临时目录:/hath_temp
```

## 执行示例

以下是最常用的示例：Host 网络、启用 STUN 穿透、启用 UPnP

请替换工作目录以及鉴权信息

```
sudo docker run -d \
--name hath \
--net host \
-v /工作目录:/hath \
-e HathClientId='H@H 客户端 ID' \
-e HathClientKey='H@H 客户端 密钥' \
-e Stun=1 \
-e StunIpbId='ipb_member_id' \
-e StunIpbPass='ipb_pass_hash' \
-e Upnp=1 \
oniicyan99/hentaiathome
```

若已配置端口映射，则可删除 `-e Upnp=1`

## 变量说明
