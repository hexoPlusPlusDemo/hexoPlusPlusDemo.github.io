---
title: 实现自己的SHELL
categories:
  - Linux
tags:
  - 技术文档
abbrlink: 61408
updated_at: 2025-03-17 05:26:01
date: 2025-03-10 21:53:00
---
# 前言

这篇文章会从头开始使用`C`语言编写一个可以交互的SHELL，并为其添加以下功能：

- 运行可执行文件
- 输入中断退出
- cd/export/env/exit 内建命令
- 实现了`|`管道通信
- 实现了部分内部命令自动高亮`ls/grep/cat`
- 记录历史命令
- 检查运行环境

未实现功能：
- & 后台任务 / fg / bg 恢复执行
- &&  依赖任务
- || 多任务
- > / >> 重定向

# 任务要求

- （1） 实现一个模拟的shell
- （2） 实现一个管道通信程序

其实书上的写的任务里这些是独立的几个任务，但是我没注意看书上的要求，于是把（1）（2）都写在了SHELL中，也就是说我实现了一个可以使用
```bash
cat /path/to/file | grep symbel | grep symbel2
```
类似机制的指令的SHELL。这里记录、分析一下用到的一些系统调用/库函数。

# 前提
使用了`readline`库，并且使用了`Linux`管道调用，所以不能在`Windows`上复现。
安装`readline`库：
```bash
sudo apt update && sudo apt install libreadline-dev
```

# 创建简单的SHELL部分

对于shell，最重要最简单的功能就是能够读懂用户的指令了，比如最简单的：
```bash
ls
cat file
vim file
pwd
cd path
exit
export something=anotherthing
env
^D
```
又或者复杂一些的命令：
```bash
ls | grep pro
./exe && ./exe2 || ./exe3
```

我们的主函数的逻辑就像下面的结构：
```c
int main() {
    char *input;
    char *prompt;
    char **args;
	setup_signal_handlers(); // 忽视中断信号
    rl_attempted_completion_function = shell_completion; // 设置正则补全回调函数
    welcome(); // 打印欢迎信息
    while (1) {
		prompt = get_prompt(); // 获取提示词
        input = readline(prompt); // 获取输入
        free(prompt);
        if (!input) { // 处理输入结束
            exit_shell();
        }
        if (strlen(input) > 0) {
            add_history(input); // 添加历史记录
            execute_command(input); // 分词并执行指令
        }
        free(input);
    }
    return 0;
}

```

## 信号处理

从上往下看，首先第一个函数`setup_signal_handlers`，你需要在这里处理shell的信号机制，比如用户的中断信号`Ctrl+C`。普通的程序会使用正常的中断退出，但是作为一个shell，不应该在用户发出`Ctrl+C`中断信号的时候退出，而是应该处理`Ctrl+D`的输入终止信号才退出，所以我们可以得到一个简单的`setup_ignal_handlers`函数的定义：
```c
#include <signal.h>
void setup_signal_handlers() {
    signal(SIGINT, SIG_IGN);
}
```
这里的`signal`函数很重要，它的函数声明和使用示例为：
```c
// reference
**void (*signal(int sig, void (*func)(int)))(int)**
// sample
signal(SIGINT, handleInterupt);// 自定义函数处理
signal(SIGINT, SIG_IGN);// 不处理
signal(SIGILL, SIG_DFL);// 默认处理
// ...
```
具体的细节可以参考菜鸟教程：[C 库函数 – signal() \| 菜鸟教程](https://www.runoob.com/cprogramming/c-function-signal.html)

我们只需要忽略掉`SIGINT`信号即可。

## 正则补全

然后是下面这行神奇的代码：
```c
#include <readline/readline.h>
rl_attempted_completion_function = shell_completion;
```
右边是一个形如：
```c
typedef char **rl_completion_func_t(const char * test, int start, int end)
```
的函数指针。该函数需要处理用户输入的不完整字符串的补全结果。`readline`库提供了一个正则匹配的函数：
```c
extern char **rl_completion_matches PARAMS((const char *, rl_compentry_func_t *));
// sample
rl_compentry_func_t *generator = command_generator;
char* result = rl_completion_matches(text, generator);
```
上面的示例中，我们需要定义一个正则规则函数，形如：
```c
char *command_generator(const char *text, int state);
```
的匹配函数，在这个函数中返回我们补全的结果。如果想要了解更多`Readline`中的补全机制，可以参考这篇博客。也可以直接读我的源码。
[ReadLine自动补全分析 - LiuYanYGZ - 博客园](https://www.cnblogs.com/LiuYanYGZ/p/14806474.html)
其实`re_attempted_aompeltion_function`类似于一个回调函数，会在用户按下`Tab`的时候尝试补全。

## 命令处理主体
再往后看，就是我们的函数主体了，在while循环中，我们需要处理用户的`Enter`输入，并执行对应的操作。并且需要为用户提供当前运行环境的一些信息，包括用户名、机器信息、路径信息等。这部分操作我们在`get_prompt`中实现，你可以随心所欲地实现你想要的提示词：

### prompt
```c
char *get_prompt() {
    char cwd[1024];
    char *prompt = malloc(1024);
    struct passwd *pw = getpwuid(getuid());
    if (getcwd(cwd, sizeof(cwd)) == NULL) {
        strcpy(cwd, "?");
    }
    snprintf(prompt, 1024, "%s%s@%s%s:%s%s%s$ ", GREEN,
             pw->pw_name, "myshell", RESET, BLUE, cwd, RESET);
    return prompt;
}
```
这里调用了`getpwuid`、`getuid`、`getcwd`三个函数，你需要引入这些头文件：
```c
#include <pwd.h>
#include <unistd.h>
```

### add_history

`add_history`是`readline`库提供的一个保存命令历史的函数，允许用户使用上下来查阅历史记录。因为上下箭头其实输入的也是一个字符串，可以判断并执行对应的操作。

### execute_command

执行命令！到这里，用户已经输入了一个完整/不完整的命令，并按下了回车键，他希望你能帮他调用这些可执行文件，并得到对应的输出/或重定向到其他地方。首先允许我为你介绍一个分词函数：
```c
char * strtok (char *str, const char * delimiters);
```
需要注意的是，这个函数会将第一参数分割，所以在处理它的时候需要进行复制处理。

下面是一个简单的循环取词的示例：
```c
char * input = "I need a friend.";
char output[10][10];
char * word = strtok(input, " \t\n");
int i = 0;
while(word!=NULL){
	output[i] = word;
	word = strtok(NULL, " \t\n");
}
```


更多有关strtok的信息，请参考：[(十六)strtok、strtok\_s、strtok\_r 字符串分割函数 - xtusir - 博客园](https://www.cnblogs.com/zhangshenghui/p/7911051.html)


