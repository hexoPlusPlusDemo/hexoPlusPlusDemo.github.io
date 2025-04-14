---
title: Unity如何控制场景切换后角色的位置？
categories:
  - 游戏开发
  - Unity
  - U2D
  - 场景管理
abbrlink: 6e1ed0060e67
date: 2024-11-09T10:17:00
tags:
  - 技术文档
---

在创作场景切换功能的时候，我遇到了一个问题，我的角色是不随场景切换而销毁的，而切换场景的时候需要确定角色的落点，但是场景切换是一个异步的过程，我们需要在这个协程结束之后再执行角色移动的代码。

在此之前，我在网上查阅了许多教程，有的说用角色的`Start`函数来追踪场景中的固定物体，[【Unity3D游戏项目入门教程】49.一行代码搞定切换场景后角色的位置。\_哔哩哔哩\_bilibili](https://www.bilibili.com/video/BV1DX4y167vu/)但是无法实现良好的操作逻辑，比如我的箱庭场景之间的切换。结合我目前实现的场景加载等待界面，我实现了一个可以定位任意位置的切换场景方式：

## 场景切换等待界面的实现

```csharp
    public void StartLoading(string scene, Vector2 pos)
    {
        LoadPanel.SetActive(true);
        currentProgress = 0;
        targetProgress = 0;
        StartCoroutine(LoadingScene(scene, pos));
    }
    public IEnumerator LoadingScene(string sceneNum, Vector2 pos)
    {
        AsyncOperation asyncOperation = SceneManager.LoadSceneAsync(sceneNum);
        asyncOperation.allowSceneActivation = false;
        while (asyncOperation.progress < 0.9f)
        {
            targetProgress = (int)(asyncOperation.progress * 100);
            yield return LoadProgress();
        }
        targetProgress = 100;
        yield return LoadProgress();
        asyncOperation.allowSceneActivation = true;
        yield return new WaitUntil(() => asyncOperation.isDone);
        hero.Instance.MoveToScenceCenter(pos);
    }
    private IEnumerator<WaitForEndOfFrame> LoadProgress()
    {
        while (currentProgress < targetProgress)
        {
            ++currentProgress;
            text.text = currentProgress.ToString() + "%";
            bar.fillAmount = currentProgress / 100f;
            yield return new WaitForEndOfFrame();
        }
        if (currentProgress >= 99)
        {
            LoadPanel.SetActive(false);
        }
    }
```
 这个协程根据帧率刷新进度，我觉得是不太好的行为，这样至少需要100帧才能完成加载。 可以尝试修改为等待0.01s来更新。

```csharp
    private IEnumerator LoadProgress()
    {
        while (currentProgress < targetProgress)
        {
            ++currentProgress;
            text.text = currentProgress.ToString() + "%";
            bar.fillAmount = currentProgress / 100f;
            yield return new WaitForSeconds(0.01f); // 等待0.01秒
        }
        if (currentProgress >= 99)
        {
            LoadPanel.SetActive(false);
        }
    }
```

我们的核心思想就是将移动角色的代码写入协程中，这样才能保证异步执行不会出错，也就是函数`LoadingScene`中的

```csharp
yield return new WaitUntil(() => asyncOperation.isDone);
 hero.Instance.MoveToScenceCenter(pos);
```

这样就可以是实现一个场景转换后角色能按指定位置移动的方法了。调用也是很方便的。
