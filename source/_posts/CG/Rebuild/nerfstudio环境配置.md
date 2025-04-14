---
title: nerfstudio环境配置
date: 2024-08-07 12:34
abbrlink: 5953
tags: 
categories:
  - CG
  - Rebuild
---

<!--more-->

环境基础：

neofetch

```bash
            .-/+oossssoo+/-.               root@zhy-cuda 
        `:+ssssssssssssssssss+:`           ------------- 
      -+ssssssssssssssssssyyssss+-         OS: Ubuntu 22.04 LTS x86_64 
    .ossssssssssssssssssdMMMNysssso.       Host: SA5212M5 00001 
   /ssssssssssshdmmNNmmyNMMMMhssssss/      Kernel: 6.8.4-3-pve 
  +ssssssssshmydMMMMMMMNddddyssssssss+     Uptime: 13 hours, 43 mins 
 /sssssssshNMMMyhhyyyyhmNMMMNhssssssss/    Packages: 535 (dpkg) 
.ssssssssdMMMNhsssssssssshNMMMdssssssss.   Shell: bash 5.1.16 
+sssshhhyNMMNyssssssssssssyNMMMysssssss+   Resolution: 1024x768 
ossyNMMMNyMMhsssssssssssssshmmmhssssssso   Terminal: node 
ossyNMMMNyMMhsssssssssssssshmmmhssssssso   CPU: Intel Xeon Gold 6138 (80) @ 3.700GHz 
+sssshhhyNMMNyssssssssssssyNMMMysssssss+   GPU: NVIDIA GeForce GTX 1080 Ti 
.ssssssssdMMMNhsssssssssshNMMMdssssssss.   Memory: 3977MiB / 32768MiB 
 /sssssssshNMMMyhhyyyyhdNMMMNhssssssss/
  +sssssssssdmydMMMMMMMMddddyssssssss+
   /ssssssssssshdmNNNNmyNMMMMhssssss/
    .ossssssssssssssssssdMMMNysssso.
      -+sssssssssssssssssyyyssss+-
        `:+ssssssssssssssssss+:`
            .-/+oossssoo+/-.

```

nvidia-smi

```bash
Sun Jul 28 05:42:24 2024       
+---------------------------------------------------------------------------------------+
| NVIDIA-SMI 535.154.05             Driver Version: 535.154.05   CUDA Version: 12.2     |
|-----------------------------------------+----------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |         Memory-Usage | GPU-Util  Compute M. |
|                                         |                      |               MIG M. |
|=========================================+======================+======================|
|   0  NVIDIA GeForce GTX 1080 Ti     On  | 00000000:3B:00.0 Off |                  N/A |
|  0%   27C    P8               9W / 300W |      2MiB / 11264MiB |      0%      Default |
|                                         |                      |                  N/A |
+-----------------------------------------+----------------------+----------------------+
                                                                                         
+---------------------------------------------------------------------------------------+
| Processes:                                                                            |
|  GPU   GI   CI        PID   Type   Process name                            GPU Memory |
|        ID   ID                                                             Usage      |
|=======================================================================================|
|  No running processes found                                                           |
+---------------------------------------------------------------------------------------+
```

## 安装conda

直接来到官网安装，选择跳过注册即可：  
<https://www.anaconda.com/download/success>

```bash
wget https://repo.anaconda.com/archive/Anaconda3-2024.06-1-Linux-x86_64.sh
chmod +x Anaconda3-2024.06-1-Linux-x86_64.sh
export LC_ALL=C.UTF-8
export LANG=C.UTF-8
./Anaconda3-2024.06-1-Linux-x86_64.sh
```

中途出现了一个路径错误，但是我并有中文路径，所以加上了两句export，之后正常安装。  
然后重启终端。

## 安装conda环境

```bash
conda create --name nerfstudio -y python=3.8
conda activate nerfstudio
python -m pip install --upgrade pip
```

到这里正常，然后需要安装一些包。这里加入代理

```bash
# 设置代理
conda config --set proxy_servers.http http://10.10.10.100:7890
conda config --set proxy_servers.https http://10.10.10.100:7890
# 取消代理
conda config --set proxy_servers.http http://10.10.10.100:7890
conda config --set proxy_servers.https http://10.10.10.100:7890
```

然后发现代理无效，于是使用清华源安装对应的库：

```bash
pip3 install torch==2.1.2 torchvision==0.16.2 -i https://pypi.tuna.tsinghua.edu.cn/simple
```

然后设置conda 清华源

```bash
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/free/
conda config --add channels https://mirrors.tuna.tsinghua.edu.cn/anaconda/pkgs/main/
conda config --set show_channel_urls yes
————————————————
版权声明：本文为博主原创文章，遵循 CC 4.0 BY-SA 版权协议，转载请附上原文出处链接和本声明。
原文链接：https://blog.csdn.net/Boys_Wu/article/details/106623192
```

然后安装

```bash
conda install -c "nvidia/label/cuda-11.8.0" cuda-toolkit
```

最后从源码安装nerfstudio即可：

```bash
git clone https://github.com/nerfstudio-project/nerfstudio.git
cd nerfstudio
pip install --upgrade pip setuptools
pip install -e .
```

## 系统代理设置

```bash
# ~/.bashrc
 # set proxy config via profie.d - should apply for all users
export http_proxy="http://10.10.10.100:7890/"
export https_proxy="http://10.10.10.100:7890/"
export ftp_proxy="http://10.10.10.100:7890/"
export no_proxy="127.0.0.1,localhost"
# For curl
export HTTP_PROXY="http://10.10.10.100:7890/"
export HTTPS_PROXY="http://10.10.10.100:7890/"
export FTP_PROXY="http://10.10.10.100:7890/"
export NO_PROXY="127.0.0.1,localhost"
```