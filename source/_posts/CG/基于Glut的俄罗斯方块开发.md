---
title: 基于Glut的俄罗斯方块开发
date: 2023-04-09 19:44
abbrlink: 15450
tags: 
categories:
  - CG
---

<!--more-->

### \# 基于Glut的俄罗斯方块

## 概述

**作为大一下期的一个C++程序设计的作业，原本李卫明老师是打算让我们用MFC实现一个俄罗斯方块的，但是我不想学习MFC，所以使用了glut来实现它。所有的代码由自己一个人完成，Game类的维护由李卫明老师的教程优化而来。李卫明老师课程传送门：**  
[1.建立框架](https://course.educg.net/assignment/imgUploadList.jsp?proNum=1&assignID=17360#/learn/_blank)  
[2.添加功能模块](https://v.youku.com/v_show/id_XNTA5NTE5NjA0NA==.html)  
[3.消息响应和界面绘制](https://v.youku.com/v_show/id_XNTA5NTIwMjIzNg==.html)  
**其中，我借鉴了李老师俄罗斯方块的存储方式（4\*4的二维数组来存储一个俄罗斯方块）然后在这篇博客的最后也回答一下李老师提出的这些问题：**  
  
**Q1本游戏开发的主要过程分哪几步？[点击跳转](#Q1)  
Q2游戏界面里控件ID有什么作用？ [点击跳转](#Q2)  
Q3游戏中主要有哪些类？哪些类使用了继承？ A:并没有  
Q4用什么表示俄罗斯方块的形状和颜色？[点击跳转](#Q4)  
Q5l游戏里的俄罗斯方块判断是否可以下落、左移、右移、旋转的方法是什么？[点击跳转](#Q5)  
Q6程序里如何实现俄罗斯方块实际下落、左移、右移、旋转？[点击跳转](#Q6)  
Q7程序里是哪里使用了动态分配？如何避免内存泄漏？ A:没有使用，唯一的地方是Vector，不需要自己进行管理。  
Q8主界面如何绘制、备用俄罗斯方块如何绘制？[点击跳转](#Q8)  
Q9如何实现俄罗斯方块的定时下落？[点击跳转](#Q9)  
Q10如何实现按钮点击响应？[点击跳转](#Q10)  
所以这篇博客可能会比较长，就当自己的一次记录吧。**

## Game类

### Game类的规划

**在我的Game类里面，存储了整个游戏需要的数据，而且维护了整个游戏的运行，但是因为回调函数不允许绑定了对象的函数指针，所以我使用了友元函数作为回调函数，至于为什么没有使用类的静态函数成员，可能是因为我懒吧。或者这个项目比较小，所以没在乎这么多了。这次的代码及其不规范，算是给自己积累一些经验吧。**

### Game类的数据成员

**首先我们来分析一下俄罗斯方块这个游戏的场景和运行逻辑：**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230408180643868-1071810635_1726324554561.png)  
**这里分为了三个方块单位，和一些文字单位，可以看到，蓝色的俄罗斯方块正在随着时间往下走，白色的预备方块静止在等待区域，那么我们需要两个俄罗斯方块对象来存储他们的信息。再看下面的绿色 L 形状的俄罗斯方块，它已经到底了，和场景融为了一体，那么我们也就不需要一个俄罗斯方块的类来存储它了，可以把它存储在场景中，我们用一个二维向量来存储这个场景的信息。**

#### 方块成员

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230408181549748-2094920393_1726324571706.png)  
**Tool类我们稍后再讲，它会是存储一个俄罗斯方块的工具类。然后我们使用vector\<vector\<int>>来存储这个场景的所有信息。（李卫明老师的教程中使用了动态分配的数组。）**

#### 信息成员（分数，等级）

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230408183430897-22289316_1726324571706.png)  
**分数、最高分和等级我们使用三个无符号整型来存储。等级是难度等级，可以用于我们之后的提高难度。**

#### Tool类

**好了，现在我们来实现最基础的Tool类，Tool类是一个俄罗斯方块对象，它有着这些属性：**  
**  
1.记录了方俄罗斯方块的类型  
2.记录了俄罗斯方块的形状  
3.记录了俄罗斯方块的位置  
4.记录是否有过移动（用于判断游戏结束）  
5.可以进行移动、旋转  
**  
  
[点击返回问题目录](#back)

##### 1.俄罗斯方块的类型

**我们使用一个枚举类型，来方便自己绘制俄罗斯方块，枚举中的名字为俄罗斯方块的类型，还可以作为绘制方块时的颜色的枚举使用，如下：**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230408185147821-1779582490_1726324571706.png)  
**其中 WALL是提供给场景使用的一个枚举常量**

##### 2.俄罗斯方块的形状

**每一个俄罗斯方块都可以认为被一个4 \* 4的网格包裹住了，所以我们可以使用一个4 \* 4的二维数组来记录它在地图中所占的位置：**

##### 3.俄罗斯方块的位置

**我们记录一个4 \* 4的网格的位置，其实只需要这个网格左上角的方块的坐标就可以了，也就是说我们记录俄罗斯方块的位置，其实只需要记录一个点的x、y坐标。**

##### 4.是否移动过

**很简单，使用一个bool类型的变量即可，那么我们的Tool类的数据成员看起来像这样：**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230408205154842-1045206341_1726324571706.png)  
  
[点击返回问题目录](#back)

##### 5.移动旋转的实现

**判断是否可以旋转的时候，我们就需要和场景中的方块联系起来了，如果一个方块无法往某个方向移动的话，意味着移动了就会与已经存在的方块重合，或者出游戏区域，那么我们的Tool类旋转的工作就是返回一个移动后的Tool类的结果，但是不能直接对自己移动，因为对于一个Tool对象来说，它不能知道自己是否可以移动但是移动的函数，直接移动就行，之后后讲到为什么，这里举两个例子，旋转和下落：**

> 旋转

```c++
//顺时针旋转
Tool Rotate() {
	Tool NewOne(*this);
	for (int i = 0; i < 4; i++)
		for (int j = 0; j < 4; j++) {
			NewOne._data[j][3 - i] = _data[i][j];
		}
	return NewOne;
}
```

> 下落

```c++
void MoveDown() {
	setPosition(_x, _y + 1);
}
```

**特别的setPosition函数，就是更改了Tool的位置信息，就不说了。然后我们来说一下Tool的构造函数。我们需要自己定义两个构造函数，一个是默认的构造函数，一个是接受三个参数的构造函数，函数原型如下：**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230408210520887-1968227040_1726324571706.png)  
**它接受了一个坐标和一个类型作为参数，对对象进行初始化。要记得对所有的数据成员进行初始化哦，保持好习惯\~**

带参的构造函数

```c++
Tool(int x, int y, ToolType type) 
	:_x(x), _y(y), _type(type),run(false) 
{
	_data.resize(4, vector<int>(4));
	for (int i = 0; i < 4; i++)
		for (int j = 0; j < 4; j++)
			_data[i][j] = 0;
	switch (type) 
	{
		case LL:
			for (int i = 0; i <= 2; i++)_data[1][i] = LL;
			_data[2][2] = LL;
			break;
		case OO:
			for (int i = 1; i <= 2; i++)
				for (int j = 1; j <= 2; j++)
					_data[i][j] = OO;
			break;
		case DOT:
			_data[1][1] = DOT;
			break;
		case II:
			for (int i = 0; i < 4; i++)_data[1][i] = II;
			break;
		case TT:
			for (int i = 0; i < 3; i++)_data[2][i] = TT;
			_data[1][1] = TT;
			break;
	}
}
``` 

**然后，我们还需要一个默认构造函数，来创建临时的Tool对象：**

```c++
Tool()
	:run(false),_x(0),_y(0),_type(LL)
{
	_data.resize(4, vector<int>(4));
}
```

**因为没有动态分配的数据（vector可以自己析构，不用处理），所以我们不需要写析构函数，使用默认的析构函数即可。**  
**到此，我们的Tool类就写完了。**

#### Game类的数据维护函数（私有）

##### NextTool

**Game类有了他自己的数据成员，那么可以开始对数据成员进行维护了，当一个俄罗斯方块落地的时候，替补的俄罗斯方块就会替补当前使用的俄罗斯方块，然后再生成一个新的俄罗斯方块，这个函数我们叫NextTool\(\)**

> NextTool

```c++
void Game::NextTool() {
	swap(m_tool, m_next);
	m_tool.setPosition(rePx, rePy);
	ToolType aType = ToolType(abs(rand()%(TTEnd-LL))+LL);
	m_next = Tool(waitPx, waitPy, aType);
}
```

**我们首先交换两个Tool对象，然后把工作中的Tool对象m\_tool移动到游戏区域，并且把m\_next对象重置为一个随机的俄罗斯方块。这里的随机操作其实是比较优美的形式，因为abs\(rand\(\)\%a\)得到是数据的范围是\(0,a-1\)，但是我们的ToolType的枚举的数值范围是\(LL,TTEnd-1\)，所以我们设置为abs\(rand\(\)\%\(TTEnd-LL\)\)+LL就解决了这个问题。**

##### AddToMap

**然后当这个Tool无法继续下落的时候，我们判断这个这个Tool对象应该加入场景了，我们创建函数AddToMap\(\):**

> AddToMap

```c++
//先把游戏方块加入背景
for(int i=0;i<4;i++)
	for (int j = 0; j < 4; j++) 
		if (m_tool._data[i][j]) 
			m_map[i + m_tool._x][j + m_tool._y] = m_tool._data[i][j];
```

**思考一下，什么时候会出现一行被消除？是不是只有某一个对象加入场景的时候？也就是说，我们应该在对象加入场景的时候进行检测，是否存在某行可以消除。我们可以在加入场景的时候记录一下改变的行数，然后对这些改变的行进行检测。最终的AddToMap代码如下：**

AddToMap

```c++
void Game::AddToMap() {
	vector<int>test;
	//先把游戏方块加入背景
	for(int i=0;i<4;i++)
		for (int j = 0; j < 4; j++) 
			if (m_tool._data[i][j]) {
				m_map[i + m_tool._x][j + m_tool._y] = m_tool._data[i][j];
				test.push_back(j + m_tool._y);
			}
	//检查游戏区域是否可以消除
	auto ibeg = test.begin();
	while (ibeg != test.end()) {
		int i = *ibeg;
		bool flag = true;
		for (int j = dx; j < GameRow; j++) {
			if (!m_map[j][i]) {
				flag = false;
				break;
			}
		}
		//可以消除第 i 行
		if (flag) {
			//把 i 行上面的所有行向下移动
			for (int k = i; k > 0; k--) {
				for (int j = dx; j < GameRow; j++) {
					m_map[j][k] = m_map[j][k - 1];
				}
			}
			//把顶部置空
			for (int j = dx; j < GameRow + dx; j++)
				m_map[j][0] = 0;
			clearTimes++;
			//计算加分
			_points += GameRow * clearTimes;
			if (_points > PB_points) {
				PB = true;
				PB_points = _points;
			}
		}
		//设置难度
		Diff = clearTimes / 3;
		ibeg++;
	}
	//如果加入的时候方块没有移动，判断游戏结束
	if (!m_tool.run) {
		GameOver();
	}
}
``` 

**很好，我们的AddToMap函数就这样完成了。接下来就是让我们的Tool对象接受消息然后动起来了。我们需要实现向下、向左、向右以及旋转的判断和实施函数。**

##### 向下、向左、向右以及旋转

  
[点击返回问题目录](#back)  
**我们的Tool类可以返回变换之后的结果，那么我们的Game类就需要判断是否能够进行变换，以及管理变换，这里我们还是以向下和旋转来举例：**

> CanMoveDown

```c++
bool Game::CanMoveDown() {
	for(int i=0;i<4;i++)
		for (int j = 0; j < 4; j++) {
			if (m_tool._data[i][j]) {
				if (m_tool._y +j+ 1 < Cow) {
					if (m_map[m_tool._x+i][m_tool._y +j + 1])return false;
				}
				else return false;
			}
		}
	return true;
}
```

**这个函数没什么意思，就是一个个的查看，如果重合，那么说明不能进行移动，否则可以。CangetMoveRight函数和CangetMoveLeft函数也相似。本质上是因为平移只需要改变Tool对象的坐标就行了，不需要对节点信息进行修改。让我们来看看旋转**

> Rotate

```c++
bool Game::Rotate() {
	//剪枝，如果是中心对称的图形，直接返回true，代表以及完成了旋转。
	if (m_tool._type == DOT||m_tool._type==OO)return true;
	Tool revTool = m_tool.Rotate();
	for(int i=0;i<4;i++)
		for (int j = 0; j < 4; j++) 
			if (revTool._data[i][j]) 
				if (m_map[revTool._x+i][revTool._y+j])return false;
	//如果没有冲突，直接交换revTool和m_tool，这里和移动赋值的理念有点相似，
	//因为我的m_tool已经不需要了，直接让revTool来进行析构。
	swap(m_tool, revTool);
	return true;
}
```

**因为旋转的开销还是比较大的，所以我们不进行多次旋转操作，也就是不设置CanRotate函数，直接改成Rotate函数，如果能够旋转就实施了。**

##### Drop

**因为下落有着独特的数据维护方法，所以我们写一个Drop函数来维护这一行为，Drop函数需要检查是否可以下落，以及下落之后的状态更新，还有不能下落时的数据处理。**

> Drop

```c++
void Game::Drop() {
	if (CanMoveDown()) {
		m_tool.run = true;
		m_tool.MoveDown();
	}
	else {
		AddToMap();
		NextTool();
	}
}
```

**在可以移动时，更新Tool的移动状态为true，并更新m\_tool的数据，**

##### Start

**到这里，我们的数据维护函数就基本上写完了，我们的Game对象可以操控两个Tool对象进行移动，判断是否可以移动，计算游戏加分，计算游戏是否结束等等，接下来我们为Game类添加开始函数，因为在游戏开始之前，我们的Game对象中的Tool对象是没有任何数据的，所以我们使用两次NextTool来让m\_tool和m\_next都有数据。然后，我们还需要引入一个新的概念游戏状态，我们来看Start函数：**

> Start

```c++
void Game::Start() {
	status = RUN;
	NextTool();
	NextTool();
}
```

**我们要做的事情很简单，把游戏的状态更改为`RUN`，然后调用两次NextTool就行了。**

#### 游戏状态的更新

**首先我们为Game类添加一个枚举对象，用于描述游戏的状态：**

```c++
typedef enum {
	STOP,			//游戏暂停
	PRESTART,		//游戏开始前
	RUN,			//游戏进行时
	GAMEOVER,		//游戏结束
	GAMEWIN,		//游戏胜利
}GameMode;
```

~~（其实是不存在游戏胜利这一说的，但是我想留一个小彩蛋，所以加入了这一状态，但是达到这个条件是人类不太可能完成的。）~~  
**然后我们为之前需要更改游戏状态的地方添加游戏状态的更改。比如在AddToMap中提到的GameOver函数：**

##### GameOver

```c++
void Game::GameOver() {
	if (_points > PB_points) {
		PB = true;
		PB_points = _points;
	}
	status = GAMEOVER;
}
```

**更新游戏状态，并检测是否破纪录。**

##### 构造函数

**创建一个Game类的对象的时候，将游戏的状态设置为PRESTAT开始前：**

构造函数

```c++
Game::Game() 
:status(PRESTART),_points(0),PB_points(0),PB_Diff(0), 
	clearTimes(0),Diff(0),PB(false)
{
	m_map.resize(Row, vector<int>(Cow));
	srand((unsigned int)time(NULL));
	for (int i = 0; i < Cow; i++) {
		//左边竖墙
		for (int j = 0; j < dx; j++)
			m_map[j][i] = WALL;
		//中间竖墙
		for (int j = 1; j <= dx; j++)
			m_map[GameRow + j][i] = WALL;
		//右边竖墙
		for (int j = 1; j <= dx; j++)
			m_map[Row - j][i] = WALL;
	}
	//顶上底下横墙
	for (int i = 0; i < dx; i++)
		for (int j = 0; j < Row - GameRow - 3 * dx; j++) {
			m_map[GameRow + 2 * dx + j][i] = WALL;
			m_map[GameRow + 2 * dx + j][Cow - 1 - i] = WALL;
		}
	//中间横墙
	for (int i = 0; i < Row - GameRow - 3 * dx; i++)m_map[GameRow + 2 * dx + i][4 + dx] = WALL;
	//next Toll右边的横杆
	for (int i = 0; i < 4; i++)m_map[2 * dx + GameRow][dx + i] = WALL;
}
``` 

**构造函数不仅要初始化所有数据、设置游戏状态外，还需要将场景的WALL部分填充，dx是设置的一个静态整形变量，用于调整边界的厚度。Row和Cow是屏幕的大小；GameRow和GameCow就是游戏区域了，这些是整形常量，这个图可以说明这一关系：**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230409125459381-2131391684_1726324590488.png)  
**这里是我的初始化**

```c++
const int mapScre = 1;						//场景缩放
const int  NodeSize = 20;					//方形边长
const int Cow = 30 * mapScre;				//窗口行数  y
const int Row = 24 * mapScre;				//列数  x
const int GameCow = 30 * mapScre;			//游戏场景行数
const int GameRow = 16 * mapScre;			//列数
```

```c++
//Game::public
	static const int dx, dy;				//用于弥补场景边框距离
	static const int rePx, rePy;			//操纵的Tool的初始位置
	static const int waitPx, waitPy;		//等待初始位置
	static const int infoPx, infoPy;		//信息所绘制的位置
```

##### reset

**其他的状态更新操作会在消息处理的时候进行，然后我还需要完成Game类的最后一个成员函数reset，用于重置游戏：**

```c++
void Game::reset() {
	PB = false;
	status = PRESTART;
	_points = 0;
	clearTimes = 0;
	Diff = 0;
	for (int i = dx; i < GameRow+dx; i++)
		for (int j = 0; j < GameCow; j++)
			 m_map[i][j] = 0;
}
```

## Glut

**不会装glut的可以参考这篇博客**  
  
[【Opengl】Glut下载与环境配置](https://blog.csdn.net/qq_31788759/article/details/104342559)  
[返回irrklang](#irr)

**另外，我们还需要glfw来提供消息处理的宏定义。这里我只教VS的配置方法：  
打开你的目标工程，然后点击上方的工具->NuGet包管理器**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230409152852350-2051693689_1726324590488.png)  
**点击浏览->搜索glfw->下载**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230409153000235-919398990_1726324590488.png)  
**下载到当前项目就行了。我们需要的头文件有这么两个：**

```c++
#include <gl/glut.h>
#include <GLFW/glfw3.h>
```

**当然还要包括你自己写的Game类的头文件，然后创建我们唯一的Game类对象（作为全局变量）`Game myGame;`在main函数中对窗口进行初始化：**

```c++
int main(int argc, char* argv[])
{
	// 初始化 glut
	glutInit(&argc, argv);
	// 设置 OpenGL 显示模式(双缓存, RGB 颜色模式)
	glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB);
	// 设置窗口初始尺寸
	glutInitWindowSize(Row*NodeSize, Cow*NodeSize);
	// 设置窗口初始位置
	glutInitWindowPosition(100, 100);
	// 设置窗口标题
	glutCreateWindow("Terix");
	// 进入 glut 事件循环
	glutMainLoop();
	return 0;
}
```

**然后我们还需要绑定输入回调函数、显示回调函数、计时器、窗口尺寸改变的回调函数以及设置菜单（非必须）。**

## 回调函数

**回调函数中，大部分需要对Game类的的数据进行更新或者读取，那么最好的办法就是使用成员函数进行绑定，但是这是不被允许的。因为指向绑定函数的指针只能用于调用函数。也就是说我们的回调函数不能是类的成员函数。所以我们将其设置为友元。**

```c++
friend void Input(int data, int x, int y);
friend void onDisplay();
friend void Input(unsigned char nchar, int x, int y);
friend void processMenuEvents(int option);
```

**然后我们开始，先从简单的来处理**

### 1.窗口尺寸变化回调函数

**这个函数允许我们的窗口在大小改变时，不会出现图像拉扯的情况，设置了这个回调函数之后的效果是这样的：**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230409153911761-1776818662_1726324590488.png)  
**拖动窗口，使其尺寸发生变化，会得到这样的结果：**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230409154004889-950934146_1726324590488.png)  
**不仅如此，我们的投影也发生在这个函数里面，投影的原理我就不讲了，这涉及到一些图形学的内容，有兴趣的可以去看Games101的课程，传送门：**  
[【GAMES101-现代计算机图形学入门-闫令琪】](https://www.bilibili.com/video/BV1X7411F744/?share_source=copy_web "中国最好的计算机图形学入门课")  
**这里我们设置一个简单的二维平行投影：**

```c++
void onReshape(int w, int h)
{
	// 设置视口大小
	glViewport(0, 0, w, h);
	// 切换矩阵模式为投影矩阵
	glMatrixMode(GL_PROJECTION);
	// 载入单位矩阵
	glLoadIdentity();
	// 进行二维平行投影
	gluOrtho2D(0, w, h, 0);
	// 切换矩阵模式为模型矩阵
	glMatrixMode(GL_MODELVIEW);
	// 发送重绘
	glutPostRedisplay();
}

// In main
------------
	// 设置窗口尺寸变化回调函数
	glutReshapeFunc(onReshape);
```

### 2.计时器

**计时器可以让我们在一定的时间内调用一次该函数，我们需要计时器来使俄罗斯方块自动的下坠，并且下降的速度就是我们调用这个函数所间隔的时间，我们可以利用这点来动态的设置游戏的难度：**  
  
[点击返回问题目录](#back)

```c++
void Ontime(int timeid) {
	timeid++;
	timeid %= 1000;
	//如果游戏进行中，那么下降一格
	if(myGame.getStatus() == RUN)
		myGame.Drop();
	int Deltatime = 150 - 3 * myGame.getDiff();
	//It is imposible!!!
	if (Deltatime <= 50)myGame.ChangeStatus(GAMEWIN) ;
	//进行图形的绘制
	onDisplay();
	glutTimerFunc(Deltatime, Ontime, 1);
}
```

**这里我设置了一个很简单的难度系统，难度和等级成正比？Deltatime就是调用该函数所间隔的时间，我设置了当Deltatime\<=50时判定为游戏胜利，也就是1秒钟1000/50=20帧，就是说它会下降20格。（**

### 3.显示回调函数

**可以看到，在Ontime里面调用了onDisplay函数，这个函数绘制了Game类的所有信息。首先让我们学一下glut的绘制逻辑，在每次绘制之前，我们需要对屏幕上的像素进行清理，我们叫它Clear，清理也不是随便清理，相当于清除了一帧的缓存，清除之前设置一个清楚颜色：**

```c++
//in OnDisplay()
	// 设置清屏颜色
	glClearColor(BCR_COLOR,1);
	// 用指定颜色清除帧缓存
	glClear(GL_COLOR_BUFFER_BIT);
	/*
	绘制操作
	*/
	//Clear Buffer
	glutSwapBuffers();
```

**因为我们采用了双缓存的模式，所以以交换缓存为绘制结束。这样我们就不会出现频闪的问题。这里我也可以解释一下频闪出现的原因，频闪的出现不是因为电脑性能不行，而是你在画图的时候给屏幕发的绘制指令数太多了，应该先把一帧的画图操作全部写在缓存中，然后一次性发给屏幕绘制。**

**让我们回到俄罗斯方块的游戏场景，这次我们分游戏状态来处理:**

#### RUN

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230409160627367-1277858287_1726324605716.png)  
**这里我们需要绘制的信息有：两个俄罗斯方块、场景方块、游戏信息。**

#### STOP

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230409160631565-514488294_1726324605716.png)  
**STOP很简单，我们只需要在RUN的基础上加上一句暂停的提示语就行了。**

#### GAMEOVER

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230409160638296-1473794252_1726324605716.png)  
**为了让GAMEOVER的时候，玩家可以感受到一种视觉冲击，所以我设置为了只绘制失败信息，并且如果分数没有超过作者的话，会奉上一句Git Gud，~~以表示敬意~~。**

#### PRESTART

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230409160640858-1534298872_1726324605716.png)  
**这个就是游戏开始之前的画面，需要绘制一些指导的信息，比如如何开始游戏、游戏的一些快捷操作、游戏的自动保存机制等等。**

#### 实现

**从上面的总结来看，不难发现：只有两个状态需要绘制场景和俄罗斯方块：**

##### 如何绘制一个方块？

**在正式的绘制信息之前，我们先来介绍一下如何绘制一个正方形。在glut中绘制一个正方形的方式非常的简单，我们可以直接使用它封装的函数进行绘制。绘制一个矩形的代码会像这样：**

```c++
glColor3f(ITEM_COLOR);
glRectd(x1,y1,x2,y2);
```

**在绘制矩形前设置矩形的填充颜色，然后设置矩形对角线的两个点的坐标就行了。**  
  
[点击返回问题目录](#back)

##### 如何绘制信息？

**在画面上，还有各种的信息显示，这里使用的是全英文的位图，因为内置的位图不支持中文，所以使用英文图个方便。绘制一串话的代码会像这样：**

```c++
const char points[20] = "Points:";
char points_num[20];
sprintf(points_num, "%d", myGame._points);
//设置字体颜色
glColor3f(TEXT_COLOR);
//设置位图位置
glRasterPos2d(Infox, Infoy);
for(int i=0;points[i]!='\0';i++)
	glutBitmapCharacter(INFO_FONT, points[i]);
//设置位图位置
glRasterPos2d(Infox, Infoy+5);
for(int i=0;points_num[i]!='\0';i++)
	glutBitmapCharacter(INFO_FONT, points_num[i]);
```

**因为使用了sprintf，所以这段代码在VS是跑不出来的，我们需要让VS认为这是安全的：加入宏定义：`#define _CRT_SECURE_NO_WARNINGS`**

##### 具体实现

运行时和暂停的绘制

```c++
	//Draw Normal Info
	if (myGame.status!=PRESTART&&myGame.status!=GAMEOVER&&myGame.status!=GAMEWIN) {
		//Draw BackGroud
		for (int i = 0; i < Row; i++) {
			bool flag = true;
			for (int j = 0; j < Cow; j++) {
				switch (myGame.m_map[i][j]) {
				case 0:
					flag = false;
					break;
				case Game::LL:
					glColor3f(LL_COLOR);
					break;
				case Game::OO:
					glColor3f(OO_COLOR);
					break;
				case Game::DOT:
					glColor3f(DOT_COLOR);
					break;
				case Game::II:
					glColor3f(II_COLOR);
					break;
				case Game::TT:
					glColor3f(TT_COLOR);
					break;
				case Game::WALL:
					glColor3f(WALL_COLOR);
					break;
				default:
					glColor3f(ELSE_COLOR);
				}
				if (flag)
					glRectd(i * NodeSize, j * NodeSize, (i + 1) * NodeSize, (j + 1) * NodeSize);
				
				flag = true;
			}
		}

		//Draw Active Terix
		switch (myGame.m_tool._type) {
		case Game::LL:
			glColor3f(LL_COLOR);
			break;
		case Game::OO:
			glColor3f(OO_COLOR);
			break;
		case Game::DOT:
			glColor3f(DOT_COLOR);
			break;
		case Game::II:
			glColor3f(II_COLOR);
			break;
		case Game::TT:
			glColor3f(TT_COLOR);
			break;
		default:
			glColor3f(ELSE_COLOR);
		}

		for (int i = 0; i < 4; i++) {
			for (int j = 0; j < 4; j++) {
				if (myGame.m_tool._data[i][j])
					glRectd((myGame.m_tool._x + i) * NodeSize, (myGame.m_tool._y + j) * NodeSize, (myGame.m_tool._x + i + 1) * NodeSize, (myGame.m_tool._y + j + 1) * NodeSize);
			}
		}
		//Draw Waiting Terix
		switch (myGame.m_next._type) {
		case Game::LL:
			glColor3f(LL_COLOR);
			break;
		case Game::OO:
			glColor3f(OO_COLOR);
			break;
		case Game::DOT:
			glColor3f(DOT_COLOR);
			break;
		case Game::II:
			glColor3f(II_COLOR);
			break;
		case Game::TT:
			glColor3f(TT_COLOR);
			break;
		default:
			glColor3f(ELSE_COLOR);
		}

		for (int i = 0; i < 4; i++) {
			for (int j = 0; j < 4; j++) {
				if (myGame.m_next._data[i][j])
					glRectd((myGame.m_next._x + i) * NodeSize, (myGame.m_next._y + j) * NodeSize, (myGame.m_next._x + i + 1) * NodeSize, (myGame.m_next._y + j + 1) * NodeSize);
			}
		}
		//Draw Info
		const char points[20] = "Points:", PBpoints[20] = "PB:", Diff[20] = "Rank:",zhywyt[]="zhywyt:";
		char points_num[20], PBpoints_num[20], Diff_num[20],zhywyt_num[20];
		sprintf(points_num, "%d", myGame._points);
		sprintf(PBpoints_num, "%d", myGame.PB_points);
		sprintf(Diff_num, "%d", myGame.Diff);
		sprintf(zhywyt_num, "%d", myGame.zhywyt);

		const char* strinfo[] = { points,PBpoints,Diff,zhywyt };
		char* str_num[] = { points_num,PBpoints_num,Diff_num ,zhywyt_num};
		if (!myGame.PB)
			glColor3f(TEXT_COLOR);
		else 
			glColor3f(PB_TEXT_COLOR);
		for (int i = 0; i < 4; i++) {
			if (i == 3)glColor3f(PB_TEXT_COLOR);
			glRasterPos2d(Game::infoPx * NodeSize, (Game::infoPy + 5 * i) * NodeSize);
			for (int j = 0; strinfo[i][j] != '\0'; j++)glutBitmapCharacter(INFO_FONT, strinfo[i][j]);
			glRasterPos2d(Game::infoPx * NodeSize, (Game::infoPy + 5 * i + 2) * NodeSize);
			for (int j = 0; str_num[i][j] != '\0'; j++)glutBitmapCharacter(INFO_FONT, str_num[i][j]);
		}
		//Draw Stop Info
		if (myGame.status == STOP) {
			const char PrestartInfo[30] = "Press Space to start.";
			glRasterPos2d((Game::dx)*NodeSize, (GameCow + 3 * Game::dx) / 2 * NodeSize);
			glColor3f(TEXT_COLOR);
			for (int i = 0; PrestartInfo[i] != '\0'; i++)
				glutBitmapCharacter(INFO_FONT, PrestartInfo[i]);
		}
	}
``` 其他的纯文本绘制

```c++
else {
	if (myGame.status == GAMEOVER) {
		//Draw gameover info
		const char GameOverinfo[30] = "Game Over!";
		char Score[30], Points[30];
		sprintf(Points, "%d", myGame._points);
		const char* VAO[3] = { GameOverinfo,Score,Points };
		if (!myGame.PB) {
			glColor3f(GAMEOVER_TEXT_COLOR);
			sprintf(Score, "Your score is ");
		}
		else {
			glColor3f(PB_TEXT_COLOR);
			sprintf(Score, "WoW!! PB! ");
		}
		for (int i = 0; i < 3; i++) {
			glRasterPos2d((Game::dx * 2) * NodeSize, ((GameCow - 4 * Game::dx) / 2+i*2*Game::dx) * NodeSize);
			for (int j = 0; VAO[i][j] != '\0'; j++)
				glutBitmapCharacter(INFO_FONT, VAO[i][j]);
		}
		char Good[40];
		if (myGame.exZhywyt) {
			sprintf(Good, "You are great ! You over the zhywyt!!");
		}
		else {
			sprintf(Good, "Git Gud.");
		}
		glRasterPos2d((Game::dx * 2)* NodeSize, ((GameCow-4*Game::dx ) / 2+6*Game::dx) * NodeSize);
		for (int j = 0;Good[j] != '\0'; j++)
			glutBitmapCharacter(INFO_FONT, Good[j]);

	}
	else if (myGame.status == GAMEWIN) {
		//It is imposible!!!!!
		const char Info1[30] = "You may use something else", Info2[30] = "To do this imposible task.";
		const char* str[] = { Info1,Info2 };
		glColor3f(RGB(255, 0, 255));
		for (int i = 0; i < 2; i++) {
			glRasterPos2d((Game::dx * 2) * NodeSize, (GameCow + (i * 3 + 1) * Game::dx) / 2 * NodeSize);
			for (int j = 0;str[i][j] != '\0'; j++)
				glutBitmapCharacter(INFO_FONT, str[i][j]);
		}
	}
	else {
		const char helpInfo1[] = "Your Can Press the Space to stop Game.";
		const char helpInfo2[] = "And you can click the right butttom to-";
		const char helpInfo21[] = "-open the emun";
		const char helpInfo3[] = "You should use the emnu \"exit\" to exit-";
		const char helpInfo31[] = "-not close the window";
		const char PrestartInfo[30] = "Press Space to start.";
		const char LuckInfo[] = "Have Good Time!";
		const char* str[] = {PrestartInfo,helpInfo31,helpInfo3,helpInfo21,helpInfo2,helpInfo1 };
		glColor3f(TEXT_COLOR);
		for (int j = 5; j >=0; j--) {
		glRasterPos2d((Game::dx)*NodeSize, ((GameCow + 9 * Game::dx) / 2-j*2 )* NodeSize);
			for (int i = 0; str[j][i] != '\0'; i++)
				glutBitmapCharacter(INFO_FONT, str[j][i]);
		}
		glColor3f(PB_TEXT_COLOR);
		glRasterPos2d((Game::dx)*NodeSize, ((GameCow + 12 * Game::dx)/2* NodeSize));
		for (int i = 0; LuckInfo[i] != '\0'; i++)
			glutBitmapCharacter(INFO_FONT, LuckInfo[i]);
	}
}
``` onDisplay

```c++
void onDisplay()
{
	// 设置清屏颜色
	glClearColor(BCR_COLOR,1);
	// 用指定颜色清除帧缓存
	glClear(GL_COLOR_BUFFER_BIT);

	//Draw Normal Info
	if (myGame.status!=PRESTART&&myGame.status!=GAMEOVER&&myGame.status!=GAMEWIN) {
		//Draw BackGroud
		for (int i = 0; i < Row; i++) {
			bool flag = true;
			for (int j = 0; j < Cow; j++) {
				switch (myGame.m_map[i][j]) {
				case 0:
					flag = false;
					break;
				case Game::LL:
					glColor3f(LL_COLOR);
					break;
				case Game::OO:
					glColor3f(OO_COLOR);
					break;
				case Game::DOT:
					glColor3f(DOT_COLOR);
					break;
				case Game::II:
					glColor3f(II_COLOR);
					break;
				case Game::TT:
					glColor3f(TT_COLOR);
					break;
				case Game::WALL:
					glColor3f(WALL_COLOR);
					break;
				default:
					glColor3f(ELSE_COLOR);
				}
				if (flag)
					glRectd(i * NodeSize, j * NodeSize, (i + 1) * NodeSize, (j + 1) * NodeSize);
				
				flag = true;
			}
		}

		//Draw Active Terix
		switch (myGame.m_tool._type) {
		case Game::LL:
			glColor3f(LL_COLOR);
			break;
		case Game::OO:
			glColor3f(OO_COLOR);
			break;
		case Game::DOT:
			glColor3f(DOT_COLOR);
			break;
		case Game::II:
			glColor3f(II_COLOR);
			break;
		case Game::TT:
			glColor3f(TT_COLOR);
			break;
		default:
			glColor3f(ELSE_COLOR);
		}

		for (int i = 0; i < 4; i++) {
			for (int j = 0; j < 4; j++) {
				if (myGame.m_tool._data[i][j])
					glRectd((myGame.m_tool._x + i) * NodeSize, (myGame.m_tool._y + j) * NodeSize, (myGame.m_tool._x + i + 1) * NodeSize, (myGame.m_tool._y + j + 1) * NodeSize);
			}
		}
		//Draw Waiting Terix
		switch (myGame.m_next._type) {
		case Game::LL:
			glColor3f(LL_COLOR);
			break;
		case Game::OO:
			glColor3f(OO_COLOR);
			break;
		case Game::DOT:
			glColor3f(DOT_COLOR);
			break;
		case Game::II:
			glColor3f(II_COLOR);
			break;
		case Game::TT:
			glColor3f(TT_COLOR);
			break;
		default:
			glColor3f(ELSE_COLOR);
		}

		for (int i = 0; i < 4; i++) {
			for (int j = 0; j < 4; j++) {
				if (myGame.m_next._data[i][j])
					glRectd((myGame.m_next._x + i) * NodeSize, (myGame.m_next._y + j) * NodeSize, (myGame.m_next._x + i + 1) * NodeSize, (myGame.m_next._y + j + 1) * NodeSize);
			}
		}
		//Draw Info
		const char points[20] = "Points:", PBpoints[20] = "PB:", Diff[20] = "Rank:",zhywyt[]="zhywyt:";
		char points_num[20], PBpoints_num[20], Diff_num[20],zhywyt_num[20];
		sprintf(points_num, "%d", myGame._points);
		sprintf(PBpoints_num, "%d", myGame.PB_points);
		sprintf(Diff_num, "%d", myGame.Diff);
		sprintf(zhywyt_num, "%d", myGame.zhywyt);

		const char* strinfo[] = { points,PBpoints,Diff,zhywyt };
		char* str_num[] = { points_num,PBpoints_num,Diff_num ,zhywyt_num};
		if (!myGame.PB)
			glColor3f(TEXT_COLOR);
		else 
			glColor3f(PB_TEXT_COLOR);
		for (int i = 0; i < 4; i++) {
			if (i == 3)glColor3f(PB_TEXT_COLOR);
			glRasterPos2d(Game::infoPx * NodeSize, (Game::infoPy + 5 * i) * NodeSize);
			for (int j = 0; strinfo[i][j] != '\0'; j++)glutBitmapCharacter(INFO_FONT, strinfo[i][j]);
			glRasterPos2d(Game::infoPx * NodeSize, (Game::infoPy + 5 * i + 2) * NodeSize);
			for (int j = 0; str_num[i][j] != '\0'; j++)glutBitmapCharacter(INFO_FONT, str_num[i][j]);
		}
		//Draw Stop Info
		if (myGame.status == STOP) {
			const char PrestartInfo[30] = "Press Space to start.";
			glRasterPos2d((Game::dx)*NodeSize, (GameCow + 3 * Game::dx) / 2 * NodeSize);
			glColor3f(TEXT_COLOR);
			for (int i = 0; PrestartInfo[i] != '\0'; i++)
				glutBitmapCharacter(INFO_FONT, PrestartInfo[i]);
		}
	}
	//Draw Prestart info
	else {
		if (myGame.status == GAMEOVER) {
			//Draw gameover info
			const char GameOverinfo[30] = "Game Over!";
			char Score[30], Points[30];
			sprintf(Points, "%d", myGame._points);
			const char* VAO[3] = { GameOverinfo,Score,Points };
			if (!myGame.PB) {
				glColor3f(GAMEOVER_TEXT_COLOR);
				sprintf(Score, "Your score is ");
			}
			else {
				glColor3f(PB_TEXT_COLOR);
				sprintf(Score, "WoW!! PB! ");
			}
			for (int i = 0; i < 3; i++) {
				glRasterPos2d((Game::dx * 2) * NodeSize, ((GameCow - 4 * Game::dx) / 2+i*2*Game::dx) * NodeSize);
				for (int j = 0; VAO[i][j] != '\0'; j++)
					glutBitmapCharacter(INFO_FONT, VAO[i][j]);
			}
			char Good[40];
			if (myGame.exZhywyt) {
				sprintf(Good, "You are great ! You over the zhywyt!!");
			}
			else {
				sprintf(Good, "Git Gud.");
			}
			glRasterPos2d((Game::dx * 2)* NodeSize, ((GameCow-4*Game::dx ) / 2+6*Game::dx) * NodeSize);
			for (int j = 0;Good[j] != '\0'; j++)
				glutBitmapCharacter(INFO_FONT, Good[j]);

		}
		else if (myGame.status == GAMEWIN) {
			//It is imposible!!!!!
			const char Info1[30] = "You may use something else", Info2[30] = "To do this imposible task.";
			const char* str[] = { Info1,Info2 };
			glColor3f(RGB(255, 0, 255));
			for (int i = 0; i < 2; i++) {
				glRasterPos2d((Game::dx * 2) * NodeSize, (GameCow + (i * 3 + 1) * Game::dx) / 2 * NodeSize);
				for (int j = 0;str[i][j] != '\0'; j++)
					glutBitmapCharacter(INFO_FONT, str[i][j]);
			}
		}
		else {
			const char helpInfo1[] = "Your Can Press the Space to stop Game.";
			const char helpInfo2[] = "And you can click the right butttom to-";
			const char helpInfo21[] = "-open the emun";
			const char helpInfo3[] = "You should use the emnu \"exit\" to exit-";
			const char helpInfo31[] = "-not close the window";
			const char PrestartInfo[30] = "Press Space to start.";
			const char LuckInfo[] = "Have Good Time!";
			const char* str[] = {PrestartInfo,helpInfo31,helpInfo3,helpInfo21,helpInfo2,helpInfo1 };
			glColor3f(TEXT_COLOR);
			for (int j = 5; j >=0; j--) {
			glRasterPos2d((Game::dx)*NodeSize, ((GameCow + 9 * Game::dx) / 2-j*2 )* NodeSize);
				for (int i = 0; str[j][i] != '\0'; i++)
					glutBitmapCharacter(INFO_FONT, str[j][i]);
			}
			glColor3f(PB_TEXT_COLOR);
			glRasterPos2d((Game::dx)*NodeSize, ((GameCow + 12 * Game::dx)/2* NodeSize));
			for (int i = 0; LuckInfo[i] != '\0'; i++)
				glutBitmapCharacter(INFO_FONT, LuckInfo[i]);
		}
	}
	//Clear Buffer
	glutSwapBuffers();
}

``` 

**如果仔细的读过代码的人会发现，代码里面出现了很多的宏定义，那是为了编程的方便，我们会设置一个Reasource.h文件，来统一管理我们的资源。完整的Reasource.h代码在这里贴出：**

Reasource.h

```c++
#ifndef REASOURCE_H
#define REASOURCE_H
#define GLUT_KEY_ESCAPE 27
#define RGB(a,b,c) (a/255.0),(b/255.0),(c/255.0)	//用于255转0.0-1.0
#define BCR_COLOR RGB(0,0,0)						//背景颜色

//所有俄罗斯方块的颜色
#define LL_COLOR RGB(0,255,0)									
#define OO_COLOR RGB(255,0,0)
#define DOT_COLOR RGB(255,255,255)
#define II_COLOR RGB(0,255,255)
#define TT_COLOR RGB(164, 225, 202)
#define ELSE_COLOR RGB(0,0,0)
#define WALL_COLOR RGB(100,255,0)

//状态颜色
#define TEXT_COLOR RGB(255,255,255)
#define GAMEOVER_TEXT_COLOR RGB(255,0,0)
#define PB_TEXT_COLOR RGB(0,255,0)

//字体设置
#define INFO_FONT GLUT_BITMAP_TIMES_ROMAN_24

#endif
``` 

### 4.输入回调函数

**终于到了激动人心的输入回调函数了，这里将是用户和窗口进行交互的地方，会处理用户所有的键盘敲击。用户的输入的作用是会随着游戏的状态的改变而改变的。在俄罗斯方块中，用户的输入大概有这些**  
  
1.WASD  
2.UP DOWN LEFT RIGHT  
  
**其实我们知道他们是对应相等的。这里我还添加了第三个输入:**  
  
3.SPACE  
  
**这个SPACE可以干很多事情，比如在游戏运行的时候可以暂停游戏，在游戏暂停的时候可以恢复游戏，在游戏结束的时候可以重置游戏，在游戏准备阶段可以开始游戏。我个人觉得是非常好的一个设计。好了，知道了输入的信息种类，我们来介绍一下glut的消息处理机制。glut中有两种消息的大类型：普通消息和特殊消息**

#### 普通消息处理

**普通消息的回调函数的绑定是这样的：**

```c++
glutKeyboardFunc(Input);
```

**其中Input函数的声明式这样的：**

```c++
void Input(unsigned char nchar, int x, int y); 
```

**从参数列表中可以看到nchar就是消息的信息，它的类型是unsigned char也就是说它所能承载的消息数量是不多的，包括了大部分的键盘输入但是没有功能键和方向键。所以我们还需要一个特殊消息处理回调函数。**

#### 特殊消息处理

**与普通消息处理不同的是，特殊消息处理中的nchar参数的类型是int 这允许了它可以包含几乎所有的消息。它的绑定回调函数是这样的：**

```c++
glutSpecialFunc(Input);
```

**回调函数是这样的：**

```c++
void Input( int nchar, int x, int y);
```

#### 输入信息

**我们来分析这个过程，从游戏开始到结束，分别可以接受的输入有哪些。**

##### 1.游戏开始前

**只能接受一个SPACE信息，然后进入RUN状态。**

```c++
//处理游戏开始前的输入
if (myGame.status == PRESTART) {
	if (nchar == GLFW_KEY_SPACE) {
	myGame.Start();
	}
}
```

##### 2.游戏进行中

**可以接受移动的信息，以及空格信息进行暂停操作。**

```c++
//处理游戏时的输入
if (myGame.status == RUN) {	
	if (nchar == GLUT_KEY_UP || nchar == GLFW_KEY_W) {
		myGame.Rotate();
	}
	else if (nchar == GLFW_KEY_S || nchar == GLUT_KEY_DOWN) {
		myGame.Drop();
	}
	else if (nchar == GLFW_KEY_A || nchar == GLUT_KEY_LEFT) {
		if (myGame.CangetMoveLeft())
			myGame.m_tool.MoveLeft();
	}
	else if (nchar == GLFW_KEY_D || nchar == GLUT_KEY_RIGHT) {
		if (myGame.CangetMoveRight())
			myGame.m_tool.MoveRight();
	}
	else if (nchar == GLFW_KEY_SPACE) {
		if (myGame.status == GAMEOVER) {
			myGame.status = PRESTART;
			myGame.reset();
		}
		else if (myGame.status == RUN) {
			myGame.status = STOP;
		}
	}
}
```

##### 3.游戏暂停

**很简单，接受一个信息SPACE，转换游戏状态为RUN就行。**

```c++
//处理暂停时的输入
if (myGame.status == STOP ) {
	if (nchar == GLFW_KEY_SPACE) {
		myGame.status = RUN;
	}
}
```

##### 4.游戏结束

**接受一个SPACE信号，把游戏状态转换为PRESTART。**

```c++
//处理结束的操作
//处理结束的操作
if (myGame.status == GAMEOVER) {
		if(nchar==GLFW_KEY_SPACE)
		myGame.reset();
	}
```

##### 5.游戏胜利

**这个比较模糊，大家自由发挥。）**

##### 6.特殊的特殊

**在任何状态下，我们都可以使用esc退出游戏，我们把这个输入设置在普通消息中，为了让消息处理看上去更加啊的完整，我们在普通消息处理中调用特殊消息处理函数，使用特殊消息处理函数来处理除esc以外的所有消息。**

```c++
void Input(unsigned char nchar, int x, int y) {
	if (nchar == GLUT_KEY_ESCAPE) {
		//退出前保存数据
		myGame.GameOver();
		exit(0);
	}
	//全部转化为大写进行处理
	if (nchar >= 'a' && nchar <= 'z')nchar += 'A' - 'a';
	Input((int)nchar, x, y);
}
```

普通消息处理函数

```c++
//简单键盘输入
void Input(unsigned char nchar, int x, int y) {
	if (nchar == GLUT_KEY_ESCAPE) {
		//推出前保存数据
		myGame.GameOver();
		exit(0);
	}
	if (nchar >= 'a' && nchar <= 'z')nchar += 'A' - 'a';
		Input((int)nchar, x, y);
}
``` 特殊的消息处理函数

```c++
void Input( int nchar, int x, int y){
	//处理游戏时的输入
	if (myGame.status == RUN) {	
		if (nchar == GLUT_KEY_UP || nchar == GLFW_KEY_W) {
			myGame.Rotate();
		}
		else if (nchar == GLFW_KEY_S || nchar == GLUT_KEY_DOWN) {
			myGame.Drop();
		}
		else if (nchar == GLFW_KEY_A || nchar == GLUT_KEY_LEFT) {
			if (myGame.CangetMoveLeft())
				myGame.m_tool.MoveLeft();
		}
		else if (nchar == GLFW_KEY_D || nchar == GLUT_KEY_RIGHT) {
			if (myGame.CangetMoveRight())
				myGame.m_tool.MoveRight();
		}
		else if (nchar == GLFW_KEY_SPACE) {
			if (myGame.status == GAMEOVER) {
				myGame.status = PRESTART;
				myGame.reset();
			}
			else if (myGame.status == RUN) {
				myGame.status = STOP;
			}
		}
	}	
	//处理暂停时的输入
	else if (myGame.status == STOP ) {
		if (nchar == GLFW_KEY_SPACE) {
			myGame.status = RUN;
		}
	}
	//处理游戏开始前的输入
	else if (myGame.status == PRESTART) {
		if (nchar == GLFW_KEY_SPACE) {
			myGame.Start();
		}
	}
	//处理结束的操作
	else if (myGame.status == GAMEOVER) {
		if(nchar==GLFW_KEY_SPACE)
		myGame.reset();
	}
	else if (myGame.status == GAMEWIN) {
		if (nchar)exit(0);
	}
}
``` 

**这样，我们的消息处理就完整啦！！（快要做完了！！好激动）**

## 菜单（非必要）

### 创建菜单

**做完上面的内容之后，我觉得我的小游戏还是少了些什么东西，它好像不能存档，它好像没有菜单，它好像很垃圾？？然后我就给它加上了几行代码，使得这个小游戏 更加的有意思了。我们可以在菜单对游戏进行重置，我们可以在提供的三个存档位中进行选择，我们可以在正常退出时保存数据，下次打开自动保存存档又能回到之前的进度！**

### 关于glut的Menu

**首先我们需要做的是创建一个菜单，glut提供的注册函数是glutCreateMenu\(\)**

---

```c++
extern int APIENTRY glutCreateMenu(void (*)(int));
```

**它会返回所创建的菜单的ID，类型是int。**  
**然后是创建这个ID下的菜单列表，使用函数:glutAddMenuEntry\(\)**

---

```c++
extern void APIENTRY glutAddMenuEntry(const char *label, int value);
```

**需要一个执行操作的函数，和一个对应执行的“值”，这个值我们一般使用枚举来提高代码可读性。**  
  
[点击返回问题目录](#back)  
**然后我们可以使用一个菜单的ID去创建一个父菜单，像这样：**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230409192044851-238051188_1726324605716.png)  
**使用函数glutAddSubMenu\(\)**

---

```c++
extern void APIENTRY glutAddSubMenu(const char *label, int submenu);
```

  
[点击返回问题目录](#back)  
**最后，我们需要绑定菜单触发的输入，比如GLUT\_RIGHT\_BUTTON，就是鼠标右键。**

### 响应菜单

**在创建菜单的时候，会将子菜单绑定到一个函数上，这个函数需要接受一个value值，然后处理对应的操作。这里先给出createGLUTMenus函数的定义：**

createGLUTMenus

```c++
void createGLUTMenus() {
	//菜单ID
	int menu,submenu, Savemenu, Loadmenu;
	//设置回调函数processMenuEvents()，获取与之对于的菜单ID
	submenu = glutCreateMenu(processMenuEvents);
	glutAddMenuEntry("Start", RUN);
	glutAddMenuEntry("Reset", PRESTART);
	//以后再做
	//glutAddMenuEntry("Check My Best", CHECKBEST);
	Savemenu = glutCreateMenu(processMenuEvents);
	glutAddMenuEntry("Save1", SAVE1);
	glutAddMenuEntry("Save2", SAVE2);
	glutAddMenuEntry("Save3", SAVE3);
	Loadmenu = glutCreateMenu(processMenuEvents);
	glutAddMenuEntry("Load1", LOAD1);
	glutAddMenuEntry("Load2", LOAD2);
	glutAddMenuEntry("Load3", LOAD3);
	glutAddMenuEntry("LoadAutoSave", LOADAUTOSAVE);
	menu = glutCreateMenu(processMenuEvents);
	//设置父菜单
	glutAddMenuEntry("Stop", STOP);
	glutAddSubMenu("Option", submenu);
	glutAddSubMenu("Save", Savemenu);
	glutAddSubMenu("LoadSave", Loadmenu);
	glutAddMenuEntry("Exit", GAMEOVER);
	//绑定鼠标点击
	glutAttachMenu(GLUT_RIGHT_BUTTON);
}

``` 

**然后我们定义在createGLUTMenus中使用过的函数指针processMenuEvents。在这个函数中，我们对应各个枚举进行实现。**

processMenuEvents

```c++
void processMenuEvents(int option) {
	switch (option) {
	case RUN:
		if (myGame.status == PRESTART)myGame.Start();
		myGame.status = RUN;
		break;
	case GAMEOVER:
		myGame.GameOver();
		myGame.Save("AutoSave.zhywyt");
		exit(0);
		break;
	case PRESTART:
		myGame.status = PRESTART;
		myGame.GameOver();
		myGame.reset();
		//添加重置的操作
		break;
	case STOP:
		if(myGame.status!=PRESTART)
		myGame.status = STOP;
		break;
	}
	if (option >= SAVE1 && option <= SAVE3) {
		if (myGame.getStatus() != PRESTART) {
			int index = option - SAVE1 + 1;
			char FileName[30];
			sprintf(FileName, "Save%d.zhywyt", index);
			string name(FileName);
			if (myGame.Save(name))
				myGame.ChangeStatus(STOP);
		}
	}
	else if (option >= LOAD1 && option <= LOAD3) {
		int index = option - LOAD1 + 1;
		char FileName[30];
		sprintf(FileName, "Save%d.zhywyt", index);
		string name(FileName);
		if(myGame.Load(name))
			myGame.ChangeStatus(STOP);
		else {
			myGame.reset();
			myGame.ChangeStatus(PRESTART);
		}
	}
	else if (option == LOADAUTOSAVE) {
		if(myGame.Load("AutoSave.zhywyt"))
			myGame.ChangeStatus(STOP);
	}
}

``` 

## 存档（非必要）

**前面的菜单里面，有着需要Game类内部实现的存档系统，那么我们来稍微修改一下Game类，为它添加存档的功能。**

### Save函数和Load函数

```c++
bool Save(string FileName);
bool Load(string FileName);
```

**实现：**

Save

```c++
bool Game::Save(string FileName) {
	ofstream ofs(FileName, fstream::out);
	if (ofs) {
		//按照数据顺序来
		ofs << status << " " << clearTimes << " "
			<< zhywyt << " " << _points << " "
			<< PB_points << " " << Diff << " "
			<< PB_Diff << " " << PB << endl;
		ofs << m_tool._type << " " << m_next._type << endl;
		for (int i = 0; i < Row; i++) {
			for (int j = 0; j < Cow; j++)
				ofs << m_map[i][j] << " ";
			ofs << endl;
		}
		return true;
	}
	return false;
}
``` Load

```c++
bool Game::Load(string FileName) {
	ifstream ifs(FileName, fstream::in);
	if (ifs) {
		int Status, m_tool_Type, m_next_Type;
		ifs >> Status >> clearTimes
			>> zhywyt >> _points
			>> PB_points >> Diff
			>> PB_Diff >> PB
			>> m_tool_Type >> m_next_Type;
		for (int i = 0; i < Row; i++)
			for (int j = 0; j < Cow; j++)
				ifs >> m_map[i][j];
		status = GameMode(Status);
		m_tool = Tool(rePx,rePy,ToolType(m_tool_Type));
		m_next = Tool(waitPx, waitPy, ToolType(m_next_Type));
		return true;
	}
	return false;
}
``` 

### 自动存档

**在用户是哟esc进行退出时，和使用exit进行退出时，我们先保存一次游戏的数据，再退出，这样可以让用户在下次进入游戏的时候找回之前忘记保存的存档。我们更新之前的普通消息处理函数：**

```c++
void Input(unsigned char nchar, int x, int y) {
	if (nchar == GLUT_KEY_ESCAPE) {
		//退出前保存数据
		myGame.GameOver();
		//真正的保存数据
		myGame.Save("AutoSave.zhywyt");
		exit(0);
	}
	//全部转化为大写信息处理
	if (nchar >= 'a' && nchar <= 'z')nchar += 'A' - 'a';
		Input((int)nchar, x, y);
}
```

**最后，要注意存档不存在的时候，这里我就没有进行额外的处理了，只是在没有存档的时候不做任何事情。**

>

更新于2023.4.15

## 音乐

**一个游戏不能没有音乐，或者说一个完整的游戏不能没有音乐，所以我还是给我的俄罗斯方块小游戏加上了音乐。**

### irrklang

**因为OpenGL是没有提供音频的接口的，所以我需要使用外部库来实现音乐部分。这里使用的是irrklang音频库，它可以非常方便的使用多种文件的音频。可以在这里找到它的下载链接**  
  
[irrKlang](https://www.ambiera.com/irrklang/downloads.html)**我使用了32位进行实现。下载好后按照之前配置glut的方式配置irrklang**[glut的配置](#glut)

### irrklang使用

**irrklang可以实现3D音效，但是我们这里不需要用到这个高级的方法。我们只使用它的2D效果。主要介绍它的两个类：**

#### ISoundEngine类

**ISoundEngine类允许我们创建一个可以播放音乐的对象，这个对象由函数`createIrrKlangDevice`得到。**

```c++
ISoundEngine* SoundEngine = createIrrKlangDevice();
```

**ISoundEngine类拥有很多的成员函数，我们需要使用的只有两个，分别是：**

```c++
SoundEngine->play2D();
SoundEngine->drop();
//函数原型
virtual ISound* play2D(const char* soundFileName, 
	   bool playLooped = false,
	   bool startPaused = false, 
	   bool track = false,
	   E_STREAM_MODE streamMode = ESM_AUTO_DETECT,
	   bool enableSoundEffects = false) = 0;

```

**drop函数很单纯，就是释放这个ISoundEngine对象的内存，销毁该对象。在程序退出前记得调用这个函数；而play2D这个函数使用了大量的默认形参，所以我们甚至可以简洁的写成：`SoundEngine->play2D("Filename")`这样简单的代码直接播放一首歌曲。它第二个参数的意义是是否进行循环播放，第三个参数的意义是第一次触发是否暂停播放，等待第二次触发再播放，第四个参数是是否返回ISound指针。后面的参数我们用不到了。我们可以得到两种使用方式，分别对应我们的背景音乐和音效。**

```c++
//BackGroundMusic背景音乐
//需要持续播放且进行"track"的的音乐
ISound*BackGroundSound SoundEngine->play2D("filename",GL_TRUE,GL_FALSE,GL_TRUE);
//音效
//只需要当前位置播放一次的音乐
SoundEngine->play2D("filename");
```

**然后我们来讲一下ISound类，它可以对一段音乐的播放进行更加细致的操纵。**

#### ISound类

**ISound类对象的指针由play2D开启第四个参数时返回，得到的ISound对象可以对这首音乐进行操纵，比如暂停、调节音量、释放空间等等。这里我们只需要用到暂停和释放空间就行了。我们用到它的两个成员函数**

```c++
//开启音乐播放
//TRUE暂停
BackGroundMusic->setIsPaused(GL_FLASE);
//销毁音乐，之后置空
BackGroundMusic->drop();
//设置音量（0.0 - 1.0）
RunSound->setVolume(value);
```

2023.4.15更新至此

  
[点击返回问题目录](#back)

## 一个游戏的开发过程主要有哪些呢？

**以下全部都是个人见解，肯定是非常不全面的，但是既然是自己第一个完整的游戏，那么也把整个开发过程的想法说一说。**

### 1.分析游戏对象

**想要做一个游戏，首先我们得知道这个游戏会有哪些对象，先从对象入手。把对象作为我们游戏的最小单元，比如游戏中的NPC，我们可能先剥离所有NPC的共性，然后写出一个基类people类，再people这个类的基础上进行继承，形成新的类，逐渐完善所有的对象类。我觉得这个步骤至关重要，也能理解为什么策划在团体中的重要性了。**

### 2.分析游戏过程

**在我自己的想法中，我还是不能把Game类和过程剥离开，整个Game类的设计还是在进行一种面向过程的编程方式，但是我觉得面向对象的意义其实就是更好的面向过程，我无法想象如何真正意义上的面向对象？我的绘图，我的消息处理，甚至我的Timer计时器，从里到外都透露着面向过程的思想。但是就这一个俄罗斯方块来说，我觉得我的处理还是很正确的，以友元作为回调函数，设置唯一的Game类。但是转念一想，那我的Game类有什么意义呢？认真的思考过后，我认为：这个游戏中对对象的封装止步于Game类的数据维护，剩下的所有事情都是在面向过程。**

### 3.代码实现

**涉及到的知识就很多了，包括C++的编程基础和图形API/库的接口使用。**

# 感谢您的阅读，谢谢！

**有什么问题请大家狠狠的指出，大家的意见都是小白在学习中的一次进步！代码多有不规范的地方还请大家包涵。**

# 代码汇总

[zhywyt](https://github.com/zhywyt/Terix-With-Glut "zhywyt's gitHub")