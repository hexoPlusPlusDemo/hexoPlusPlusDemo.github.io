---
title: Unity游戏开发学习
date: 2024-09-20T04:54:00
---
短暂的测试过后，我决定使用WIndows进行开发，一是由于Ubuntu的版本太低了，二是因为不便于合作。在Windows下，Unity的安装变得简单而便捷。安装好Unity Hub和Editer以及一些插件后，我创建了自己第一个正式项目。
![](../assets/images/Pasted%20image%2020240920040914.png)
![](../assets/images/Pasted%20image%2020240920040949.png)
如你所见，它的名字叫做`Cursing Otherworld`是一个2d rpg角色扮演游戏。事实上我对Unity可以说是零基础的，C#也几乎没写过，但是C++和python已经很熟练了。这个项目花精力做完能够提升很大的。困难肯定很多，坑肯定有大有小。我希望能在此记录他们。
# 英雄移动&子弹发射

和策划沟通了一下，他们主要的想法是想先看单词攻击这个机制能不能很好的实现。所以我打算先制作英雄的移动和子弹的发射，之后再把子弹换成不同的单词尝试实现他们。
## 英雄移动
要让英雄移动其实是一件比较简单的事情，我们只需要为英雄写一个移动的脚本就可以了：
```scss
// class hero
public float speed;
// function update
if(Input.GetKey(KeyCode.W))
{
	transform.Translate(Vector3.up * speed * Time.deltaTime);
}
if (Input.GetKey(KeyCode.S))
{
	transform.Translate(Vector3.down * speed * Time.deltaTime);
}
if (Input.GetKey(KeyCode.A))
{
	transform.Translate(Vector3.left * speed * Time.deltaTime);
}
if (Input.GetKey(KeyCode.D))
{
	transform.Translate(Vector3.right * speed * Time.deltaTime);
}
```
然后我想实现鼠标点击移动的效果，然后遇到了第一个坑。鼠标的点击位置是三维位置，但是由于我的图层关系，我无法察觉到这个件事情，最后发现英雄的z轴在减小，发现并解决了他。
```scss
// class hero
public Vector3 m_direction = Vector3.left;
// function update
if (Input.GetMouseButton(0))
{
	//只取xy
	Vector3 mousePosition = Input.mousePosition;
	Vector3 worldPosition = Camera.main.ScreenToWorldPoint(mousePosition);
	m_direction = worldPosition - transform.position;
	m_direction.z = 0;
	m_direction.Normalize();
	transform.Translate(m_direction * speed * Time.deltaTime);
}
```
## 子弹发射
完成了英雄的移动，我开始开发子弹发射的功能，我创建了一个简单的精灵用于控制，然后在英雄的脚本中添加了一个`GameObject`成员，取名为`bullet`，这样我们就可以在`Unity`中为其绑定我们想要的精灵。 然后我们需要编写一个按键绑定，用于子弹精灵的生成，暂时不使用对象池。
```scss
// calss hero
public GameObject bullet;
// function update
if (Input.GetKeyDown(KeyCode.Return)){
	GameObject a_bullt = Instantiate(bullet,transform.position,transform.rotation);
	a_bullt.GetComponent<bullet>().direction = m_direction;
}
```
然后我们需要为子弹精灵写一个运动的脚本：
```scss
// class bullet
public float lifeTime=10f;
public float speed = 15f;
public Vector3 direction;
// function update
transform.position += direction * 15f * Time.deltaTime;
// lifetime over
if (lifeTime <= 0){
	Destroy(gameObject);
}else{
	lifeTime -= Time.deltaTime;
}
```
但是会发现我们的子弹的发射并没有附带旋转，它的朝向与运动方向不匹配，于是我们写一个旋转的运动代码。添加在它的初始化里面：
我尝试使用鼠标的`m_direction`来初始化这个角度，然后我就踩了两个坑，第一个是`AWSD`移动时无法进行正确的发射，一个是我应该使用`Quaternion.LookRotation(Vector3.forward, m_direction)`来计算我的旋转，因为子弹默认是`forward`的，测试得到了正确的代码。这部分代码只需要修改`update`函数：
```scss
// class hero
// function update
if(Input.GetKey(KeyCode.W)){
	Vector3 move = Vector3.up * speed * Time.deltaTime;
	transform.Translate(move);
	m_direction += move;
}
if (Input.GetKey(KeyCode.S)){
	Vector3 move = Vector3.down * speed * Time.deltaTime;
	transform.Translate(move);
	m_direction += move;
}
if (Input.GetKey(KeyCode.A)){
	Vector3 move = Vector3.left * speed * Time.deltaTime;
	transform.Translate(move);
	m_direction += move;
}
if (Input.GetKey(KeyCode.D)){
	Vector3 move = Vector3.right * speed * Time.deltaTime;
	transform.Translate(move);
	m_direction += move;
}
if (Input.GetMouseButton(0)){
	//只取xy
	Vector3 mousePosition = Input.mousePosition;
	Vector3 worldPosition = Camera.main.ScreenToWorldPoint(mousePosition);
	m_direction += worldPosition - transform.position;
	m_direction.z = 0;
	m_direction.Normalize();
	transform.Translate(m_direction * speed * Time.deltaTime);
}
m_direction.Normalize();
if (Input.GetKeyDown(KeyCode.Return)){
	GameObject a_bullt = Instantiate(bullet,transform.position,transform.rotation);
	a_bullt.GetComponent<bullet>().direction = m_direction;
	a_bullt.transform.rotation = Quaternion.LookRotation(Vector3.forward, m_direction);
}
```
# 暂停时缓
我们的效果是暂停的时候显示一个输入框，然后玩家可以输入字符，再作为攻击打出。我有一个想法是用时缓代替暂停，这样可以不会有那么生硬的画面表现，也让玩家保持一些紧张感。但是这个时缓的实现我目前没有很好的想法，不可能让一个参数传遍所有的精灵。
!!!
```scss
Time.timeScale = 0.1f;
```
在`Unity`中修改`Time.timeScale`的值可以之间完成时缓的操作，真是太方便了。
将这个值改为`1.0f`就能实现我们需要的不暂停效果，我们可以尝试添加一个词条用于增加缓的效果。

# 移动修复

在简单的测试中，我发现英雄的移动代码有很大的问题，其一是英雄的速度会被两个方向的按键叠加，导致速度翻倍。其次是我们的相机设为了英雄的子期间，这是不合理的，我认为相机应该跟随英雄。

在上面想法的实现过程中遇到了许多问题，今天可以安排进度解决一下。
## 2024-09-21 13:49修改
暂时删除了英雄的转向功能，并使用`Cinemachine`套件实现了正确的相机跟随。对于移动部分暂时先放下了。修复后的代码如下，由于我希望移动的时候鼠标用于选择敌人，所以我设置了键盘移动和鼠标移动互斥的效果：
```scss
/* 移动部分 */
// 只有Normal可以移动
if(status==Status.Normal||status==Status.AutoLocking){
	// 创建新的move可以让之后的m_direction分离开，从而锁定敌人攻击
	Vector3 move = Vector3.zero;
	if(Input.GetKey(KeyCode.W))
	{
		move += Vector3.up;
	}
	if (Input.GetKey(KeyCode.S))
	{
		move += Vector3.down;
	}
	if (Input.GetKey(KeyCode.A))
	{
		move += Vector3.left;
	}
	if (Input.GetKey(KeyCode.D))
	{
		move += Vector3.right;
	}
	// 如果move为空则才使用鼠标移动
	if (move==Vector3.zero&&Input.GetMouseButton(0))
	{
		//只取xy保证在2d平面移动
		Vector3 direction = Camera.main.ScreenToWorldPoint(Input.mousePosition) - transform.position;
		direction.z = 0;
		direction.Normalize();
		move += direction;
	}
	move.Normalize();
	m_direction = move;
	transform.Translate(move * speed * Time.deltaTime);
}
```

# 索敌系统
首先为玩家添加一个索敌指示器，我随便创建了一个精灵来实现它，将精灵添加给英雄（非必要，我认为方便查找），然后在英雄的脚本中添加一个`GameObject`，并绑定该指示器。
然后我们需要准备检索敌人的方法，这里使用`tag`检索，为敌人添加`Enemy`作为`tag`，这样可以高效地查找到敌人。并编写一个草率的状态系统（这个系统没有细分，非常差劲）：
```scss
// in class hero
public enum Status : int{
	AutoLocking,        //自动索敌中
	Attacking,          //攻击状态
	UIing,              //UI状态
	Normal              //正常状态
}
```
由于我们需要控制精灵的出现与否，我们需要添加组件
```scss
// in file hero.cs
using UnityEngine.UI;
```
然后我们可以通过设置该精灵的出现与否以及位置来标志我们的索敌位置。接下来就是实现代码：
```scss
/* 锁定敌人 */
// 自动检索检索敌人开关
if (Input.GetKeyDown(KeyCode.Tab)){
	if(status == Status.AutoLocking){
		status = Status.Normal;
		lockedEnemy = null;
	}else{
		status = Status.AutoLocking;
	}
}
// 注意切换之前需要取消上一个敌人的锁定标记
LockedLabel.GetComponent<Renderer>().enabled = false;
if(lockedEnemy == null&&status == Status.AutoLocking){
	// 这个if我没有把为空判断去掉，提高可读性。
	lockedEnemy = GameObject.FindWithTag("Enemy");
}
// 手动检索敌人比自动优先级高
if(Input.GetMouseButtonDown(0)){
	// 检查Input.mousePosition位置是否有敌人被选中
	RaycastHit2D hit = Physics2D.Raycast(Camera.main.ScreenToWorldPoint(Input.mousePosition), Vector2.zero);
	if (hit.collider != null && hit.collider.CompareTag("Enemy"))
	{
		// 如果成功了应该关闭自动检索。修改：这里我觉得可以修改自动检索的方式来调整，如果目标变为空则重新索引。
		// status = Status.Normal;
		lockedEnemy = hit.collider.gameObject;
	}
}
if(lockedEnemy!=null){
	// 调整朝向
	m_direction = lockedEnemy.transform.position - transform.position;
	// 开启锁定标记显示
	// 让LockedLabel的位置和lockedEnemy的位置相同
	LockedLabel.transform.position = lockedEnemy.transform.position;
	LockedLabel.GetComponent<Renderer>().enabled = true;
}
```
接下来我需要为物体添加碰撞体积，并开始写子弹击中的效果。
# 碰撞
为精良添加`Polygon Colider 2D`组件 ，可以让物体使用多边形骨骼。暂时使用这个简单的骨骼。
然后我希望为子弹碰撞添加伤害，将bullet的`poylogon collider 2d`设置为触发器，然后在脚本中通过`OnCollisionEnter`函数中检测碰撞。注意添加`using UnityEngine.PolygonCollider2D;`
但是由于我物体的移动并没有使用刚体的逻辑，所以我前面的移动逻辑需要重新写。
# 文本攻击
我添加了两个文本框分别用于输入和显示，输入需要一个基础的输入框，但是这个输入框组件无法进行高亮展示，于是叠加了另一个`TextMeshPro`组件用于显示最后的输入，将文本组件隐藏，但是在`TMp`之上，这样可以保证玩家输入的同时能够看到被程序修改后的文本，比如简单的：
```scss
// 绑定输入的组件
public GameObject AttackInputUI;
// 绑定TMp组件
public GameObject AttackInputShow;
public TextMeshPro AttackOutputText;

// 这个是textmeshpro的，用来显示用户输入的攻击指令渲染后的样子


// Start
// 通过绑定的TMp组件来获取它的文本组件，用于修改TMp上的富文本
AttackOutputText = AttackInputShow.GetComponent<TextMeshPro>();
```

下面是一个简单的例子，没有使用任何本地化内容，只是把关键词替换为了带颜色的样式，在`TMp`中可以使用更过的效果，
```scss
if(status == Status.Attacking){
	// TODO: 按照输入显示攻击
	// 获取用户当前输入
	string input = AttackInputUI.GetComponent<InputField>().text;
	if(input.Length > 0){
		// 检查输入中是否存在 “笨蛋”
		// 防止循环检测
		AttackOutputText.text = input;
		if (input.Contains("笨蛋")){
			// 创建对应的攻击实例
			// 高亮文本中的“笨蛋”
			AttackOutputText.text = input.Replace("笨蛋", "<color=red>笨蛋</color>");
			// 系统日志输出
			Debug.Log("你刚刚输入了“笨蛋”");
		}
	}
	else{
		AttackOutputText.text = "请输入攻击指令";
	}
}
```
## TextMeshPro的效果

### 字体`<font>`

通过`<font="fontAssetName">`标签可以修改字体，我们还可以使用`material`属性在同一种字体中切换不同的材质，_font_和_material_资源必须放置在 `TextMesh Pro -> Resources -> Fonts&Materials`文件夹中。
```scss
Would you like <font="Impact SDF">a different font?</font> or just <font="NotoSans" material="NotoSans Outline">a different material?
```

### 字宽`<font-weight>`
可以设置字宽的数值，但是需要字体支持。

### 渐变 `<gradient>`
```scss
Apply<b>
<gradient="Yellow to Orange - Vertical">any
<gradient="Light to Dark Green - Vertical">gradient
<gradient="Blue to Purple - Vertical">preset</gradient>
</b>to your text
```
 这个很有意思，可以尝试。但是在使用渐变色的时候，会和文本原来的颜色进行叠加，所以可以先使用`<color>`将文本设置为白色，再使用渐变色获得纯正的渐变色。
### Style`<style>`
可以使用预设置的样式来直接调用，我尝试创建一个样式：
![](../assets/images/Pasted%20image%2020240926111108.png)
找到该组件，点击打开检查器，就可以开始添加样式了。外面可以用这个组件来添加外面需要使用固定样式展示的文本。这里尝试了一个简单的样式：
![](../assets/images/Pasted%20image%2020240926111224.png)
它的效果如下：
![](../assets/images/Pasted%20image%2020240926111301.png)
如果还需要其他的特效之类的可能需要美术的帮助了。
## 如何创建这样的文本精灵用于攻击？
和策划沟通了，说是应该用美术来替代。那么就很容易实现了，本质上就是不同的子弹。暂时将此功能放置一旁。

# 寻路部分
简单的直线索敌已经满足不了我们的需求了，我们需要使用`PathFinder`组件来实现更加智能的索敌。同样的我认为这部分可以用于我们的点击移动的寻路工作中，于是这里我会同时记录敌人锁定人物和我们的英雄点击移动两部分。
## 敌人寻路
我们首先安装`PathFinder`组件：[astar](https://arongranberg.com/astar/download)
这个组件的名字其实叫做`A*`就是那个寻路算法的意思，我们需要用到它的两个核心组件叫做`Seeker`，这个组件可以提供一个自动寻路的算法，并返回路径。

### 定义网格
首先我们需要在场景中创建一个空物体，并挂载`PathFinder`组件，然后设置为2d场景，并将我们的tilemap的图层给设置为障碍图层，最后使用`Scan`完成地图网格定义。
有了地图的信息，我们就可以开始各种寻路了。首先是敌人的寻路，我们可以简单的使用三个脚本完成这个操作。
### 目标寻路
设置一个方形精灵，为它添加三个脚本：
- Seeker
- AI Path
- AI Destination Setter
然后为`AI Path`设置为二维寻路、固定z轴、取消重力

为`AI Destination Setter`组件添加跟踪对象。就可以简单的实现非常聪明的人机了。但是这个人机不能满足我们的需求，所以我自己调用它的一些API来实现更高级的操作，比如寻路的时候播放我们的动画等等。
### 自定义寻路
我们自定义寻路只需要`Seeker`一个组件就可以了，为我们的`Enemy`对象添加组件`Skeer`后，在脚本中写入：
```scss
using PathFinding;

// in class
public Seeker seeker;

// in Start()
seeker = Gercomponent<Seeker>();

// in Update()
seeker.StartPath(transform.position, Target, OnPathComplete);

// in class
public void OnPathComplete(Path p){
	Debug.Log("There is error?"+ p.error);
	if(!p.error){
		pathPointLists = p.vectorPath;
		currentPathIndex = 0;
	}
}
```
然后就可以使用`currentPathIndex`来索引路径了。使用`p.Count`可以得到当前路径的检查点个数。通过这些代码的组合，我们得到了一个完备的敌人追踪功能。我们还可以设置追踪的距离、追踪路径更新时间等等高级操作。这里就不一一细讲了。
## 英雄寻路
英雄寻路，我目前只完成了直线寻路，`A*`明天再写吧。今天收获满满，还提交了一个版本在仓库了。目前提交的版本使用当前日期，如果有重大进度再使用日志进行标记。