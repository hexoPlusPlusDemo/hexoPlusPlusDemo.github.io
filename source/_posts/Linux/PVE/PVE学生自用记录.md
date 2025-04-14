---
title: PVE学生自用记录
date: 2024-05-17 16:09
abbrlink: 4182
tags: 
categories:
  - Linux
  - PVE
---

<!--more-->

# PVE记录

这篇博客主要记录自己大二阶段配置和使用PVE的过程。

## 什么是PVE

说到`PVE`，大家可能会想到`Playsers Vs Environment`，但是这里肯定不是指的游戏中的模式了，而是一个操作系统。

> 它的全称为：`Proxmox VE`，是一个运行虚拟机和容器的平台。基于 Debian Linux 完全开源。最大的灵活性，实施了两种虚拟化技术 （1）基于内核的虚拟机 \(KVM\) （2）基于容器的虚拟化 \(LXC\)。

## 我为什么会接触到这个东西？

事情还要从许的这篇论文说起，那天他在朋友圈发了论文的消息，然后我便迫不及待地把代码拉下来想要跑一下，结果就有了这个朋友圈：  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240517151640419-111115740_1726323567021.png)  
是的，我这**古老的笔记本**无法支撑**强大**的Pytorch-3D编译所需要的内存，多次omm，于是我痛定思痛，想要换电脑。  
但是我看了看我的钱包：  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240517152511343-1229231052_1726323590635.jpg)  
还是先将就着吧…………  
**然后！——————**

### 成为垃圾佬

我在向longhao chen请教如何捡垃圾的时候，我发现了它：  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240517152709034-205874299_1726323590635.png)

#### 分析一下：

- CPU : E5 2680V4\*2  
  ![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240517153835868-656025569_1726323590635.png)
  - **一颗100 ，两颗200**
- 主板：Z10PA-D8  
  ![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240517153819905-383790457_1726323590635.png)
  - **600左右**
- 内存条 ： 3200 \* 16g \*2条
  - **一条320 ，两条640**
- 电源
  - **240左右**
- 机箱
  - **50**
- 总计
  - **1730**
- 到手
  - **1030**

要求不高，只要能点亮，不少配件就赚麻了。

#### 激情下单购买配件

128G nvme 固态当缓存（但最后因为速度太慢放弃了）  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240517154046528-508019228_1726323590635.jpg)  
5\*500G sata机械盘组RAID5阵列

> Raid5：至少需要3块硬盘  
> raid5优势：以上优势，raid5兼顾。任意N-1快硬盘都有完整的数据。  
> 缺点：只允许单盘故障，一盘出现故障得尽快处理。有盘坏情况下，raid5 IO/CPU性能狂跌，此时性能烂到无以复加。  
> 建议：盘不多，对数据安全性和性能提示都有要求，raid5是个不错选择

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240517154050308-925812108_1726323611610.jpg)

### 装机

配件完好，机箱像新的，用户手册非常详细。  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240517154518395-927108097_1726323611610.png)  
外挂机械测试是否可正常组阵列。这里组阵列也是用到了PVE的软组，非常的方便。  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240517154528816-1594179286_1726323611610.png)  
Bios版本  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240517154621448-79517483_1726323611610.png)  
CPU正确  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240517154631144-1816898344_1726323611611.png)  
操作系统安装  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240517154658294-69713113_1726323620532.png)  
意外之喜：BMC  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240517154856657-2015804610_1726323620532.png)

### PVE

再通过zerotier进行路由，直接远程连接容器，垃圾佬也是用上自己的服务器了。  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240517155046664-51199699_1726323620532.png)

#### zerotier 路由设置

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240517155412142-2016686325_1726323620532.png)

### 使用

longhao chen给我的建议是：**不要在节点上拉屎，工作全部在容器中进行。**  
节点就是我的PVE服务器（因为PVE服务器可以存在多个一起组网），然后容器就是运行在PVE上的容器。  
于是我当即立下创建了我人生中的第一个**CT容器**，取名为**Main**。开始了我垃圾佬的一生。  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240517163353295-2090178253_1726323620532.png)

### windows

PVE除了可以创建容器以外还可以创建虚拟机！而我刚好有有一些只能在windows上运行的软件，于是便可以通过远程桌面直接控制windows：  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240517164138857-1798400883_1726323646907.png)

### Ubuntu远程桌面

由于图形学的**显示**+**计算**需要，使用ubuntu的远程桌面貌似是最好的解决办法了，于是我找了一些方法，最后找到了这位大佬的帖子：  
[PVE下安装LXC创建桌面环境](https://www.right.com.cn/forum/thread-8227639-1-1.html)