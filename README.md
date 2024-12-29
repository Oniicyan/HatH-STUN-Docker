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

一般推荐的操作方法，优先级从高到底为 **端口映射（或叫“虚拟服务器”） > UPnP > DMZ**。

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

## 获取账号 Cookie

**仅在使用 STUN 穿透时需要**

登录 E-Hentai 后，按 `F12` 打开浏览器开发人员工具，抓取网络通信

在 E-Hentai 的任意页面按 `Ctrl + R` 键刷新，点击捕获到的请求并下拉

从 `Cookie` 项目中复制 `ipb_member_id` 与 `ipb_pass_hash`

![图片](https://github.com/user-attachments/assets/fe5a99a3-238f-45e2-afdb-426c83a70e9b)
