---
title: Ubuntu解决高分屏下Matlab工具栏字体过小
date: 2023-07-25 18:43
abbrlink: 6886
tags: 
categories:
  - Linux
  - Ubuntu
---

<!--more-->

**能够看到工具栏，说明你已经能够打开matlab了，不管你是以何种方式打开的。**  
**首先打开matlab，然后在命令行输入一下代码：**

```matlab
#在命令行内输入如下命令，其中2.0是放大的尺度，根据需要自行设置
s = settings;
s.matlab.desktop.DisplayScaleFactor;
s.matlab.desktop.DisplayScaleFactor.PersonalValue = 2.0;
```

**会给出一个重启以适应缩放的提示，重启matlab就好了。**