---
title: Unity如何保存存档？
date: 2024-10-03T19:29:00
categories:
  - 游戏开发
  - Unity
tags:
  - 技术文档
overDate: 2024-10-06T13:02:00
abbrlink : 823c297f1d7f
---
这部分内容消耗了我大量的时间和精力，在这里稍微总结一下吧。首先我和策划达成一个共识：**当前所有的数据都要保存在角色身上**，所以我们创建一个`saveData`类在我们的`hero`中。这里我们可以加入任何我们需要保存的数据。

但是我们需要实现多个存档，而PlayerPref只能存储单个存档，并且类型十分有限，只能存储**整形**、**浮点**、**字符串**。于是我们只能结束`json`的序列化字符串的功能来实现我们的想法。但是这还是不能解决多存档的问题。我在b站上看到一个思路：<font color='red'>使用PlayerPref保存存档信息，使用文件保存存档。</font>这个想法让我眼前一亮，直接开始了结构的整理。


# 架构
我们有两个地方需要用到存档UI，一个是开始界面，玩家直接读档，一个是设置页面，玩家保存和读档。特殊的我们还需要实现自动存档来实现开始页面的继续游戏选项。我们总共设置八个存档，所以需要八个档位对象，挂载在存档表下。裆位对象需要实现外部展示、档位路由、按钮回调实现。存档表需要实现档位对象的管理。

|        对象名        | 功能                                                           | 挂载精灵           |
|:--------------------:|:-------------------------------------------------------------- | ------------------ |
|      档位(save)      | 实现存档按钮的回调函数，并展示存档信息                         | 用于UI中展示的按钮 |
|   存档表(UIManager)   | 实现多档位的管理，处理档位之间的关系                           | 最大的UIcanvas上   |
| 存档管理(RecordData) | 记录多存档的信息，调用保存类的接口，将存档信息保存到PlayerPref | 档位的滑动视图上   |
|      英雄(hero)      | 实现存档数据结构的设计，调用存档管理类的接口和保存类的接口     | 主角               |
|  保存类(SaveSystem)  | 实现数据写入PlayerPref和JSON文件                               | 全局静态           |

这里的`UIManager`类和`RecordData`类再分清楚一点，`RecordData`类实际上没有保存任何与游戏相关的内容，而是把所有的存档的文件路径保存在了PlayerPref中，因为PlayerPref默认使用注册表保存，所以不宜保存大量数据，并且只需要保存一份数据就可以了。而`UIManager`类将所有的游戏数据保存在本地文件中，需要保存多个文件，接受`RecordData`管理。这里能理解那么这个存档系统就十分的清晰了。
# 类的实现

## save

这个类主要用于展示我们的存档信息，每个对象只需要管理自己的一个存档就可以了。这份脚本需要挂载在所有的存档精灵上，所以它需要标识自己的存档序号，这个序号我选择手动标记。

### 数据部分

数据部分主要包括三块：`控件`、`info`、`本地化`。

由于只需要静态本地化字符，所以不需要很复杂的设计，只需要将需要的字符全部本地化就好了。本地化设置可以参考：[Unity如何在脚本中使用本地话字符？](http://hexo.zhywyt.me/posts/59a4f8f59f45)

**控件**部分我们需要控制档位精灵下面的所有精灵，包括文字、按钮、图像等。
**info**部分我设计为一个存档的决定因素，包括ID、图片路径、状态等。
这两部分代码如下：
```csharp
#region 控件
public GameObject infoScence;
public GameObject infoGameTime;
public GameObject infoSaveTime;
public GameObject infoLabel;
public Image image;
public Button m_button;
#endregion

#region info
public int ID;
public string ImagePath;
public bool isSave, isLoad;
#endregion
```

### 方法

方法一览：

|   方法名   | 返回值类型 | 方法作用                                             |
|:----------:|:---------- | ---------------------------------------------------- |
|   Start    | void       | 初始化所有控件，设置状态                             |
|  SetInfo   | void       | 接口函数，用于设置info                               |
|   getID    | int        | 接口函数，用于返回当前存档的ID                       |
|  OnClick   | void       | 回调函数，绑定回调事件，通过状态判断需要存档还是读档 |
|  LoadSelf  | void       | 尝试从文件中读取存档信息，文件路径从`RecordData`     |
| SetStatus  | void       | 接口函数，用于设置状态                               |
| DeleteSelf | void       | 删档函数，需要同步删除存档引用的截图                 |


### 代码汇总

```csharp fold | file:save.cs
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;
using UnityEngine.UI;
using System;
using UnityEngine.Localization.Settings;
using UnityEngine.Localization.Tables;
using UnityEngine.Localization;
public class save : MonoBehaviour
{
    #region 控件
    public GameObject infoScence;
    public GameObject infoGameTime;
    public GameObject infoSaveTime;
    public GameObject infoLabel;
    public Image image;
    public Button m_button;
    #endregion

    #region info
    public int ID;
    public string ImagePath;
    public bool isSave, isLoad;
    #endregion

    #region 本地化
    private string lsCurScence, lsGameTime, lsSaveTime, lsAutoSave, lsSave;
    public LocalizedStringTable stringTable = new LocalizedStringTable { TableReference = "UI" };

    private void OnEnable()
    {
        stringTable.TableChanged += LoadLocalizationString;
    }
    private void OnDisable()
    {
        stringTable.TableChanged -= LoadLocalizationString;
    }
    void LoadLocalizationString(StringTable table)
    {
        lsCurScence = GetLocalizedString(table, "CurrentScence");
        lsGameTime = GetLocalizedString(table, "GameTime");
        lsSaveTime = GetLocalizedString(table, "SaveTime");
        lsAutoSave = GetLocalizedString(table, "AutoSave");
        lsSave = GetLocalizedString(table, "Save");
    }
    static string GetLocalizedString(StringTable table, string key)
    {
        if(table == null || key == null)
        {
            Debug.Log("[LocalLization LOG] Table OR Key is null!");
            return null;
        }
        var entry = table.GetEntry(key);
        if (entry == null)
        {
            Debug.Log("[LocalLization LOG] There is not key: " + key);
            return null;
        }
        return entry.GetLocalizedString();
    }

    /// <summary>
    /// with include:
    /// using UnityEngine.Localization;
    /// </summary>
    #endregion
    void Start()
    {
        infoScence = gameObject.transform.Find("InfoScence").gameObject;
        infoGameTime = gameObject.transform.Find("InfoGameTime").gameObject;
        infoSaveTime = gameObject.transform.Find("InfoSaveTime").gameObject;
        infoLabel = gameObject.transform.Find("id").gameObject;
        image = GetComponent<Image>();
        m_button = GetComponent<Button>();
        isSave = isLoad = false;
        m_button.onClick.AddListener(OnClick);
    }
    // TODO : load the screeenshot
    public void SetInfo(string scence, string  gameTime, string saveTime, string imagePath="")
    {
        // 本地化
        infoScence.GetComponent<TextMeshProUGUI>().text = (scence == null ? "" : lsCurScence + "：" + scence);
        infoGameTime.GetComponent<TextMeshProUGUI>().text = (gameTime == null ? "" : lsGameTime + "：" + gameTime);
        infoSaveTime.GetComponent<TextMeshProUGUI>().text = (saveTime == null ? "" : lsSaveTime + "：" + saveTime);
        if (imagePath != "")
        {
            byte[] bytes = System.IO.File.ReadAllBytes(imagePath);
            Texture2D texture = new Texture2D(1, 1);
            texture.LoadImage(bytes);
            image.sprite = Sprite.Create(texture, new Rect(0, 0, texture.width, texture.height), new Vector2(0, 0));
            ImagePath = imagePath;
            Debug.Log("Succe Load The Image");
        }
    }
    public int getID()
    {
        return ID;
    }
    public void OnClick()
    {
        if (isSave)
        {
            // TODO: 提示此操作不可逆
            hero.Instance.Save(getID());
            RecordData.instance.Load();
            Debug.Log("Save the game" );
            // save
        }
        else if (isLoad)
        {
            hero.Instance.Load(getID());
            Debug.Log("Load the game");
            //load
        }
    }
    public void LoadSelf()
    {
        // load the id from json
        // 本地化
        if (ID == 1)
        {
            // localization
            infoLabel.GetComponent<TextMeshProUGUI>().text = lsAutoSave;
        }
        else
        {
            infoLabel.GetComponent<TextMeshProUGUI>().text = lsSave + ID;
        }
        var saveData = SaveSystem.LoadFromJson<hero.SaveData>(RecordData.instance.getRecordName(getID()));
        if (saveData != null)
        {
            // format the time to hh mm ss
            TimeSpan ts = new TimeSpan(0, 0, ((int)saveData.GameTime));
            var gameTime = string.Format("{0:D2}:{1:D2}:{2:D2}", ts.Hours, ts.Minutes, ts.Seconds);
            SetInfo(saveData.currentScene, gameTime, saveData.saveTime ,saveData.imagePath);
            Debug.Log("Load the save: " + getID());
        }
        else
            Debug.Log("Save is empty :" + getID());
        // 空存档不处理
    }
    public void SetStatus(bool save, bool load)
    {
        isSave = save;
        isLoad = load;
    }
    public void DeleteSelf()
    {
        // 确保删除的和存档列表相同
        LoadSelf();
        // imagePath存在则删除
        SaveSystem.FileDelete(ImagePath);
        SaveSystem.FileDelete(RecordData.instance.getRecordName(getID()));
    }
}
```

非常不错，我们来看下一个类的实现。

## UIManager
这是一个非常庞大的类，我写它的目的是用于管理所有的UI控件，并为他们设置回调函数，事实上，目前为止，除了存档这样逻辑复杂的控件以外其他的控件我都是使用该类简单地进行回调的。在一个类中处理所有的UI逻辑会显得很简单，但是今天不是来讲UI逻辑的，我们只将其中管理存档的部分代码，你可以参照这个设计理念设计一个简单的存档管理类，而不是UI管理。
首先我们需要获取当前存档结构的所有精灵：
```csharp file:UIManager.cs

public GameObject AllSave;
public string preAllSaveButtonName;
public List<string> AllSaveButtonName = new List<string> { "Save1", "Save2", "Save3", "Save4", "Save5", "Save6", "Save7", "Save8" };
public Dictionary<string, GameObject> AllSaveButton = new Dictionary<string, GameObject>();
public GameObject AllSaveCloseButton;
public bool isSave;
public bool isLoad;


private void Awake(){
	// something others

	preAllSaveButtonName = "Viewport/Content/";
	isSave = isLoad = false;
	AllSaveButtonName = new List<string> { "Save1", "Save2", "Save3", "Save4", "Save5", "Save6", "Save7", "Save8" };
	AllSave = SettingScreen.transform.Find("AllSave").gameObject;
	AllSaveCloseButton = AllSave.transform.Find("close").gameObject;
	for (int i=0;i < AllSaveButtonName.Count; i++)
	{
		var button = AllSave.transform.Find(preAllSaveButtonName+AllSaveButtonName[i]);
		if (button != null)
		{
			AllSaveButton.Add(AllSaveButtonName[i],button.gameObject);
		}
		else
		{
			Debug.LogError("Can't find button: " + AllSaveButtonName[i]);
		}
	}

}
private void Start(){
	// something
	if(AllSaveCloseButton.GetComponent<Button>() != null)
	{
		AllSaveCloseButton.GetComponent<Button>().onClick.AddListener(() =>
		{
			Debug.Log("Close activate!");
			disableCanvas(AllSave);
			isLoad = isSave = false;
		});
	}

}
```
然后我们设置打开存档的回调函数：
```csharp
void OnOpenSave(){
	isSave = true;
	UpdateAllSave();
	enableCanvas(AllSave);
	Debug.Log("Save is avaliable");
}
void UpdateAllSave()
{
	// to update the save from disk to UI
	for (int i = 0; i < AllSaveButtonName.Count; i++)
	{
		var asave = AllSaveButton[AllSaveButtonName[i]].GetComponent<save>();
		asave.LoadSelf();
		asave.SetStatus(isSave,isLoad);
	} 
}
```
由于这只是部分的代码，我不能确定是否能直接运行（大概率不行），你需要自己编写属于你的管理类，这里只做参考。因为这个类也不是最重要的类，只是一个中间层而已。我们的存档思想主要体现在`RecordData`类中：

## RecordData
我们需要在这个类中记录我们存档在计算机上的保存信息，并对应在内存（代码）中的映射关系。这个类近乎是一个模板，因为它和保存的数据结构没有任何关系，只需要接口对应就能完成它的工作。同样的，我把它设计为一个单例，这样保证我们不会有更多的存档。
### 数据部分
在数据部分，我们需要设定我们的最大存档的数量、以及在注册表中的键名（因为我们的这些信息是使用`PlaerPref`保存在注册表中的）、一个记录存档的数据类（目前里面只需要保存存档的文件路径就好了）。

| 数据名         | 作用                                                           |
| -------------- |:-------------------------------------------------------------- |
| recordNum      | 记录最大保存数量                                               |
| NAME           | 记录在注册表中的键名                                           |
| recordName[]   | 记录所有保存的文件名                                           |
| class SaveData | 数据类，数据成员与本类中保存的一致，也可以直接保存一个该类对象 |

### 方法
方法表如下：

| 方法                              | 作用                                                       |
|:--------------------------------- | ---------------------------------------------------------- |
| SaveData ForSave()                | 保存前的准备工作，将类中的数据复制到一个新对象中，并返回它 |
| void ForLoad(SaveData saveData)   | 读入后的复制工作，接受从文件中读入的数据类对象             |
| public void Save()                | 接口函数，用于将所有数据保存到注册表                       |
| public void Load()                | 接口函数，用于从注册表读取数据到文件                       |
| public string getRecordName(int ) | 接口函数，用于读取对应id的文件名                           |
| public string genRecordName(int ) | 接口函数，用于创建对应id的文件名                           |
| public int getNum()               | 接口函数，用于返回存档数                                   |


### 代码汇总

```csharp fold | file:RecordData.cs
using System.Collections;
using System.Collections.Generic;
using Unity.VisualScripting;
using UnityEngine;
using System.IO;
public class RecordData : MonoBehaviour
{
    #region 单例
    public static RecordData instance;
    private void Awake()
    {
        if (instance == null)
        {
            DontDestroyOnLoad(gameObject);
            instance = this;
            // 创建全空数组
            for (int i = 0; i < recordNum; i++)
            {
                recordName[i] = "";
            }
            Load();
        }
        else if (instance != this)
        {
            Destroy(gameObject);
        }
    }
    #endregion

    public const int recordNum = 8;
    public const string NAME = "Saves";
    

    private string[] recordName = new string[recordNum];
    //public int lastID;
    class SaveData
    {
        public string[] recordName = new string[recordNum];
        //public int lastID;
    }
     SaveData ForSave()
    {
        var saveData = new SaveData();
        for (int i = 0; i < recordNum; i++)
        {
            saveData.recordName[i] = recordName[i];
        }
        //saveData.lastID = lastID;
        return saveData;
    }
    void ForLoad(SaveData saveData)
    {
        //lastID = saveData.lastID;
        for (int i = 0; i < recordNum; i++)
        {
            recordName[i] = saveData.recordName[i];
        }
    }
    public void Save()
    {
        SaveSystem.SaveByPlayerPrefs(NAME, ForSave());
    }
    public void Load()
    {
        if (PlayerPrefs.HasKey(NAME))
        {
            Debug.Log("Log the record SUCCE!!");
            var saveData = SaveSystem.LoadFromPlayerPrefs<SaveData>(NAME);
            for (int i = 0; i < recordNum; i++)
            {
                // 文件不存在则删除该记录
                if (saveData.recordName[i] != "" && !File.Exists(saveData.recordName[i]))
                {
                    saveData.recordName[i] = "";
                }
            }
        ForLoad(saveData);
        }
    }
    public string getRecordName(int id)
    {
        string name = "";
        if (id >= 0 && id < recordNum)
            name = recordName[id];
        return name;
    }
    public string genRecordName(int id)
    {
        if(id >= 0 && id < recordNum)
        {
            recordName[id] = Path.Combine(Application.persistentDataPath, NAME, System.DateTime.Now.ToString("yyyy-MM-dd_HH-mm-ss") + ".json");
            Save();
#if UNITY_EDITOR
            for(int i=0;i<recordNum; i++)
            {
                Debug.Log("RecordData: " + i + " :" + recordName[i]);
            }
#endif
            return recordName[id];
        }
        return null;
    }
    public int getNum()
    {
        return recordNum;
    }
}

```


### 讲解
这个类的实现思路很有意思，它只调用了两个与文件操作的接口，也就是后面要实现的`SaveSystem`类。自由度极高，它使用时间戳来给需要保存的存档命名，每次初始化检查存档文件是否存在，不存在则删除注册表中的记录。这样可以让用户删除存档文件的时候出现错误。如果你希望，还可以加一个反向添加的功能，这样就能让玩家自己添加存档了。这里我就不实现了。

## SaveSystem
这里我先讲SaveSystem，这里主要是与文件的读写有关系的函数，也是相当独立的一个类，与保存到数据结构没有关系。
### 数据部分
`SaveSystem`没有必要的数据成员。如果需要为你的存档创建截图的话，你需要使用到一个相机对象。关于如何使用分离相机的方式创建截图可以参考这篇博客：[Unity创建不带UI的截图](/posts/bd7f49a3fa80)。
### 方法

#### PlayerPref

| 方法                                                 | 作用                                                        |
| ---------------------------------------------------- | ----------------------------------------------------------- |
| public static void SaveByPlayerPrefs(string, object) | 接口函数，保存obj中的所有数据到注册表中，使用PlayerPref保存 |
| pbulic static T LoadFromPlayerPrefs<T>(string)       | 接口函数，用于读取某一个键中的数据，并反序列化为指定类      |

#### JSON

| 方法                                            | 作用                          |
| --------------------------------------------- | --------------------------- |
| static string GetPath(string)                 | 这个函数是内部函数，用于将相对路径指定到项目的绝对路径 |
| public static void SaveByJson(string, object) | 接口函数，这个函数将对象序列化后保存到指定路径中    |
| public static T LoadFromJson<T>(string)       | 接口函数，将文件中的数据读出并反序列化为指定类型    |
| public static void FileDelete(string path)    | 接口函数，删除指定文件                 |

### 代码汇总
```csharp fold | file:SaveSystem.cs
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;
using Unity.VisualScripting;
using System;
public class SaveSystem : MonoBehaviour 
{
    #region 单例
    public static SaveSystem instance;
    private void Awake()
    {
        if (instance == null)
        {
            DontDestroyOnLoad(gameObject);
            instance = this;
        }
        else if (instance != this)
        {
            Destroy(gameObject);
        }
    }
    #endregion


    #region prefs
    public static void SaveByPlayerPrefs(string key, object obj)
    {
        string json = JsonUtility.ToJson(obj);
        PlayerPrefs.SetString(key, json);
        PlayerPrefs.Save();
    }
    public static T LoadFromPlayerPrefs<T>(string key)
    {
        string json = PlayerPrefs.GetString(key,null);
        if (json!=null)
        {
            return JsonUtility.FromJson<T>(json);
        }
        return default;
    }
    #endregion

    #region JOSN
    static string GetPath(string filename)
    {
        return Path.Combine(Application.persistentDataPath, filename);
    }
    public static void SaveByJson(string path, object obj)
    {
        string json = JsonUtility.ToJson(obj);
        Debug.Log(json);
        // path dir not exist
        if (!Directory.Exists(Path.GetDirectoryName(path)))
        {
            Directory.CreateDirectory(Path.GetDirectoryName(path));
        }
        System.IO.File.WriteAllText(path, json);

    }
    
    public static T LoadFromJson<T>(string fileName)
    {
        if (fileName == ""||fileName==null)
        {
            Debug.Log("File name is empty");
            return default;
        }
        string path = GetPath(fileName);
        if(File.Exists(path))
        {
            string json = File.ReadAllText(path);
            Debug.Log($"Loaded from {path}");
            return JsonUtility.FromJson<T>(json);
        }
        else
        {
            Debug.Log("File not found in " + path);
            return default;
        }

    }
    public static void FileDelete(string path)
    {
        // path存在
        if (File.Exists(GetPath(path)))
        {
            File.Delete(GetPath(path));
        }
    }

    #endregion
```
## hero
最后就是我们的主要数据控制部分了，在`hero`类或者你自己的`Player`类中，我们需要定义需要保存的数据结构，以及调用接口进行保存和读取操作。如果你看的仔细的话，在`save.cs`类中已经存在了对`hero`单例的函数调用，因为当前的所有数据都保存在`hero`中，我们需要它来具体读入和保存。
### 数据部分
首先我们要定义一个需要保存的数据结构，并声明为可序列化类：
```csharp
[System.Serializable]public class SaveData{
	// your data
}
```
这里可以保存任何你想保存的数据，包括基础类型、列表、字典等一切可序列化的数据。
如果你想实现自动保存的话，你还需要一个自动保存计时器。并定义自动保存挡位ID和它的自动保存时间：
```csharp
private float SinceLastSaveTime;
private const int AUTO_SAVE_ID = 1;
private const int AUTO_SAVE_TIME = 10;
```

然后你还需要在`Start`函数中初始化他们，并在`Update`函数中更新计时器。
这部分我不细讲了。你可以自己实现，或者借助GPT的力量。
### 方法

| 方法                               | 作用                                         |
| ---------------------------------- | -------------------------------------------- |
| SaveData ForSave()                 | 保存前的数据准备                             |
| void ForLoad(SaveData)             | 读取后的数据拷贝                             |
| public void Save(int)              | 接口函数，用于保存当前数据到id档位           |
| public void Load(int)              | 接口函数，用于读入id档位数据                 |
| public static void DeleteSave(int) | 接口函数，用于删除某一个存档(此函数用于调试) |
| public void AutoSave()             | 接口函数，自动存档一次                       |


代码我给出存档部分的，具体的数据请自己实现：
```csharp fold | file:hero.cs
    #region JSON存档
    SaveData ForSave()
    {
        var saveData = new SaveData();
		// copy your data
        return saveData;
    }
    void ForLoad(SaveData data)
    {
		// copy your data
    }
    public void Save(int id)
    {
        string RecordName = RecordData.instance.genRecordName(id);
        if(RecordName == null)
        {
            Debug.LogError("RecordName is null");
            Debug.LogError("ID: "+id.ToString());
            return;
        }
        Debug.Log("Save to :"+RecordName);
        SaveSystem.SaveByJson(RecordName, ForSave());
    }
    public void Load(int id)
    {
        var saveData = SaveSystem.LoadFromJson<SaveData>(RecordData.instance.getRecordName(id));
        if (saveData != null)
        {
            ForLoad(saveData);
            Debug.Log("Load the data from " + id.ToString() + " : " + saveData);
        }
        else
            Debug.Log(id.ToString() + "空存档");
    }

#if UNITY_EDITOR
    [UnityEditor.MenuItem("Jobs/Delete All PlayerPrefs")]
    public static void DeleteAllSave()
    {
        Debug.Log("Deleting all save!");
        for(int i=0;i<RecordData.instance.getNum(); i++)
        {
            DeleteSave(i);
        }
        if (PlayerPrefs.HasKey(RecordData.NAME))
        {
            PlayerPrefs.DeleteKey(RecordData.NAME);
        }
        Debug.Log("All save deleted!");
    }
#endif
    public static void DeleteSave(int id)
    {
        UIManager.instance.DeleteSave(id);
    }
    public void AutoSave()
    {
        // in update save with 5 mins
        Save(AUTO_SAVE_ID);
    }
    #endregion

```



# 后记
存档部分就到这里啦，其实要完成一个存档，不仅仅需要代码的支持，还要和组件一起合作实现，需要完成两边协作才行！希望这篇文章对你有帮助，而不是代码对你有帮助，这种实现方法，这种理念我认为是很好的。谢谢阅读~