---
title: 使用HTTPS
updated_at: 2025-03-16T15:40:30.726+08:00
date: 2025-03-14T22:14:00
abbrlink: usehttps
---

# 前言

如果正常的话，我当前的域名应该是：https://hexo.zhywyt.me，为了庆祝我找到了免费的https方案，特地来写下这篇文章。

话不多说展示军火：

```
- frp
- nginx
- acme.sh
- ZeroSSL/Let's Encrypt
```

具体思路是，使用`nginx`做本地的两个服务，一个是`81`端口的[http转https服务](https://www.cnblogs.com/larrydpk/p/12819231.html)，一个是正常的`80`端口http服务。再使用`acme.sh`在`ZeroSSL`或者`Let's Encrypt`上[自动申请证书](https://github.com/acmesh-official/acme.sh/wiki/%E8%AF%B4%E6%98%8E)，然后使用`frp`[为本地 HTTP 服务启用 HTTPS \| frp](https://gofrp.org/zh-cn/docs/examples/https2http/)，

然而你也可以不使用`frp`做`https`服务，那么你需要使用`nginx`进行认证，你可以参考：[免费永久HTTPS(ssl)证书——Let's Encrypt来了 - 大司徒 - 博客园](https://www.cnblogs.com/chuanghongmeng/p/18466820)。

让我们开始HTTP<font color='red'>S</font>。

# frps

你需要启用`frps`的`https`穿透，具体配置文件为：
```toml
bindPort = 7000
vhostHTTPPort = 80
vhostHTTPSPort = 443
webServer.addr = "0.0.0.0"
webServer.port = 7500
webServer.user = "****"
webServer.password = "****"
enablePrometheus = true
auth.token = "****"
```

重要的是你的`vhostHTTPSPort`字段，其他的请不要修改。修改完配置后重启`frps`，并打开你服务器的`443`端口。

# nginx

为什么使用`nginx`？~~因为我只会用这个~~，并且它的配置文件很有意思，且好玩。

## 使用frp

如果你使用了`frp`，那么你就不需要在`nginx`中设置`443`端口的`https`服务，只需要开放本机上的`http`服务即可。请修改下面的`<yourservername>`为你想要的名字。
```bash
cp /etc/nginx/sites-available/default /etc/nginx/sites-available/<yourservername>
ln -s /etc/nginx/sites-available/<yourservername> /etc/nginx/sites-enabled/<yourservername>
```
并将下面的配置文件写入你创建的文件中。请修改下面的`<your server path>`为你的网站路径，修改下面的`<your domain>`为你的域名。
```nginx
server{
        listen 81;
        rewrite ^(.*)$ https://$host$1 permanent;
}
server {
        listen 80;
        root <your server path> ;
        index index.html;
        server_name <your domain> ;
}
```

然后重启`nginx`。
```bash
sudo systemctl restart nginx
```

# acme.sh
我使用了[acme.sh](https://github.com/acmesh-official/acme.sh)项目来实现证书的申请和自动更新！🥰
这是令人兴奋的，但是我有义务让你知道免费SSL证书的来源！我是从这篇知乎文章得知了这一渠道：[为什么 SSL 证书要花钱购买，而不是政府免费发放的？怎么知道卖证书的是否可信呢？](https://www.zhihu.com/question/22869797)

接下来，让我们开始吧！

```bash
# 安装依赖
sudo apt update && sudo apt install unzip socat
```
然后你需要准备一个邮箱，并尝试运行下面的命令来下载acme.sh：
```bash
curl https://get.acme.sh | sh -s email=my@example.com
source ~/.bashrc
```

## 使用frp
接下来你需要准备：
- 申请证书的域名
- 服务的根目录
并填入下面的命令，尝试执行它。
```bash
acme.sh --issue -d mydomain.com -d www.mydomain.com --webroot /home/wwwroot/mydomain.com/
```
然后你需要选择两个路径位置，用于存档`cert`和`key`，你可以直接使用下面命令中的路径，否则你应该记住自己使用的路径，你应该修改下面的域名为你自己设置的域名
```bash
mkdir /etc/nginx/ssl
acme.sh --install-cert -d example.com \
--key-file       /etc/nginx/ssl/key.pem  \
--fullchain-file /etc/nginx/ssl/cert.pem \
--reloadcmd     "service nginx reload"
```



## 后续

到这里你可以使用下面的命令来查看是否成功安装证书了！
```bash
acme.sh --info -d example.com
```

并且你可以查看自己的定时任务：
```bash
crontab -e
```

# 上线网站

对于不使用`frp`的用户，其实重启`nginx`就可以正常工作了，但是对于`frp`用户，还需要进行一些`frpc`的配置。

打开你的`frpc.toml`，输入下面的配置：
你可以参考：[为本地 HTTP 服务启用 HTTPS \| frp](https://gofrp.org/zh-cn/docs/examples/https2http/)
```toml
serverAddr = "x.x.x.x"
serverPort = 7000

[[proxies]]
name = "test_htts2http"
type = "https"
customDomains = ["domain"]

[proxies.plugin]
type = "https2http"
localAddr = "127.0.0.1:80"

# HTTPS 证书相关的配置
crtPath = "./server.crt"
keyPath = "./server.key"
hostHeaderRewrite = "127.0.0.1"
requestHeaders.set.x-from-where = "frp"

```

并额外添加一个`http`的服务：
```toml
[[proxies]]
name = "httpname"
type = "http"
localIP = "localhost"
localPort = 81
customDomains = ["domain"]
```

最后重启`frpc`！大功告成！👋🛠️

如果有任何问题，欢迎向我提问！