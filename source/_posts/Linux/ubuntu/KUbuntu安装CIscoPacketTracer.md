---
title: KUbuntu安装CIscoPacketTracer
date: 2024-05-26 15:41
abbrlink: 49793
tags: 
categories:
  - Linux
  - Ubuntu
---

<!--more-->

注意：这是正版教程，需要你有Cisco账号。

## 第一步注册账号

先去思科官网注册账号：[Cisco](https://www.netacad.com/courses/packet-tracer)

可以先尝试这个链接，如果可以的话就跳过第二步，直接看第三步，如果链接失效了请继续第二步。[PackeTracer](https://skillsforall.com/resources/lab-downloads)

## 第二步下载PacketTracer

思科规定下载PacketTracer需要先免费注册任意一门课程，登陆好的页面如下：  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240526152511310-1836730294_1726323545490.png)

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240526152648623-1276232439_1726323545490.png)  
等待跳转或者点击这个Skills for all  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240526152706426-965827330_1726323545490.png)

然后点击链接开始  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240526152754573-915539124_1726323545490.png)

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240526152834258-1382698559_1726323545490.png)

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240526152902945-865654347_1726323567021.png)

进入课程后往下滚动  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240526152954382-1445776826_1726323567021.png)

找到下载链接：  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240526153027729-374319974_1726323567021.png)

## 第三步选择需要的版本

选择对应版本并下载，安装。  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240526153223778-1604264757_1726323567021.png)

### Ubuntu||KUbuntu||Debain

如果出现缺少`libgl1-mesa-glx`依赖，并且apt 无法直接安装的时候，那么从官方源下载deb安装即可。[libgl1-mesa-glx](https://pkgs.org/download/libgl1-mesa-glx)  
选择对应版本，然后找到下面的链接，下载到本地用apt安装。记得换成你对应版本的包的名字。

```bash
sudo apt install ./libgl1-mesa-glx_22.3.6-1+deb12u1_amd64.deb
```

装好依赖后就可以正常安装CiscoPacketTracer了。