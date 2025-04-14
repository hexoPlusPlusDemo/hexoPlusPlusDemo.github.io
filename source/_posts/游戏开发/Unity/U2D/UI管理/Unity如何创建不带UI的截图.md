---
title: Unity 如何创建不带UI的截图？
abbrlink: bd7f49a3fa80
date: 2024-10-06T12:35:00
categories:
  - 游戏开发
  - Unity
  - U2D
tags:
  - 技术文档
---


首先我知道相机对象可以直接调用内部接口实现截图的效果，但是我们要拍摄一张不带UI的截图，那么我们可以使用第二个相机，不添加UI图层来实现这一操作。

我们要在场景中创建第二个相机，然后关闭它的`Adiuo listener`（我好像打错了，不过你应该能意会），然后将它的剔除遮罩中的UI取消勾选，并将你的UI图层设置为UI<font color='red'>注意是图层，不是排序图层</font>
像这样：
![](../../../../../assets/images/Pasted%20image%2020241006130908.png)
一定要取消`Audio Listenner`选项，不然会导致你的点击事件变得奇怪。然后创建一个脚本加入以下代码：

```csharp
#region 截图
// 指定截图的相机
public Camera screenshotCamera;
// 保存当前相机的截图
public  string SaveCurrenScreen(string filename)
{
	string path = Path.Combine(Application.persistentDataPath, RecordData.NAME, "screenshot", "screenshot_" + filename + ".png");
	Debug.Log("ScreenShot Save to: " + path);
	// 文件夹不存在则创建
	if (!Directory.Exists(Path.GetDirectoryName(path)))
	{
		Directory.CreateDirectory(Path.GetDirectoryName(path));
	}
	// 获取指定相机的截图：
	SaveCameraView(path);
	return path;
}

void SaveCameraView(string path)
{
	RenderTexture screenTexture = new RenderTexture(Screen.width, Screen.height, 24);
	screenshotCamera.targetTexture = screenTexture;
	RenderTexture.active =  screenTexture;
	screenshotCamera.Render();
	Texture2D renderTexture = new Texture2D(Screen.width, Screen.height);
	renderTexture.ReadPixels(new Rect(0, 0, Screen.width, Screen.height), 0, 0);
	RenderTexture.active = null;
	byte[] byArray = renderTexture.EncodeToPNG();
	File.WriteAllBytes(path, byArray);
}
#endregion
```

然后只需要调用`SaveCurrenScreen`就好了。