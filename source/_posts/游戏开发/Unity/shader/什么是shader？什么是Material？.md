---
updated_at: 2025-01-15T20:46:44.354+08:00
edited_seconds: 1450
title: 什么是shader？什么是Material？
date: 2025-01-15T20:46:00
abbrlink: 58283ae7cb2d
categories:
  - 游戏开发
  - Unity
  - Shader
tags:
  - 技术文档
---
首先可以看一下官方文档：[着色器 - Unity 手册](https://docs.unity3d.com/cn/current/Manual/Shaders.html)，好吧我相信也不会有人看它的（不是。
这是一个非常非常浅薄的shader见解，这里我不会讲任何shader graph有关的信息。只讲代码以及渲染思路。

# shader渲染管线

在现代渲染管线中，如果使用光栅化，那么一定离不开顶点着色器(Vertex Shader)和片段着色器(Fragment Shader)。而在unity中有第三种着色器——表面着色器（Surface Shader），表面着色器是Unity提供的一种高级抽象，简化了光照模型的实现。

这里简单地列出三种着色器来讲解他们的作用：
```csharp
// vertex shader
v2f vert(appdata v) {
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex); // 将顶点从模型空间转换到裁剪空间
	o.uv = v.uv; // 传递纹理坐标
    return o;
}
// fragment shader
fixed4 frag(v2f i) : SV_Target {
    fixed4 texColor = tex2D(_MainTex, i.uv); // 采样纹理
	return texColor * _Color; // 返回最终颜色
}
// surface shader
void surf(Input IN, inout SurfaceOutputStandard o) {
    fixed4 c = tex2D(_MainTex, IN.uv_MainTex); // 采样纹理
    o.Albedo = c.rgb; // 设置漫反射颜色
    o.Metallic = _Metallic; // 设置金属度
    o.Smoothness = _Glossiness; // 设置光滑度
}
```


在顶点着色器中，我们需要处理顶点的信息，一般包括顶点位置、纹理坐标。并打包将信息传递给片段着色器，片段着色器是顶点着色器插值的一个中间状态，比如我们需要渲染一条线，那么我们的顶点着色器就是判断点的位置，点的颜色，真正的渲染线上的每一个点由渲染管线插值得到插值后的位置和颜色，并使用片段着色器来计算最后的颜色。所以如果涉及到形变，首先想到修改顶点着色器，因为片段着色器无法修改位置。如果要修改颜色，需要使用片段着色器，最终的计算值由片段着色器来决定。
在一般的渲染管线中我们只需要顶点着色器和片段着色器其实已经足够了，非必要我们一般不使用所谓的surface shader。

# 什么是Material材质？

刚刚我们讲了shader可以做什么，shader就像一个模板一样，它指出了渲染方式。而材质就是一个shader的实例化，每个材质对应一个shader，可以进行不同类型的参数调整。

# shader hello world

我们用一个简单好看的例子来展示shader的力量！
首先我们打开一个Unity项目（随意版本，随意渲染管线，无需PBR）。
首先创建一个标准计算着色器
![[../../../../assets/images/Pasted image 20250115201718.png]]
打开它：
![[../../../../assets/images/QQ_1736943477807.png]]
这里会创建一个简单的反色shader，可以看到里面有两个简单的shader，以及一堆看不懂的东西。不用在意，先来看这两个函数干了什么：
```csharp
v2f vert (appdata v)
{
	v2f o;
	o.vertex = UnityObjectToClipPos(v.vertex);    // 转换顶点坐标到相机坐标系
	o.uv = v.uv;    // 简单地复制uv
	return o;
}
fixed4 frag (v2f i) : SV_Target
{
	fixed4 col = tex2D(_MainTex, i.uv);    // 采样纹理
	col.rgb = 1 - col.rgb;    // 颜色取反
	return col;
}
```
首先是顶点着色器，它将物体的顶点坐标转换到相机坐标系，然后复制顶点的uv。然后片段着色器我们先使用uv坐标在主材质上进行采样，然后将颜色取反，最后输出颜色。其余部分的代码你可以暂时不了解。
然后在unity中再创建一个材质：
![[../../../../assets/images/Pasted image 20250115202302.png]]
并将你的shader拖动到材质上：
![[../../../../assets/images/QQ_1736943831502.png]]
为什么得到了一个黑不溜秋的东西？因为我们的预览中是没有材质的！所以对材质采样会得到空的结构，我们可以给这个材质附上一个图片来测试我们的shader的效果，点击选中你的材质，然后在检查器中你可以看到纹理：
![[../../../../assets/images/QQ_1736943947838.png]]
点击选择，选择一张你喜欢的图片，然后就可以看到预览效果了！
![[../../../../assets/images/QQ_1736944860459.png]]
