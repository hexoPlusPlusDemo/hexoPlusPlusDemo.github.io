---
title: Linux批量修改文件名字
date: 2023-07-31 15:18
abbrlink: 3472
tags: 
categories:
  - Linux
---

<!--more-->

**在做这样一件事情的时候我遇到了困难：我有十几个文件的日期都是以点作为分割符的，但是我需要提交的文件名中不能有`.`，那我需要把这些文件名改成`-`为分割符。**

## `mv`

**我只知道`mv`可以修改文件的名字，但是也只能修改一个：**  
`mv 7.20.png 7-20.png`  
**于是我望着我剩下的文件发呆**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230731150828816-471545079_1726324278734.png)  
**百度准备解决一次，用一辈子**

## `rename`

**经过一番百度，我才发现`mv`只能进行单个文件的命名修改，使用`rename`才能进行批量修改：**  
[大佬的rename详解](https://zhuanlan.zhihu.com/p/411184519)  
**我使用的rename 是Perl版本的，那么我可以参照这个表：**

```c
# Perl版本
-v, --verbose  详细：成功重命名的文件的打印名称。
-0, --null 从STDIN读取时，请使用\0作为记录分隔符
-n, --nono 不执行任何操作：打印要重命名的文件名，但不重命名。
-f, --force 覆盖：允许覆盖现有文件
--path, --fullpath 重命名完整路径：包括任何目录组件。默认
-d, --filename, --nopath, --nofullpath 不重命名目录：仅重命名路径的文件名部分
-h, --help 帮助：打印提要和选项。
-m, --man 手册: 打印手册页.
-V, --version 版本: 显示版本号.
-e  表达: 作用于文件名的代码. 可以重复来构建代码（比如“perl-e”）。如果没有-e，则第一个参数用作代码。
-E   语句：对文件名执行操作的代码，如-e，但终止于 ';'.
# C语言版本
-v, --verbose 提供视觉反馈，其中重命名了哪些文件（如果有的话）
-V, --version 显示版本信息并退出。
-s, --symlink 在符号链接目标上执行重命名
-h, --help 显示帮助文本并退出
```

`rename \-v "s/7-/7./g" *`  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230731151533001-202011965_1726324304027.png)  
`rename \-v "s/7./7-/" *`  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230731151638994-1710560310_1726324304027.png)

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230730101326510-705923470_1726324304027.png)