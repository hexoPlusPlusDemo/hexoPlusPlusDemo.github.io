---
title: gitea搭建
tags:
  - 技术文档
abbrlink: 1c09aa798545
categories:
  - Linux
---

记录一次使用`postgrepsql`搭建`gitea`的过程。
首先我们在机器上安装`postgrepsql`和必须的工具。
```bash
apt install postgresql curl
```
然后根据[gitea文档](https://docs.gitea.com/zh-cn/installation/database-prep)修改数据库的配置文件。
```bash
# 注意一下这里的版本是你自己的版本。
vim /etc/postgresql/14/main/postgresql.conf
```
修改好之后重启
```bash
sudo /etc/init.d/postgresql restart
```
然后测试连接，注意密码是`gitea`
```bash
psql -U gitea -d giteadb
psql "postgres://gitea@<ip>/giteadb"
```
这边建议使用docker-comppose安装，首先去官网安装[docker-compose](https://docs.docker.com/compose/install/standalone/)。
```bash
curl -SL https://github.com/docker/compose/releases/download/v2.29.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
sudo apt install docker.io
docker-compose up -d

```
