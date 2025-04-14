---
title: Unity如何设置鼠标图标？
date: 2024-11-23T10:19:00
abbrlink: d7ea97fbec36
categories:
  - 游戏开发
  - Unity
  - U2D
  - UI管理
tags:
  - 技术文档
---

我们要设置鼠标图标，肯定是因为要在不同的条件下能呈现不同的图标，所以我们需要一个单例来暴露设置鼠标的接口。

你可以从[Assets · Kenney](https://www.kenney.nl/assets)上下载一些免费资源来学习。 我们要找到已经拆分好的Tiles，将他们的格式设置为icon，并调整它的最大大小，最好设置为32，因为我们的指针不会很大，太大了会导致显示奇怪。
![](../../../../../assets/images/Pasted%20image%2020241123160500.png)
![](../../../../../assets/images/Pasted%20image%2020241123160518.png)

然后我们需要知道指针图标的全局控制方法：
## 指针的控制方法
unity为我们提供了一个简单易用的api来控制指针图标：
```csharp cursor api
Cursor.SetCursor(cursorTexture, hotspot, mode);
```
![](../../../../../assets/images/Pasted%20image%2020241123160757.png)

它接受三个参数，用于设置指针的图标、控制点、控制方式。hotspot我们会设置为（0，0），mode设置为CursorMode.mode，然后再根据状态设置texture就可以了。
## 使用求交判断鼠标指向什么
我们要判断鼠标处于什么状态可以使用光线投射来判断与什么求交。简单的，我们如果要判断与实体求交的话只需要使用，Physics2D.Raycast就可以得到第一个与光线相交的物体，但是如果我们的场景中存在不可见的覆盖物的时候，就可能出现指针状态不正确的情况。
```csharp
RaycastHit2D hit = Physics2D.Raycast(clickPos, Vector2.zero);
```
并且这种方式无法判断是否与UI（canvas render）相交，所以我们需要使用到Evensystem的接口来获取所有的相交物了。
```csharp
EventSystem.current.RaycastAll(eventDataCurrentPosition, results);
```
![](../../../../../assets/images/Pasted%20image%2020241123162003.png)
该函数会返回场景中所有与指针相交的物体，并排序。所以我们只需要得到该物体后使用第一个符合我们规则的物体作为我们的相交物体就行了。（这里需要注意，如果只选择第一个物体作为我们的相交物体可能出现被意想不到的物体遮挡的情况）

```csharp
PointerEventData eventDataCurrentPosition = new PointerEventData(EventSystem.current);
eventDataCurrentPosition.position = new Vector2(Input.mousePosition.x, Input.mousePosition.y);
List<RaycastResult> results = new List<RaycastResult>();
EventSystem.current.RaycastAll(eventDataCurrentPosition, results);
foreach (var hit in results)
{
    if (hit.gameObject != null)
    {
        Debug.Log("[CursorManager] Hit the obj: " + hit.gameObject.name + " tag with: " + hit.gameObject.tag);
        if (hit.gameObject.CompareTag("Enemy"))
        {
            SetCursor(CursorType.Attack);
            return;
        }
        else if (hit.gameObject.CompareTag("ground"))
        {
            SetCursor(CursorType.Walk);
            return;
        }
        else if (hit.gameObject.CompareTag("Buttom") || hit.gameObject.CompareTag("Inter"))
        {
            SetCursor(CursorType.Inter);
            return;
        }
		// more Type of Cursor
    }
}
SetCursor(CursorType.Normal);
```


