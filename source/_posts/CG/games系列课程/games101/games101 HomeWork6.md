---
title: games101 HomeWork6
date: '2023-07-30 21:24'
abbrlink: 56022
tags:
categories:
  - CG
  - games101
---

<!--more-->

# Games101 HomeWork6

## 导航

[导航](https://www.cnblogs.com/zhywyt/p/17576370.html)

## 作业要求

- **`IntersectP(const Ray& ray, const Vector3f& invDir,const std::array<int, 3>& dirIsNeg)` in the Bounds3.hpp: 这个函数的作用是判断包围盒BoundingBox 与光线是否相交，你需要按照课程介绍的算法实现求交过程。**
- **`getIntersection(BVHBuildNode* node, const Ray ray)`in BVH.cpp: 建立BVH 之后，我们可以用它加速求交过程。该过程递归进行，你将在其中调用你实现的`Bounds3::IntersectP`。**

## 前置要求

- **`Render()` in Renderer.cpp: 将你的光线生成过程粘贴到此处，并且按照新框架更新相应调用的格式。**
- **`Triangle::getIntersection` in Triangle.hpp: 将你的光线-三角形相交函数  
  粘贴到此处，并且按照新框架更新相应相交信息的格式**

### Render\(\)

**新框架里把光线写成了一个类，castRay的参数列表也改成了这样：**

```c
Vector3f castRay(const Ray &ray, int depth) const;
```

**Ray类中的部分代码如下，我只保留了这些有用的代码：**

```c
struct Ray{
    //Destination = origin + t*direction
    Vector3f origin;
    Vector3f direction, direction_inv;
    double t;//transportation time,
    double t_min, t_max;
    Ray(const Vector3f& ori, const Vector3f& dir, const double _t = 0.0): origin(ori), direction(dir),t(_t) {
        direction_inv = Vector3f(1./direction.x, 1./direction.y, 1./direction.z);
        t_min = 0.0;
        t_max = std::numeric_limits<double>::max();
    }
    Vector3f operator()(double t) const{return origin+direction*t;}
};
```

**初始化一个Ray类对象需要一个起点点和一个向量，我们也可以使用ray\(t\)来直接访问某点的坐标。知道这些之后，我们就可以完成Render的实现：**

```c
//Render
	for (uint32_t j = 0; j < scene.height; ++j) {
        for (uint32_t i = 0; i < scene.width; ++i) {
            // generate primary ray direction
            float x = (2 * (i + 0.5) / (float)scene.width - 1) *
                      imageAspectRatio * scale;
            float y = (1 - 2 * (j + 0.5) / (float)scene.height) * scale;
            // TODO: Find the x and y positions of the current pixel to get the
            // direction
            //  vector that passes through it.
            // Also, don't forget to multiply both of them with the variable
            // *scale*, and x (horizontal) variable with the *imageAspectRatio*
            Vector3f dir = normalize(Vector3f(x, y, -1)); 
            framebuffer[m++]=scene.castRay(Ray(eye_pos,dir), 0);
        }
        UpdateProgress(j / (float)scene.height);
    }
```

### Triangle::getIntersection\(\)

**这个函数进行的操作是，在一个三角形对象中判断一根光线是否与自己相交。下图是Triangle类的数据成员声明，它继承了抽象类Object类，但是Object中没有任何数据成员，这个不用关心。可以看到三角形保存了点、边、和法线等等**

```c
//#Triangle.hpp
class Triangle : public Object
{
public:
    Vector3f v0, v1, v2; // vertices A, B ,C , counter-clockwise order
    Vector3f e1, e2;     // 2 edges v1-v0, v2-v0;
    Vector3f t0, t1, t2; // texture coords
    Vector3f normal;
    Material* m;
};
```

**在getIntersection中，我们需要返回的是一个intersection也就是碰撞体，看一下intersection类的声明：**

```c
//#Intersection.hpp
struct Intersection
{
    Intersection(){
        happened=false;
        coords=Vector3f();
        normal=Vector3f();
        distance= std::numeric_limits<double>::max();
        obj =nullptr;
        m=nullptr;
    }
    bool happened;
    Vector3f coords;
    Vector3f normal;
    double distance;
    Object* obj;
    Material* m;
};
```

**可以看到，如果没有发生碰撞，我们不需要对inter做任何操作，发生了碰撞，我们需要设置它的纹理坐标、法线、光路长度、模型指针、物体指针。这些在三角形对象中都有，检测之后一一设置就好了。**

```c
//#getIntersection()
    if(t_tmp<0)return inter;
    inter.distance = t_tmp;
    inter.happened=true;
    inter.normal=normal;
    inter.coords=ray(t_tmp);
    inter.obj=this;
    inter.m=m;
    return inter;
```

## 普通要求

### IntersectP\(\)

**这个函数需要我们完成光线与包围盒的求交判断。**

```c
    Vector3f t_minTemp=(pMin-ray.origin)*invDir;
    Vector3f t_maxTemp=(pMax-ray.origin)*invDir;
    Vector3f t_min=Vector3f::Min(t_minTemp,t_maxTemp);
    Vector3f t_max=Vector3f::Max(t_minTemp,t_maxTemp);

    float t_enter=std::max(t_min.x,std::max(t_min.y,t_min.z));
    float t_out=std::min(t_max.x,std::min(t_max.y,t_max.z));
```

**先计算进入盒子的时间和出盒子的时间，然后返回判断条件的真假就好了**

```c
    if(t_out>=0.0f&&t_enter<=t_out)
        return true;
    return false;
```

### getIntersection\(\)

**要求建立BVH ，我们可以用它加速求交过程。**  
**还记得么？包围盒是以二叉树的形式存储的，就像这样：**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230730210530875-1305392703_1726324304027.png)  
**对一个包围盒，我们需要检查该包围盒是否与光线相交，如果有，那么判断这个包围盒是否存在子叶，如果有，检查递归检查子叶是否与光线有交点，直到这个包围盒不与光线相交；或者该包围盒不再存在子叶，则判断这个物体是否与光线相交。代码实现如下：**

```c
Intersection BVHAccel::getIntersection(BVHBuildNode* node, const Ray& ray) const
{
    // TODO Traverse the BVH to find intersection
	// invDir: ray direction(x,y,z), invDir=(1.0/x,1.0/y,1.0/z), use this because Multiply is faster that Division
    // dirIsNeg: ray direction(x,y,z), dirIsNeg=[int(x>0),int(y>0),int(z>0)], use this to simplify your logic
    Intersection intersect;
    Vector3f invdir(1./ray.direction.x,1./ray.direction.y,1./ray.direction.z);
    std::array<int, 3> dirIsNeg;
    dirIsNeg[0] = ray.direction.x>0;
    dirIsNeg[1] = ray.direction.y>0;
    dirIsNeg[2] = ray.direction.z>0;
    if(!node || !node->bounds.IntersectP(ray,ray.direction_inv,dirIsNeg))
    {
        return intersect;
    }

    if(!node->right && !node->left)
        return node->object->getIntersection(ray);

    Intersection isect2= getIntersection(node->left,ray);
    Intersection isect1= getIntersection(node->right,ray);
    return isect1.distance < isect2.distance ? isect1:isect2;
}
```

### 运行`./RayTracing`

#### **注意！运行前，请确保你的/build目录下有`imag_BVH`和`imag_SAH`目录，我把生成的图片放在里面了！！！**

**像这样**  
![image](https://img2023.cnblogs.com/blog/3080748/202307/3080748-20230730210530875-1305392703.png)

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230730153853931-712417031_1726324322660.png)  
**很棒的光影！但是渲染这张图片需要花费我的电脑6-8秒钟，BVH还是太慢了，接着，我们来学习新的加速模式SAH\(Surface Area Heuristic\)。**

## 提高题\(SAH加速\)

**首先，做BVH的时候，我们划分空间的方式是从中间进行的，不考虑空间中物体的密度大小。这样可能导致划分非常的不合理。而简单来说SAH就是指在划分空间的时候，先判断两块空间所需的时间（进行估计），估计的方法有很多。**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230730203530877-1333849713_1726324322660.png)  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230730203252774-563756016_1726324322660.png)

**我们的优化目标就是这个总消耗\\\(C\\\)**

 -    **0.125为无关消耗，可以理解为计算这个消耗的消耗 \\\(C\_\{trav\}\\\)**
 -    **第二个和第三个分别是左节点和右节点的消耗**
 -    **最后的maxAreaDiv就是总当前节点包围盒的总面积分之一 \\\(\\frac\{1\}\{S\_N\}\\\)**

```c
float cost = 0.125f + (leftCount * leftBounds3.SurfaceArea() + rightCount * rightBounds3.SurfaceArea()) * maxAreaDiv;
```

**枚举一定数量的划分方案，然后估算这些方案的消耗值。通过求最大值得到划分方案。**

```c
			Bounds3 centroidBounds;
            for (int i = 0; i < objects.size(); ++i)
                centroidBounds =
                    Union(centroidBounds, objects[i]->getBounds().Centroid());
            int dim = centroidBounds.maxExtent();
            float maxArea = centroidBounds.SurfaceArea();
            float minCost = std::numeric_limits<float>::infinity();
            int minClipNum = 0;
            float BoundingClip = 10;

            float BoundingClipDiv = 1.0f / BoundingClip;
            float maxAreaDiv = 1.0f / maxArea;
            for (int i = 0; i < BoundingClip; i++)
            {
                Bounds3 leftBounds3;
                Bounds3 rightBounds3;
                float leftCount = 0.0f;
                float rightCount = 0.0f;
                auto middlingTemp = objects.begin() + std::floor(objects.size() * (i * BoundingClipDiv));
                for (auto j = objects.begin(); j < middlingTemp; j++)
                {
                    leftBounds3 = Union(leftBounds3, (*j)->getBounds().Centroid());
                    leftCount = leftCount + 1.0f;
                }
                for (auto j = middlingTemp; j < objects.end(); j++)
                {
                    rightBounds3 = Union(rightBounds3, (*j)->getBounds().Centroid());
                    rightCount = rightCount + 1.0f;
                }
                float cost = 0.125f + (leftCount * leftBounds3.SurfaceArea() + rightCount * rightBounds3.SurfaceArea()) * maxAreaDiv;
                if (cost < minCost)
                {
                    minClipNum = i;
                    minCost = cost;
                }
            }
            middling = objects.begin() + std::floor(objects.size() * (minClipNum * BoundingClipDiv));
```

**这里就不挂完整代码了，有兴趣的小伙伴可以去github上看。**

### 结果

#### AMD® Ryzen 7 5800h with radeon graphics × 16

#### BVH `./RayTracing BVH`

**BVH用我的电脑跑出来最好的效果是最快`7299ms`**

#### SAH `./RrayTracing SAH`

**SAH用我的电脑跑出来最好的效果是最快`6732ms`**

#### DIY

**有兴趣的小伙伴可以尝试修改`float BoundingClip = 10;`，它在`BVHAccel::recursiveBuild`中，代表SAH划分空间的时候枚举的空间数量。说不定会有更好的加速效果哦～**

## 代码汇总

[zhywyt-github](https://github.com/zhywyt/games101HomeWork/tree/master/Assignment6)

## 下/上一篇

[下一篇：](https://www.cnblogs.com/zhywyt/p/17597301.html)  
[上一篇：Ray Tracing 光线追踪](https://www.cnblogs.com/zhywyt/p/17589717.html)