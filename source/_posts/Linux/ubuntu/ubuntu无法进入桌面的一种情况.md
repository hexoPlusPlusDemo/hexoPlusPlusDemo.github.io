---
title: ubuntu无法进入桌面的一种情况
date: 2024-04-23 16:21
abbrlink: 7287
tags: 
categories:
  - Linux
  - Ubuntu
---

<!--more-->

## 问题描述

系统环境：  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240423163225383-1782844975_1726323663548.png)

- 无法进入桌面
- 可以进入锁屏
- 输入密码后黑屏，并返回锁屏
- tty能进入`startx`
- `startx`中部分软件无法打开  
  无法进入桌面最直接的错误，非常严重不可原谅。用户登陆输入密码，黑屏，然后回到用户登陆。

## 误导我的一个报错：

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240423162206763-1640149187_1726323663548.png)  
起初我认为是xdroid-server出毛病了，但是后来发现它无法启动，于是尝试使用`startx`来寻找错误。

## tty如何进入

在锁屏页面使用`Ctrl+Alt+F4`，即可进入`tty`。  
进入后输入用户名和用户密码。

## 进入startx进行debug

登陆好后使用`startx`进入。  
后续操作使用`tty`执行`startx`展现。

## 大量的.desktop无法打开

执行`code`竟然出现`Node.js`的报错

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240423161316305-2104047575_1726323663548.png)

打开`code`可以看到顶部的解释器选择，如果直接指定解释器，发现能够打开VSCode，说明不是可执行文件的错误。

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240423161326206-1860745500_1726323663548.png)

指定解释器：

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240423161343885-1891381834_1726323663548.png)

如果去掉`code`中的指定解释器行：

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240423161351037-1625310902_1726323679699.png)

成功打开：

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240423161357706-1589883165_1726323679699.png)

## 发现了Node.js

观察到VScode的解释器是/usr/bin/env sh

为什么不是/bin/sh或者/usr/bin/sh呢？

于是我尝试运行了/usr/bin/env发现！：

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20240423161402829-1386755668_1726323679699.png)

我天呢？这是什么道理？

## 问题解决

综上所述，我认为是/bin/env和/usr/bin/env被NodeJs覆写了，于是我决定删除/bin/env，然后重装`coreutils`问题解决：

```bash
sudo rm /bin/env
sudo apt reinstall coreutils
```

另外因为安装了`gnome-tweaks`和原来的某些东西有冲突，卸载后恢复原状：

```bash
sudo apt remove gnome-tweaks 
reboot
```

## 总结

这是一个非常奇怪的问题，因为我的`/bin/env`被`Node.js`覆写了，导致大量依赖于`/bin/env`寻找环境的批处理无法运行，这才导致了桌面无法打开。  
debug期间我干了：

### 重装显卡驱动

### 卸载nodejs

### 删除所有与nodejs有关的文件

### 重装gnome

### 切换内核

### 修改用户权限

### 修改profile、\~/.bashrc、/etc/environment……