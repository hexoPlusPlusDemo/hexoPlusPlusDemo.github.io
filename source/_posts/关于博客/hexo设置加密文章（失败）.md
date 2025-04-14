---
title: hexo设置加密文章(失败)
date: 2024-12-14T13:27:00
abbrlink : b0c241b3d4cf
tags:
  - encrypt
---

我们需要使用一个插件来实现，他叫[hexo-blog-encrypt - npm](https://www.npmjs.com/package/hexo-blog-encrypt)，安装它也十分简单：
```bash
npm install hexo-blog-encrypt
```
在你的工作目录下安装好后，我们来设置它。

## \_config.yml
根据官方给出的实例，我们可以知道，encrypt插件可以通过设置tag来加密，比如下面的配置文件：
```yml
# Security
encrypt: # hexo-blog-encrypt
  abstract: Here's something encrypted, password is required to continue reading.
  message: Hey, password is required here.
  tags:
  - {name: encryptAsDiary, password: passwordA}
  - {name: encryptAsTips, password: passwordB}
  wrong_pass_message: Oh, this is an invalid password. Check and try again, please.
  wrong_hash_message: Oh, these decrypted content cannot be verified, but you can still have a look.
```
从上往下可以看到
```yml
abstract : 
```
可以设置你的摘要
然后是
```yml
message : 
```
可以设置你的提示信息
再就是你的tag了，不同的tag可以设置不同的密码：
```yml
tags:
  - {name: encryptAsDiary, password: passwordA}
  - {name: encryptAsTips, password: passwordB}
```
最后是两个提示信息，第一个是密码错误的时候的提示信息，第二个我暂时不知道是什么含义：
```yml
wrong_pass_message: Oh, this is an invalid password. Check and try again, please.
wrong_hash_message: Oh, these decrypted content cannot be verified, but you can still have a look.
```

但是由于奇怪的问题，我的fluid似乎无法正确的展示这个功能，我无法提交我的密码。我可以确定不是我浏览器的问题，因为我能正确的使用官方的demo。作废吧就此。