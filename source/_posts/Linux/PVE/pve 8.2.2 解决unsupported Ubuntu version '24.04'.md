---
title: pve 8.2.2 解决unsupported Ubuntu version '24.04'
date: 2024-08-18 12:37
abbrlink: 24484
tags: 
categories:
  - Linux
  - PVE
---

<!--more-->

# 解决unsupported Ubuntu version '24.04'

问题描述：**我在重装pve8.2.2恢复我的容器和虚拟机的时候，发现24.04的容器恢复时出现了如下错误：**

```bash
TASK ERROR: unable to restore CT 104 - unsupported Ubuntu version '24.04'
```

在pve的论坛可以看到这篇文章：[Ubuntu 24.04 \- unsupported Ubuntu version '24.04'](https://forum.proxmox.com/threads/ubuntu-24-04-unsupported-ubuntu-version-24-04.146454/)这里只是对文章进行一个梳理。

## 修改 PVE/LXC/Setup/Ubuntu.pm

参见原文：[Setup support Ubuntu 24.04 noble](https://git.proxmox.com/?p=pve-container.git;a=commitdiff;h=3d800f832c25e4bf2435d88ab190fd8e681a67b1)

```bash
find / -name "Ubuntu.pm"
```

它应该在`/usr/share/perl5/PVE/LXC/Setup/Ubuntu.pm`或者其他的地方，修改它。

```bash
my $known_versions = {
+    '24.04' => 1, # noble
     '23.10' => 1, # mantic
     '23.04' => 1, # lunar
     '22.10' => 1, # kinetic
```

添加24.04这一行。  
然后运行

```bash
pveam available
pveam update
pveam available
```

确保第二次运行`pveam available`的时候已经有`system ubuntu-24.04-standard_24.04-2_amd64.tar.zst`  
然后参考这篇文章换源：[PVE8修改软件仓库源和 CT模板（LXC）源为国内源](https://www.dgpyy.com/archives/174/)，重要的是CT模板换源，如果已经换过了可以跳过。

最后下载24.04模板即可：  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240818123539408-1414267459_1726322928992.png)  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240818123558074-2018575344_1726322928992.png)  
最后重新尝试恢复容器成功：