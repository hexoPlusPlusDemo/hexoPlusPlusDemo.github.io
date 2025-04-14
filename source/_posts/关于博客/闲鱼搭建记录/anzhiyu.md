---
title: anzhiyu主题搭建记录
categories:
  - 闲鱼兼职
  - 网站搭建
abbrlink: 64880
updated_at: 2025-03-16 07:37:56
date: 2025-03-16 15:36:00
---


# 来自闲🐟老板芬达的订单

要求使用 github page 搭建安知鱼主题： [主题简介 \| 安知鱼主题官方文档](https://docs.anheyu.com/intro.html)

先安装nodejs
[Node.js — 在任何地方运行 JavaScript](https://nodejs.org/zh-cn)
```bash
# 安装hexo
npm install -g hexo-cli
mkdir dir
cd dir
hexo init
npm install hexo-deployer-git --save
git clone -b main https://github.com/anzhiyu-c/hexo-theme-anzhiyu.git themes/anzhiyu

npm install hexo-renderer-pug hexo-renderer-stylus --save
cp -rf ./themes/anzhiyu/_config.yml ./_config.anzhiyu.yml

```

修改配置文件主题到`anzhiyu`

创建github仓库，打开仓库page，创建机器ssh key。

修改配置文件，设置deploy:
```bash
deploy:  
  type: git  
  repo: <repository url> # https://bitbucket.org/JohnSmith/johnsmith.bitbucket.io  
  branch: [branch]  
```

推送`hexo d`

效果预览：[Hexo](https://fenda2.github.io/)
老板反馈：
![](../../../assets/images/QQ_1742110666829.png)