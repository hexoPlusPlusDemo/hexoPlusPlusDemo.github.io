---
title: games101 HomeWork3
date: '2023-07-27 14:21'
abbrlink: 55574
tags:
categories:
  - CG
  - games101
---

<!--more-->

# Games101 HomeWork3

## 导航

[导航](https://www.cnblogs.com/zhywyt/p/17576370.html)

## 作业要求

**第三次作业才是真正上强度的作业，作业要求和质量都特别高，先来看看所有的要求：**

- **1 . 修改函数rasterize\_triangle\(const Triangle\& t\) in rasterizer.cpp: 在此处实现与作业 2 类似的插值算法，实现法向量、颜色、纹理颜色的插值。**
- **2 . 修改函数 get\_projection\_matrix\(\) in main.cpp: 将你自己在之前的实验中实现的投影矩阵填到此处，此时你可以运行./Rasterizer output.png normal来观察法向量实现结果。**
- **3 . 修改函数 phong\_fragment\_shader\(\) in main.cpp: 实现 Blinn-Phong 模型计算 Fragment Color.**
- **4 . 修改函数 texture\_fragment\_shader\(\) in main.cpp: 在实现 Blinn-Phong的基础上，将纹理颜色视为公式中的 kd，实现 Texture Shading FragmentShader.**
- **5 . 修改函数 bump\_fragment\_shader\(\) in main.cpp: 在实现 Blinn-Phong 的基础上，仔细阅读该函数中的注释，实现 Bump mapping.**
- **6 . 修改函数 displacement\_fragment\_shader\(\) in main.cpp: 在实现 Bumpmapping 的基础上，实现 displacement mapping.**  
  `提高题`
- **7 .尝试更多模型**
- **8 .双线性纹理插值**  
  不要慌张，一个一个来。先看第一题

### rasterize\_triangle中的插值

**我们在第二题2x2的超采样的基础上进行，先看看题目的提示：**

rasterize\_triangle 函数与你在作业2 中实现的内容相似。不同之处在于被  
设定的数值将不再是**常数**，而是按照 Barycentric Coordinates 对法向量、颜  
色、纹理颜色与底纹颜色\(Shading Colors\) 进行插值。回忆我们上次为了计算  
z value 而提供的**\[alpha, beta, gamma\]**，这次你将需要将其应用在**其他参  
数**的插值上。你需要做的是**计算插值后的颜色**，并将Fragment Shader 计算得  
到的颜色写入 framebuffer，这要求你**首先使用插值得到的结果设置 fragment  
shader payload**，并**调用 fragment shader** 得到计算结果。  
**可以看见，这里基本给出了插值的操作步骤，这里对一个重心坐标做一个解释：**

#### 重心坐标（Barycentric Coordinates）

**给定三角形的三点坐标A, B, C，该平面内一点\(x,y\)可以写成这三点坐标的线性组合形式，即 \\\(\(x,y\)=\\alpha A+\\beta B+\\gamma C\\\) 并且有\\\(\\alpha + \\beta +\\gamma =1\\\)点\\\(\(\\alpha ,\\beta ,\\gamma \)\\\)就是这个点的重心坐标。关于重心坐标的求法，这里直接给出代码，不做推导：**

```c
//重心坐标的求解
static std::tuple<float, float, float> computeBarycentric2D(float x, float y, const Vector4f* v){
    float c1 = (x*(v[1].y() - v[2].y()) + (v[2].x() - v[1].x())*y + v[1].x()*v[2].y() - v[2].x()*v[1].y()) / (v[0].x()*(v[1].y() - v[2].y()) + (v[2].x() - v[1].x())*v[0].y() + v[1].x()*v[2].y() - v[2].x()*v[1].y());
    float c2 = (x*(v[2].y() - v[0].y()) + (v[0].x() - v[2].x())*y + v[2].x()*v[0].y() - v[0].x()*v[2].y()) / (v[1].x()*(v[2].y() - v[0].y()) + (v[0].x() - v[2].x())*v[1].y() + v[2].x()*v[0].y() - v[0].x()*v[2].y());
    float c3 = (x*(v[0].y() - v[1].y()) + (v[1].x() - v[0].x())*y + v[0].x()*v[1].y() - v[1].x()*v[0].y()) / (v[2].x()*(v[0].y() - v[1].y()) + (v[1].x() - v[0].x())*v[2].y() + v[0].x()*v[1].y() - v[1].x()*v[0].y());
    return {c1,c2,c3};
}
```

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230724150810522-1121172651_1726324407642.png)

#### 插值

**有了重心公式，就可以对各个属性进行插值了，先写一个工具函数`这里框架给出了，直接调用就好`，来计算各种插值：**

```c
//三维向量版本，颜色、法线、view_pos
static Eigen::Vector3f interpolate(float alpha, float beta, float gamma, const Eigen::Vector3f& vert1, const Eigen::Vector3f& vert2, const Eigen::Vector3f& vert3, float weight)
{
    return (alpha * vert1 + beta * vert2 + gamma * vert3) / weight;
}
//二维向量版本，用于纹理坐标
static Eigen::Vector2f interpolate(float alpha, float beta, float gamma, const Eigen::Vector2f& vert1, const Eigen::Vector2f& vert2, const Eigen::Vector2f& vert3, float weight)
{
    auto u = (alpha * vert1[0] + beta * vert2[0] + gamma * vert3[0]);
    auto v = (alpha * vert1[1] + beta * vert2[1] + gamma * vert3[1]);
    u /= weight;
    v /= weight;
    return Eigen::Vector2f(u, v);
}
```

**然后就是插值的实现了：**

```c
auto[alpha, beta, gamma] = computeBarycentric2D(i+0.5f, j+0.5f, t.v);
auto interpolated_color=interpolate(alpha,beta,gamma,t.color[0],t.color[1],t.color[2],1);
auto interpolated_normal=interpolate(alpha,beta,gamma,t.normal[0],t.normal[1],t.normal[2],1).normalized();
auto interpolated_shadingcoords=interpolate(alpha,beta,gamma,view_pos[0],view_pos[1],view_pos[2],1);
//二维版本
auto interpolated_texcoords=interpolate(alpha,beta,gamma,t.tex_coords[0],t.tex_coords[1],t.tex_coords[2],1);
```

**最后调用`fragment_shader`计算最后的颜色值**

```c
payload.view_pos = interpolated_shadingcoords;
auto pixel_color = fragment_shader(payload);
// check zbuff
set_pixel(Eigen::Vector2i(i,j),pixel_color*IsInTriangleCount/4.0f);
```

### get\_projection\_matrix\(\) 投影矩阵

**前面提过了，这里只给出代码：**

```c
Eigen::Matrix4f get_projection_matrix(float eye_fov, float aspect_ratio, float zNear, float zFar)
{
    Eigen::Matrix4f projection = Eigen::Matrix4f::Identity();
    eye_fov=eye_fov/180*MY_PI;
    projection<<1/(aspect_ratio*tan(eye_fov/2.0f)) ,0,0,0,
                0,1/tan(eye_fov/2.0f),0,0,
                0,0,-(zFar+zNear)/(zFar-zNear),2*zFar*zNear/(zNear-zFar),
                0,0,-1,0;
    return projection;
}
```

#### 运行 `./Rasterizer normal.png normal`

normal.png  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230724153730332-1148351579_1726324407642.png)

### phong\_fragment\_shader\(\) 光照模型

**接下来需要实现的是Bline-Pong光照系统，首先来回忆一下Bline-Pong的操作步骤**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230724154952168-2123046406_1726324422982.png)

#### 环境色Ambient

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230724155154637-1147583584_1726324422982.png)

#### 漫反射Diffuse

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230724155045414-446559460_1726324422982.png)

#### 镜面反射Specular

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230724155117823-1687347092_1726324422982.png)

#### 代码实现（看注释）

**解释一下一些操作**

 -    **Eigen::Vector3f::cwiseProduct 返回两个矩阵（向量）同位置的元素分别相乘的新矩阵（向量）。**
 -    **std::pow\(x,n\)返回 \\\(x\^n\\\)**

```c
//phong_fragment_shader

Eigen::Vector3f LightDir=light.position-point;
Eigen::Vector3f ViewDir=eye_pos-point;
//r ^ 2
float d=LightDir.dot(LightDir);
Eigen::Vector3f H=(LightDir.normalized()+ViewDir.normalized()).normalized();
//Ambient
Eigen::Vector3f Ambient= ka.cwiseProduct(amb_light_intensity);
float LdotN=(normal.normalized()).dot(LightDir.normalized());
float NdotH=(H.normalized()).dot(normal.normalized());
//Diffuse
Eigen::Vector3f Diffuse= std::max( LdotN , 0.0f)*kd.cwiseProduct(light.intensity/d);
//Specular
Eigen::Vector3f Specular= std::pow(std::max( NdotH , 0.0f),150)*ks.cwiseProduct(light.intensity/d);
result_color+=Ambient+Diffuse+Specular;
```

#### 运行 `./Rasterizer phong.png phong`

**看看，我们的小牛又光滑了许多**  
phong.png  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230724164122063-449571494_1726324422982.png)

### texture\_fragment\_shader\(\) 纹理贴图

**在基础任务中，纹理映射只需要在phong的基础上，把颜色换成纹理坐标对应的颜色就好了，在texture类中，框架已经实现了getColor函数，我们只需要在有纹理的时候调用getColor方法获取对应的颜色就好。**

```c
//texture_fragment_shader函数
    if (payload.texture)
    {
	 	return_color=payload.texture->getColor(payload.tex_coords.x(),payload.tex_coords.y());
    }
//getColor函数（框架已实现）
    Eigen::Vector3f getColor(float u, float v)
    {
        auto u_img = u * width;
        auto v_img = (1 - v) * height;
        auto color = image_data.at<cv::Vec3b>(v_img, u_img);
        return Eigen::Vector3f(color[0], color[1], color[2]);
    }
```

#### 运行`./Rasterizer texture.png texture`

**如果你做对了这一步，那么你make之后使用上面的指令应该能得到这样的结果:**  
texture.png  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230727142426702-454027515_1726324439052.png)

### bump\_fragment\_shader\(\) 凹凸\(法线\)贴图

**这一步天坑，我大概卡在这里改了两个小时的代码，每次跑出来都是段错误！！结果却不是算法问题，我哭死。在我几乎崩溃的时候，还是发现了这个小问题，纹理坐标的在边界的时候可能导致超出1.0,这个时候应该对其进行边界处理，防止数组越界。**  
**关于凹凸贴图的实现，照着提示做就好了，不会有什么问题。**

```c
//错误代码
    float x=normal.x(),y=normal.y(),z=normal.z();
    Vector3f t =Vector3f(x*y/sqrt(x*x+z*z),sqrt(x*x+z*z),z*y/sqrt(x*x+z*z));
    Vector3f b = normal.cross(t);
    Eigen:Matrix3f TBN ;
    TBN<<t.x(),b.x(),normal.x(),
         t.y(),b.y(),normal.y(),
         t.z(),b.z(),normal.z();
    float u=payload.tex_coords.x();
    float v=payload.tex_coords.y();
    float w=payload.texture->width;
    float h=payload.texture->height;
    float dU = kh * kn * (payload.texture->getColor(u+1/w,v).norm()-payload.texture->getColor(u,v).norm());
    float dV = kh * kn * (payload.texture->getColor(u,v+1/h).norm()-payload.texture->getColor(u,v).norm());
    Vector3f ln = Vector3f(-dU, -dV, 1);
    Eigen::Vector3f result_color = {0, 0, 0};
    result_color = (TBN * ln).normalized();
    return result_color * 255.f;
//正确代码
Eigen::Vector3f bump_fragment_shader(const fragment_shader_payload& payload)
{
    static long int numb=1;
    std::cout<<"bump_fragment_shader"<<numb++<<std::endl;
    Eigen::Vector3f ka = Eigen::Vector3f(0.005, 0.005, 0.005);
    Eigen::Vector3f kd = payload.color;
    Eigen::Vector3f ks = Eigen::Vector3f(0.7937, 0.7937, 0.7937);
    auto l1 = light{{20, 20, 20}, {500, 500, 500}};
    auto l2 = light{{-20, 20, 0}, {500, 500, 500}};
    std::vector<light> lights = {l1, l2};
    Eigen::Vector3f amb_light_intensity{10, 10, 10};
    Eigen::Vector3f eye_pos{0, 0, 10};
    float p = 150;
    Eigen::Vector3f color = payload.color; 
    Eigen::Vector3f point = payload.view_pos;
    Eigen::Vector3f normal = payload.normal;
    float kh = 0.2, kn = 0.1;

    // TODO: Implement bump mapping here
    // Let n = normal = (x, y, z)
    // Vector t = (x*y/sqrt(x*x+z*z),sqrt(x*x+z*z),z*y/sqrt(x*x+z*z))
    // Vector b = n cross product t
    // Matrix TBN = [t b n]
    // dU = kh * kn * (h(u+1/w,v)-h(u,v))
    // dV = kh * kn * (h(u,v+1/h)-h(u,v))
    // Vector ln = (-dU, -dV, 1)
    // Normal n = normalize(TBN * ln)
    float x=normal.x(),y=normal.y(),z=normal.z();
    Vector3f t =Vector3f(x*y/sqrt(x*x+z*z),sqrt(x*x+z*z),z*y/sqrt(x*x+z*z));
    Vector3f b = normal.cross(t);
    Eigen:Matrix3f TBN ;
    TBN<<t.x(),b.x(),normal.x(),
         t.y(),b.y(),normal.y(),
         t.z(),b.z(),normal.z();
    float u=payload.tex_coords.x();
    float v=payload.tex_coords.y();
    float w=payload.texture->width;
    float h=payload.texture->height;
	
	//这里多一步防止越界的操作使用std::clamp(x , l , r);来保证数值在l 到 r之间
    float dU = kh * kn * (payload.texture->getColor(std::clamp(u+1/w, 0.0f, 1.0f),v).norm()-payload.texture->getColor(u,v).norm());
    float dV = kh * kn * (payload.texture->getColor(u,std::clamp(v+1/h, 0.0f, 1.0f)).norm()-payload.texture->getColor(u,v).norm());
    Vector3f ln = Vector3f(-dU, -dV, 1);
    Eigen::Vector3f result_color = {0, 0, 0};
    result_color = (TBN * ln).normalized();
    return result_color * 255.f;
}

```

#### 运行`./rasterizer bump.png bump`

bump.png  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230727160448722-329949569_1726324439052.png)

### displacement\_fragment\_shader\(\) 位移贴图

**位移贴图与凹凸\(法线\)贴图有所不同,凹凸贴图不会影响网格的实际多边形性质，只会影响在平面上计算光照的方式。位移贴图（常听到的置换贴图有点勉强），可以让模型表面产生一定的位移变化。（注意跟Bump凹凸贴图的区别，它可以实质性地改变模型的面数，而Bump凹凸贴图并没有实质性地改变模型面数）\\\(\^\{\[1\]\}\\\)**  
**那么该怎么做位移贴图呢？最关键的一步就是位移了：**

```c
    point += kn*normal*payload.texture->getColor(u,v).norm();
```

**除了这步，就是一个缝合了法线贴图和phong模型的着色方法。说实话，这里还真不是很懂，但是照着注释做确实能的要想要的结果。**

```c
Eigen::Vector3f displacement_fragment_shader(const fragment_shader_payload& payload)
{
    Eigen::Vector3f ka = Eigen::Vector3f(0.005, 0.005, 0.005);
    Eigen::Vector3f kd = payload.color;
    Eigen::Vector3f ks = Eigen::Vector3f(0.7937, 0.7937, 0.7937);

    auto l1 = light{{20, 20, 20}, {500, 500, 500}};
    auto l2 = light{{-20, 20, 0}, {500, 500, 500}};

    std::vector<light> lights = {l1, l2};
    Eigen::Vector3f amb_light_intensity{10, 10, 10};
    Eigen::Vector3f eye_pos{0, 0, 10};

    float p = 150;

    Eigen::Vector3f color = payload.color; 
    Eigen::Vector3f point = payload.view_pos;
    Eigen::Vector3f normal = payload.normal;

    float kh = 0.2, kn = 0.1;
    
    // TODO: Implement displacement mapping here
    // Let n = normal = (x, y, z)
    // Vector t = (x*y/sqrt(x*x+z*z),sqrt(x*x+z*z),z*y/sqrt(x*x+z*z))
    // Vector b = n cross product t
    // Matrix TBN = [t b n]
    // dU = kh * kn * (h(u+1/w,v)-h(u,v))
    // dV = kh * kn * (h(u,v+1/h)-h(u,v))
    // Vector ln = (-dU, -dV, 1)
    // Position p = p + kn * n * h(u,v)
    // Normal n = normalize(TBN * ln)
    float x=normal.x(),y=normal.y(),z=normal.z();
    Vector3f t =Vector3f(x*y/sqrt(x*x+z*z),sqrt(x*x+z*z),z*y/sqrt(x*x+z*z));
    Vector3f b = normal.cross(t);
    Eigen:Matrix3f TBN ;
    TBN<<t.x(),b.x(),normal.x(),
         t.y(),b.y(),normal.y(),
         t.z(),b.z(),normal.z();
    float u=payload.tex_coords.x();
    float v=payload.tex_coords.y();
    float w=payload.texture->width;
    float h=payload.texture->height;
    float dU = kh * kn * (payload.texture->getColor(std::clamp(u+1/w,0.f,1.f),v).norm()-payload.texture->getColor(u,v).norm());
    float dV = kh * kn * (payload.texture->getColor(u,std::clamp(v+1/h,0.f,1.f)).norm()-payload.texture->getColor(u,v).norm());
    Vector3f ln = Vector3f(-dU, -dV, 1);
	//位移
    point += kn*normal*payload.texture->getColor(u,v).norm();
    Eigen::Vector3f result_color = {0, 0, 0};
    normal = (TBN * ln).normalized();


    Eigen::Vector3f ViewDir=eye_pos-point;
    for (auto& light : lights)
    {
        // TODO: For each light source in the code, calculate what the *ambient*, *diffuse*, and *specular* 
        // components are. Then, accumulate that result on the *result_color* object.
        Eigen::Vector3f LightDir=light.position-point;
        float d=LightDir.dot(LightDir);
        Eigen::Vector3f H=(LightDir.normalized()+ViewDir.normalized()).normalized();
        Eigen::Vector3f Ambient= ka.cwiseProduct(amb_light_intensity);
        float LdotN=(normal.normalized()).dot(LightDir.normalized());
        float NdotH=(H.normalized()).dot(normal.normalized());
        Eigen::Vector3f Diffuse= std::max( LdotN , 0.0f)*kd.cwiseProduct(light.intensity/d);
        Eigen::Vector3f Specular= std::pow(std::max( NdotH , 0.0f),150)*ks.cwiseProduct(light.intensity/d);
        result_color+=Ambient+Diffuse+Specular;
    }
    return result_color * 255.f;
}
```

#### 运行`./Rasterizer displacement.png displacement`

displacement.png  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230727170304928-975418181_1726324439052.png)

### 双线性插值

**这个虽然简单，但是我们也来讲一下具体实现：**  
**函数原型如下**

```c
Eigen::Vector3f getColorBilinear(float u,float v);
```

**根据下面这张原理图，我们来一步步实现**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230727143136416-982621662_1726324439052.png)  
**第一步，将`u`和`v`限制在\\\(0-1\\\)**

```c
	u = std::clamp(u, 0.0f, 1.0f);
	v = std::clamp(v, 0.0f, 1.0f);
```

**把比例转化为纹理坐标，并计算相邻的四个像素点**

```c
	auto u_img = u * width;
	auto v_img = (1 - v) * height;
	float uMax=std::min((float)width,std::ceil(u_img));
	float uMin=std::max(0.0f,std::floor(u_img));
	float vMax=std::min((float)height,std::ceil(v_img));
	float vMin=std::max(0.0f,std::floor(v_img));
```

**其中**

 -    `ceil()`向上去整
 -    `floor()`向下取整  
  **记录四个点的颜色**

```c
	//Up Left Point
	auto colorUL = image_data.at<cv::Vec3b>(vMax,uMin );
	//Up Right Point
	auto colorUR = image_data.at<cv::Vec3b>(vMax, uMax);
	//Down Left Point
	auto colorDL = image_data.at<cv::Vec3b>(vMin, uMin);
	//Down Right Point
	auto colorDR = image_data.at<cv::Vec3b>(vMin, uMax);
```

**单线性插值**

```c
	float uLerpNum=(u_img-uMin)/(uMax-uMin);
	float vLerpNum=(v_img-vMin)/(vMax-vMin);
	//U Up Lerp
	auto colorUp_U_Lerp=uLerpNum*colorUL+(1-uLerpNum)*colorUR;
	//U Down Lerp
	auto colorDown_U_Lerp= uLerpNum*colorDL+(1-uLerpNum)*colorDR;
```

**再进行一次插值**

```c
	//V Lerp
	auto color = vLerpNum*colorDown_U_Lerp+(1-vLerpNum)*colorUp_U_Lerp;
```

**并修改texture\_fragment\_shader中获取材质的语句**

```c
Eigen::Vector3f texture_fragment_shader(const fragment_shader_payload& payload)
{
    Eigen::Vector3f return_color = {0, 0, 0};
    if (payload.texture)
    {
        // TODO: Get the texture value at the texture coordinates of the current fragment
		//双线性插值
        return_color=payload.texture->getColorBilinear(payload.tex_coords.x(),payload.tex_coords.y());
    }
    Eigen::Vector3f texture_color;
    texture_color << return_color.x(), return_color.y(), return_color.z();

    Eigen::Vector3f ka = Eigen::Vector3f(0.005, 0.005, 0.005);
    Eigen::Vector3f kd = texture_color / 255.f;
    Eigen::Vector3f ks = Eigen::Vector3f(0.7937, 0.7937, 0.7937);

    auto l1 = light{{20, 20, 20}, {500, 500, 500}};
    auto l2 = light{{-20, 20, 0}, {500, 500, 500}};

    std::vector<light> lights = {l1, l2};
    Eigen::Vector3f amb_light_intensity{10, 10, 10};
    Eigen::Vector3f eye_pos{0, 0, 10};

    float p = 150;

    Eigen::Vector3f color = texture_color;
    Eigen::Vector3f point = payload.view_pos;
    Eigen::Vector3f normal = payload.normal;

    Eigen::Vector3f result_color = {0, 0, 0};

    for (auto& light : lights)
    {
        // TODO: For each light source in the code, calculate what the *ambient*, *diffuse*, and *specular*
        // components are. Then, accumulate that result on the *result_color* object.
        Eigen::Vector3f LightDir=light.position-point;
        Eigen::Vector3f ViewDir=eye_pos-point;
        float d=LightDir.dot(LightDir);
        Eigen::Vector3f H=(LightDir.normalized()+ViewDir.normalized()).normalized();
        Eigen::Vector3f Ambient= ka.cwiseProduct(amb_light_intensity);
        float LdotN=(normal.normalized()).dot(LightDir.normalized());
        float NdotH=(H.normalized()).dot(normal.normalized());
        Eigen::Vector3f Diffuse= std::max( LdotN , 0.0f)*kd.cwiseProduct(light.intensity/d);
        Eigen::Vector3f Specular= std::pow(std::max( NdotH , 0.0f),150)*ks.cwiseProduct(light.intensity/d);
        result_color+=Ambient+Diffuse+Specular;
    }

    return result_color * 255.f;
}
```

### 使用其他模型

**由于凹凸贴图和位移贴图是需要法线贴图的，所以只有spot模型（小牛）是可以进行的，其他的模型都进行不料，那么我们就不做了。但是我在做纹理映射的时候，大抵是发生了奇怪的事情，没有办法很好的作出纹理贴图。那我摆栏了，效果如下：挺差的，我也解决不了了**  
**我自己做了一些指令，具体如下：**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230728150251896-1866767253_1726324439052.png)

#### bunny

`./Rasterizer \- normal bunny 2`  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230728151501544-1113996278_1726324449461.png)  
`./Rasterizer \- phong bunny 2`  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230728151503837-676167363_1726324449461.png)

#### Crate

`./Rasterizer \- normal crate`  
**具体为什么画出来这个样子我也不清楚，搞了一下午，摆栏了**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230728152651037-615293228_1726324449461.png)  
`./Rasterizer \- phong crate`  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230728152836476-1104393584_1726324449461.png)  
**我本来以为是因为摄像机的位置，然后我调整了摄像机的位置，又画出了这样的图片：这下没办法了**  
`./Rasterizer \- phong crate 20`  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230728153017561-293420920_1726324449461.png)  
`./Rasterizer \- texture crate`  
**贴图也不知道为什么非常奇怪，罢了罢了**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230728153127067-1582248841_1726324464669.png)

#### cube

`./Rasterizer \- normal cube`  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230728153255697-793645420_1726324464669.png)  
**还可以移动摄像机到\(0,0,-10\)去看看 ~~\(其实这个成像是错误的，因为只是移动了eye\_pos，深度信息的计算并没有重新计算，所以深度还是以\(0,0,10\)来计算的。看到图像就很奇怪\)~~**  
`./Rasterizer \- normal cube \-10`  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230728153344003-1666282860_1726324464669.png)  
`./Rasterizer \- phong cube`  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230728153751868-999380803_1726324464669.png)  
`./Rasterizer \- texture cube`  
**~~就乐呵乐呵吧~~**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230728153846947-867937133_1726324464669.png)

#### rock

`./Rasterizer \- normal rock 20`  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230728154200513-633371835_1726324474344.png)  
**rock这个模型，如果用10的话，会超出视口范围，但是getIndex函数并没有对其进行该有的操作，导致会出现段错误，这里调远摄像机的位置来防止出现段错误。**

```c
int rst::rasterizer::get_index(int x, int y)
{
    return (height-y)*width + x;
}
```

`./Rasterizer \- phong rock 20`  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230728154237464-1535985916_1726324474344.png)  
`./Rasterizer \- texture rock 20`  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230728154310832-172869686_1726324474344.png)

#### main函数源代码

```c
int main(int argc, const char** argv)
{
    vector<string> model_list,shader_list;
    if(argc==2&&std::string(argv[1])=="--help"){
        std::cout<<
        "The first data is output file name or a '-' to defult it"<<std::endl<<
        "The second data is shader mode such as : normal phong texture nump displacement"<<std::endl<<
        "The Thired data is optional which you can choose whatever model you want :spot cate bunny cube rock "<<std::endl<<
        "The fourth data is optional you can change your eye's axis z,in range(2,50)"
        <<std::endl;
        return 0;
    }
    std::vector<Triangle*> TriangleList;
    float angle = 140.0;
    bool command_line = false;
    std::string model_name("spot"),shader_name;
    std::string filename = "output.png";
    objl::Loader Loader;
    std::string obj_path = "../models";
    rst::rasterizer r(700, 700);    
    std::string texture_path;
    // Load .obj File
    bool loadout =false;
    texture_path = "/spot/hmap.jpg";
    if (argc <= 3)
    {
        loadout = Loader.LoadFile("../models/spot/spot_triangulated_good.obj");
    }
    else if(argc>=4){
        if(std::string(argv[3])=="rock"){
            loadout = Loader.LoadFile("../models/rock/rock.obj");
            texture_path = "/rock/rock.png";
        }
        else if(std::string(argv[3])=="cube"){
            loadout = Loader.LoadFile("../models/cube/cube.obj");
            texture_path = "/cube/wall.tif";
        }
        else if(std::string(argv[3])=="bunny"){
            loadout = Loader.LoadFile("../models/bunny/bunny.obj");
            texture_path.clear();
        }
        else if(std::string(argv[3])=="crate"){
            loadout = Loader.LoadFile("../models/Crate/Crate1.obj");
            texture_path = "/Crate/crate_1.jpg";
        }
        else if(std::string(argv[3])=="spot"){
            loadout = Loader.LoadFile("../models/spot/spot_triangulated_good.obj");
            std::cout<<"Model Load succes"<<std::endl;
            texture_path = "/spot/hmap.jpg";
        }
        std::cout<<"Model is "<<argv[3]<<std::endl;
        model_name=argv[3];
    }
    // if(!texture_path.empty())
    //     r.set_texture(Texture(obj_path + texture_path));
    if (argc==3||argc>=4&&string(argv[3])=="spot")
        r.set_texture(Texture(obj_path + texture_path));
    for (auto mesh : Loader.LoadedMeshes)
    {
        for (int i = 0; i < mesh.Vertices.size(); i += 3)
        {
            Triangle *t = new Triangle();
            for (int j = 0; j < 3; j++)
            {
                t->setVertex(j, Vector4f(mesh.Vertices[i + j].Position.X, mesh.Vertices[i + j].Position.Y, mesh.Vertices[i + j].Position.Z, 1.0));
                t->setNormal(j, Vector3f(mesh.Vertices[i + j].Normal.X, mesh.Vertices[i + j].Normal.Y, mesh.Vertices[i + j].Normal.Z));
                t->setTexCoord(j, Vector2f(mesh.Vertices[i + j].TextureCoordinate.X, mesh.Vertices[i + j].TextureCoordinate.Y));
            }
            TriangleList.push_back(t);
        }
    }
    std::function<Eigen::Vector3f(fragment_shader_payload)> active_shader = phong_fragment_shader;
    if (argc >= 2)
    {
        command_line = true;
        filename = std::string(argv[1]);
        if(argc>=3)shader_name=argv[2];
        if (argc >= 3 && std::string(argv[2]) == "texture")
        {
            std::cout << "Rasterizing using the texture shader\n";
            active_shader = texture_fragment_shader;
            if(argc >=4 && argv[3]=="spot"||argc==3){
                texture_path = "/spot/spot_texture.png";
            r.set_texture(Texture(obj_path + texture_path));
            }
        }
        else if (argc >= 3 && std::string(argv[2]) == "normal")
        {
            std::cout << "Rasterizing using the normal shader\n";
            active_shader = normal_fragment_shader;
        }
        else if (argc >= 3 && std::string(argv[2]) == "phong")
        {
            std::cout << "Rasterizing using the phong shader\n";
            active_shader = phong_fragment_shader;
        }
        else if (argc >= 3 && std::string(argv[2]) == "bump")
        {
            if(model_name!="spot"){
                std::cout<<"There is no normal texture!"<<std::endl;
                return 0;
            }
            else{
            std::cout << "Rasterizing using the bump shader\n";
            active_shader = bump_fragment_shader;
            }
        }
        else if (argc >= 3 && std::string(argv[2]) == "displacement")
        {
            if(model_name!="spot"){
                std::cout<<"There is no normal texture!"<<std::endl;
                return 0;
            }
            else{
            std::cout << "Rasterizing using the bump shader\n";
            active_shader = displacement_fragment_shader;
            }
        }
    }
    float eye_z=10;
    if(argc>=5)eye_z=std::stoi(argv[4]);
    Eigen::Vector3f eye_pos = {0,0,eye_z};
    r.set_vertex_shader(vertex_shader);
    r.set_fragment_shader(active_shader);
    int key = 0;
    int frame_count = 0;
    if (command_line)
    {
        if(std::string(argv[1])=="-"){
            filename=model_name+"_"+shader_name+"_"+std::to_string(int(eye_z))+".png";
        }
        r.clear(rst::Buffers::Color | rst::Buffers::Depth);
        r.set_model(get_model_matrix(angle));
        r.set_view(get_view_matrix(eye_pos));
        r.set_projection(get_projection_matrix(45.0, 1, 0.1, 50));
        std::cout<<"Before Draw"<<std::endl;
        r.draw(TriangleList);
        std::cout<<"After Draw shader with "<<shader_name<<std::endl;
        cv::Mat image(700, 700, CV_32FC3, r.frame_buffer().data());
        image.convertTo(image, CV_8UC3, 1.0f);
        cv::cvtColor(image, image, cv::COLOR_RGB2BGR);
        cv::imwrite(filename, image);
        return 0;
    }
    while(key != 27)
    {
        r.clear(rst::Buffers::Color | rst::Buffers::Depth);
        r.set_model(get_model_matrix(angle));
        r.set_view(get_view_matrix(eye_pos));
        r.set_projection(get_projection_matrix(45.0, 1, 0.1, 50));
        //r.draw(pos_id, ind_id, col_id, rst::Primitive::Triangle);
        r.draw(TriangleList);
        cv::Mat image(700, 700, CV_32FC3, r.frame_buffer().data());
        image.convertTo(image, CV_8UC3, 1.0f);
        cv::cvtColor(image, image, cv::COLOR_RGB2BGR);
        cv::imshow("image", image);
        cv::imwrite(filename, image);
        key = cv::waitKey(10);
        if (key == 'a' )
        {
            angle -= 0.1;
        }
        else if (key == 'd')
        {
            angle += 0.1;
        }
    }
    return 0;
}

```

## 引用

\\\(\{\[1\]\}\\\) [【Blender】 详解 凹凸贴图 Bump/Normal/Displacement 三者的区别](https://zhuanlan.zhihu.com/p/137449232)

## 代码合集

**代码有些多，我就直接放github了。**  
[zhywyt-github](https://github.com/zhywyt/games101HomeWork/tree/master/Assignment3)

## 下/上一篇

[下一篇：Bezier曲线的绘制](https://www.cnblogs.com/zhywyt/p/17589119.html)  
[上一篇：图形填充](https://www.cnblogs.com/zhywyt/p/17576366.html)

---

## 2023-10-18  
鸽了这么久又回来写101的框架解读了

## 框架解读

### 新增文件一览

```cpp
#include "global.hpp"
#include "Shader.hpp"
#include "Texture.hpp"
#include "OBJ_Loader.h"
```