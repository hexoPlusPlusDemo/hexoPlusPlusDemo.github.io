---
title: NU-NeRF论文解读
date: 2024-10-30T11:10:00
abbrlink: 2c9570b00976
categories:
  - CG
  - Rebuild
  - Transparent
---
![](../../../../assets/images/Pasted%20image%2020241030111112.png)
 # Neural Reconstruction of Nested Transparent Objects with Uncontrolled Capture Environment
无控制捕获环境下嵌套透明物体的神经重建
[NU-NeRF](http://geometrylearning.com/NU-NeRF/)
[参考](https://mp.weixin.qq.com/s?__biz=MzA3MzI4MjgzMw==&mid=2650935808&idx=4&sn=f3e20f5144102508c919a192e0f16c28&)

## Abstract 摘要
The reconstruction of transparent objects is a challenging problem due to the highly noncontinuous and rapidly changing surface color caused by refraction. Existing methods rely on special capture devices, dedicated backgrounds, or ground-truth object masks to provide more priors and reduce the ambiguity of the problem. However, it is hard to apply methods with these special requirements to real-life reconstruction tasks, like scenes captured in the wild using mobile devices. Moreover, these methods can only cope with solid and homogeneous materials, greatly limiting the scope of the application. To solve the problems above, we propose NU-NeRF to reconstruct nested complex transparent objects requiring no dedicated capture environment or additional input. NU-NeRF is built upon a neural signed distance field formulation and leverages neural rendering techniques. It consists of two main stages. In Stage I, the surface color is separated into reflection and refraction. The reflection is decomposed using physically based material and rendering. The refraction is modeled using a single MLP given the refraction and view directions, which is a simple yet effective solution of refraction modeling. This step produces high-fidelity geometry of the outer surface. In stage II, we use explicit ray tracing on the reconstructed outer surface for accurate light transport simulation. The surface reconstruction is executed again inside the outer geometry to obtain any inner surface geometry. In this process, a novel transparent interface formulation is used to cope with different types of transparent surfaces. Experiments conducted on synthetic scenes and real captured scenes show that NU-NeRF is capable of producing better reconstruction results than previous methods and achieves accurate nested surface reconstruction while requiring no dedicated capture environment.
由于折射引起的表面颜色的高度不连续和快速变化，透明物体的重建是一个具有挑战性的问题。现有的方法依赖于特殊的捕获设备，专用的背景，或地面实况对象掩模，以提供更多的先验知识，并减少问题的模糊性。然而，很难将具有这些特殊要求的方法应用于现实生活中的重建任务，例如使用移动的设备在野外捕获的场景。此外，这些方法只能科普固体和均匀的材料，大大限制了应用范围。为了解决上述问题，我们提出了NU-NeRF来重建嵌套的复杂透明对象，不需要专门的捕获环境或额外的输入。NU-NeRF建立在神经符号距离场公式的基础上，并利用神经渲染技术。它包括两个主要阶段。在第一阶段，表面颜色被分为反射和折射。使用基于物理的材质和渲染来分解反射。在给定折射和视角方向的情况下，使用单个MLP来建模折射，这是一种简单而有效的折射建模解决方案。该步骤产生外表面的高保真几何形状。在第二阶段，我们使用显式光线追踪重建的外表面精确的光传输模拟。在外部几何结构内部再次执行表面重建以获得任何内部表面几何结构。在这个过程中，一种新的透明界面配方是用来科普不同类型的透明表面。在合成场景和真实的捕获场景上进行的实验表明，NU-NeRF能够产生比以前的方法更好的重建结果，并且在不需要专用捕获环境的情况下实现精确的嵌套表面重建。

## Method 方法