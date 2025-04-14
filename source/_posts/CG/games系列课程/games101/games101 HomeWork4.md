---
title: games101 HomeWork4
date: '2023-07-28 23:17'
abbrlink: 6999
tags:
categories:
  - CG
  - games101
---

<!--more-->

# Games101 HomeWork4

- **bezier：该函数实现绘制 Bézier 曲线的功能。它使用一个控制点序列和一个OpenCV：：Mat 对象作为输入，没有返回值。它会使 t 在 0 到 1 的范围内进行迭代，并在每次迭代中使 t 增加一个微小值。对于每个需要计算的 t，将调用另一个函数 recursive\_bezier，然后该函数将返回在 Bézier 曲线上 t处的点。最后，将返回的点绘制在 OpenCV ：：Mat 对象上。**
- **recursive\_bezier：该函数使用一个控制点序列和一个浮点数 t 作为输入，实现 de Casteljau 算法来返回 Bézier 曲线上对应点的坐标。**

### bezier \& recursive\_bezier

**`bezier`函数需要完成整个Bezier曲线的绘制，而`recursive_bezier`需要完成Bezier曲线中任意一点的坐标计算。**

#### bezier

```c
void bezier(const std::vector<cv::Point2f> &control_points, cv::Mat &window){
    // TODO: Iterate through all t = 0 to t = 1 with small steps, and call de Casteljau's 
    // recursive Bezier algorithm.
    for(double i=0;i<1.;i+=0.0001){
        auto point=recursive_bezier(control_points,i);
        window.at<cv::Vec3b>(point.y,point.x)[1]=255; 
    }
}
```

**这里有一点需要强调，window.at\<>\(\)的第一个元素\[0\]是B通道，而\[2\]才是R通道，所以我们需要把\[1\]也就是G通道设置为255,这样才满足作业要求中的设置为绿色。**

#### recursive\_bezier

**给定所有的控制点，每对应一个t值需要给出对应的坐标。递归很容易实现：**

```c
cv::Point2f recursive_bezier(const std::vector<cv::Point2f> &control_points, float t){
    // TODO: Implement de Casteljau's algorithm
    std::vector<cv::Point2f> recursive_list;
    for (int i = 0; i < control_points.size() - 1; i++){
        recursive_list.push_back(((1 - t)) * (control_points[i]) + (t) * (control_points[i + 1]));
    }
    if(recursive_list.size()==1)
        return recursive_list[0];
    return recursive_bezier(recursive_list,t);
}
```

**修改main函数的绘制语句**

```c
//main
`		if (control_points.size() == 4) 
        {
            naive_bezier(control_points, window);
            bezier(control_points, window);
            // bezier_with_antialiasing(control_points,window);
            cv::imshow("Bezier Curve", window);
            cv::imwrite("my_bezier_curve.png", window);
            key = cv::waitKey(0);

            return 0;
        }
```

#### make\&build

`./BezierCurve`  
**随便点击四个点，得到这样的图像：**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230729092648250-1244234009_1726324391043.jpg)  
**如果不是黄色请检查你的bezier函数，在使用at\<>\(\)设置颜色的时候选择的下标是不是\[1\]。**

### 提高题

**对于一个曲线上的点，不只把它对应于一个像素，你需要根据到像素中心的距离来考虑与它相邻的像素的颜色。**  
**要求利用距离实现反走样，我设计了这么一个选择方式：**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230729095031771-280781984_1726324391043.png)  
**核心选择代码如下**

```c
float color = std::max(static_cast<uchar>((255*(2-distance)/2)),window.at<cv::Vec3b>(miny+j,minx+k)[1]);
```

**完整代码如下：**

```c
inline float get_distance(const cv::Point2f&p1,const cv::Point2f&p2){
    return (p1.x-p2.x)*(p1.x-p2.x)+(p1.y-p2.y)*(p1.y-p2.y);
}
void bezier_with_antialiasing(const std::vector<cv::Point2f> &control_points, cv::Mat &window){
    for (float i = 0; i < 1; i+=0.001f)
    {
        auto point = recursive_bezier(control_points,i);
        float minx=std::floor(point.x),miny=std::floor(point.y);
        //calculate the four points's color arount the input point 
        for(int k=0;k<=1;k++)
        {
            for(int j=0;j<=1;j++)
            {
                float distance=get_distance(cv::Point2f(miny+j,minx+k),point);
                std::cout<<distance<<std::endl;
                float color = std::max(static_cast<uchar>((255*(2-distance)/2)),window.at<cv::Vec3b>(miny+j,minx+k)[1]);
                window.at<cv::Vec3b>(miny+j, minx+k)[1] = color;
            }
        }
    }
}
```

#### 运行`./BezierCurve -a`

![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230729095151865-1624406335_1726324391043.png)  
**放大观察，可以看到不错的反走样效果。**  
![image](https://img2023.cnblogs.com/blog/3080748/202307/3080748-20230729095151865-1624406335.png)

### 番外：不同数量的控制点

**我实现了一些小把戏，可以在控制台中控制是否开启anti和控制控制点的数量，你可以键入**  
`./BezierCurve \--help`  
**来获取使用向导：**  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230729095442467-1616788326_1726324407642.png)

#### 四个点的Bezier曲线绘制展示

**前面的实现可以做到绘制任意数量控制点的Bezier曲线，只需要修改CallBack函数就好了，修改如下：**

```c
int point_num=4;//global variale
void mouse_handler(int event, int x, int y, int flags, void *userdata)
{
    if (event == cv::EVENT_LBUTTONDOWN && control_points.size() < point_num)//这里修改为了point_num
    {
        std::cout << "Left button of the mouse is clicked - position (" << x << ", "
        << y << ")" << '\n';
        control_points.emplace_back(x, y);
    }
}
```

`./BezierCurve \-a 5`  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230729100501365-1401361587_1726324407642.png)  
**甚至10个点，其实都是一样的操作**  
`./BezierCurve \-a 10`  
![image](https://raw.githubusercontent.com/zhywyt/cnblogs_pic/master/img/3080748-20230729100601157-2081347811_1726324407642.png)

#### main函数

**这里给出main函数的具体实现**

```c
int main(int argc,const char*argv[]) 
{
    if(argc==2&&std::string(argv[1])=="--help"){
        std::cout<<"The first data is use antialiasing or not.\nInput '-a' to use it!\nInput '-' to defualt\n"
        <<"The second data is number of contol point, maybe you should input more than 4"<<std::endl;
        return 0;
    }
    cv::Mat window = cv::Mat(700, 700, CV_8UC3, cv::Scalar(0));
    cv::cvtColor(window, window, cv::COLOR_BGR2RGB);
    cv::namedWindow("Bezier Curve", cv::WINDOW_AUTOSIZE);
    cv::setMouseCallback("Bezier Curve", mouse_handler, nullptr);
    bool use_anti =false;
    int key = -1;
    if(argc>=2&&std::string(argv[1])=="-a")use_anti=true;
    if(argc>=3&&std::stoi(argv[2])>4)point_num=std::stoi(argv[2]);
    while (key != 27)
    {
        for (auto &point : control_points) 
        {
            cv::circle(window, point, 3, {255, 255, 255}, 3);
        }
        std::cout<<"point_num"<<control_points.size()<<std::endl;

        if (control_points.size() == point_num) 
        {
            std::string filename="bezier_"+std::to_string(point_num)+"num_";
            if(!use_anti){
                filename+="_without_anti";
                naive_bezier(control_points, window);
                bezier(control_points, window);
            }
            else {
                filename+="with_anti";
                bezier_with_antialiasing(control_points,window);
            }
            filename+=".png";
            cv::imshow("Bezier Curve", window);
            cv::imwrite(filename, window);
            key = cv::waitKey(0);
            return 0;
        }
        cv::imshow("Bezier Curve", window);
        key = cv::waitKey(20);
    }
return 0;
}

```

## 代码汇总

[zhywyt-github](https://github.com/zhywyt/games101HomeWork/tree/master/Assignment4)

## 导航

[导航](https://www.cnblogs.com/zhywyt/p/17576370.html)

## 下/上一篇

[下一篇：Ray Tracing光线追踪](https://www.cnblogs.com/zhywyt/p/17589717.html)  
[上一篇：obj导入与phong](https://www.cnblogs.com/zhywyt/p/17577186.html)