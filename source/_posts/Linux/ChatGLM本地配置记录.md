---
title: ChatGLM本地配置记录
date: 2024-09-16T19:38:00
overDate: 2024-09-17T23:18:00
categories:
  - Linux
abbrlink: b4ca7a5fb5b2
---
[gitea](../1c09aa798545)
## 原由
可爱的室友说想玩本地部署的GPT，于是这里打算部署一个ChatGLM给他玩一下。这里记录部署过程。本地使用的机器如图。由于GLM需要大量的显存和内存，我使用的是PVE容器分配了32GB内存用于和显卡用于推理模型。
![](../../assets/images/Pasted%20image%2020240916194636.png)
![](../../assets/images/Pasted%20image%2020240916194935.png)
## 环境配置
#### conda
并使用conda安装环境。
```bash
wget https://repo.anaconda.com/archive/Anaconda3-2024.06-1-Linux-x86_64.sh
chmod +x Anaconda3-2024.06-1-Linux-x86_64.sh
./Anaconda3-2024.06-1-Linux-x86_64.sh
# 激活conda
eval "$(/root/anaconda3/bin/conda shell.bash hook)"
# 可选
ln -s /root/anaconda3/bin/conda /bin/conda
```

请自行根据引导安装conda。装好conda之后重启终端，开始安装ChatGLM需要的环境。
#### cuda
cuda的安装方法你可以在这里找到[cuda](https://developer.nvidia.com/cuda-downloads?target_os=Linux)，不建议使用deb安装，而建议使用.run的方式安装，但是具体看你的设备环境能装上哪个版本。比如我需要12.4的cuda，所以我可以找到他并安装。
比如你要找`<version>`这个版本，你可以用这条链接找到他
`https://developer.download.nvidia.com/compute/cuda/<version>`

<center><font color='red'>!!!版本很重要</font></center>

```bash
wget https://developer.download.nvidia.com/compute/cuda/12.4.0/local_installers/cuda_12.4.0_550.54.14_linux.run
sh cuda_12.4.0_550.54.14_linux.run
```
如果你没有安装显卡驱动可以在这里同步安装，如果安装了的话，请不要重复安装。
你可能需要一点耐心，cuda的安装非常漫长，这是由于apt是单线程导致的。你可以尝试使用多线程的apt，但是我无法保证多线程编译是否正确。安装的同时你可以进行后面不需要cuda的部分。比如conda创建环境、模型下载等。

#### pytorch
```bash
# 创建虚拟环境
conda create -n glm python=3.10
conda activate glm
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu124

```


#### 克隆仓库
这里我使用了GLM4，我想配置一个`GLM4-9b-chat`
```bash
git clone https://github.com/THUDM/GLM-4.git
cd GLM-4/basic_demo
pip install -r requirements.txt
pip install peft
```
#### 模型下载
模型你可以在这里找到：[Modelscope](https://www.modelscope.cn/models/ZhipuAI/glm-4-9b-chat/files)，lfs你可以在这里找到他的安装教程[git lfs](https://packagecloud.io/github/git-lfs/install)
```bash
# 如果你没有安装git lfs
apt install git-lfs
# 这个位置是模型的默认位置
mkdir THUDM
cd THUDM
# 检测是否安装成功
git lfs install
# 使用lfs下载
git clone https://www.modelscope.cn/ZhipuAI/glm-4-9b-chat.git
```
## 开始
### 直接运行
我尝试了直接运行所有模型，你但是效果非常差，速度很慢。你可以在仓库下运行：
```bash
# 注意你的运行位置
(base) root@ChatGLM:~/GLM-4$ python basic_demo/trans_cli_demo.py
```
来尝试模型的效果，但是这份代码是不会进行量化的。

### INT4量化
我这里放两份我成功运行的INT4量化代码，你可以尝试修改它并运行。
#### basic_demo/trans_cli_demo.py
```git
(base) root@ChatGLM:~/GLM-4# git diff basic_demo/trans_cli_demo.py  
diff --git a/basic_demo/trans_cli_demo.py b/basic_demo/trans_cli_demo.py  
index cbd0ba0..98790b5 100644  
--- a/basic_demo/trans_cli_demo.py  
+++ b/basic_demo/trans_cli_demo.py  
@@ -15,7 +15,7 @@ If you use flash attention, you should install the flash-attn and  add attn_impl  
import os  
import torch  
from threading import Thread  
-from transformers import AutoTokenizer, StoppingCriteria, StoppingCriteriaList, TextIteratorStreamer, AutoModel  
+from transformers import AutoTokenizer, StoppingCriteria, StoppingCriteriaList, TextIteratorStreamer, AutoModel, BitsAndBytes  
Config  
   
MODEL_PATH = os.environ.get('MODEL_PATH', 'THUDM/glm-4-9b-chat')  
   
@@ -46,8 +46,10 @@ tokenizer = AutoTokenizer.from_pretrained(  
model = AutoModel.from_pretrained(  
    MODEL_PATH,  
    trust_remote_code=True,  
-    # attn_implementation="flash_attention_2", # Use Flash Attention  
-    # torch_dtype=torch.bfloat16, #using flash-attn must use bfloat16 or float16  
+    #attn_implementation="flash_attention_2", # Use Flash Attention  
+    quantization_config=BitsAndBytesConfig(load_in_4bit=True),  
+    low_cpu_mem_usage=True,  
+    torch_dtype=torch.bfloat16, #using flash-attn must use bfloat16 or float16  
    device_map="auto").eval()
```
成功运行大概是这样的：
![](../../assets/images/Pasted%20image%2020240917232107.png)
#### basic_demo/trans_web_demo.py
```git
(base) root@ChatGLM:~/GLM-4# git diff basic_demo/trans_web_demo.py  
diff --git a/basic_demo/trans_web_demo.py b/basic_demo/trans_web_demo.py  
diff --git a/basic_demo/trans_web_demo.py b/basic_demo/trans_web_demo.py  
index 1a470de..a85b4bd 100644  
--- a/basic_demo/trans_web_demo.py  
+++ b/basic_demo/trans_web_demo.py  
@@ -21,7 +21,9 @@ from transformers import (  
    PreTrainedTokenizerFast,  
    StoppingCriteria,  
    StoppingCriteriaList,  
-    TextIteratorStreamer  
+    TextIteratorStreamer,  
+    AutoModel,  
+    BitsAndBytesConfig  
)  
   
ModelType = Union[PreTrainedModel, PeftModelForCausalLM]  
@@ -35,27 +37,44 @@ def _resolve_path(path: Union[str, Path]) -> Path:  
    return Path(path).expanduser().resolve()  
   
   
-def load_model_and_tokenizer(  
-        model_dir: Union[str, Path], trust_remote_code: bool = True  
-) -> tuple[ModelType, TokenizerType]:  
-    model_dir = _resolve_path(model_dir)  
-    if (model_dir / 'adapter_config.json').exists():  
-        model = AutoPeftModelForCausalLM.from_pretrained(  
-            model_dir, trust_remote_code=trust_remote_code, device_map='auto'  
-        )  
-        tokenizer_dir = model.peft_config['default'].base_model_name_or_path  
-    else:  
-        model = AutoModelForCausalLM.from_pretrained(  
-            model_dir, trust_remote_code=trust_remote_code, device_map='auto'  
-        )  
-        tokenizer_dir = model_dir  
-    tokenizer = AutoTokenizer.from_pretrained(  
-        tokenizer_dir, trust_remote_code=trust_remote_code, use_fast=False  
-    )  
-    return model, tokenizer  
-  
+#def load_model_and_tokenizer(  
+#        model_dir: Union[str, Path], trust_remote_code: bool = True  
+#) -> tuple[ModelType, TokenizerType]:  
+#    model_dir = _resolve_path(model_dir)  
+#    if (model_dir / 'adapter_config.json').exists():  
+#        model = AutoPeftModelForCausalLM.from_pretrained(  
+#            model_dir, trust_remote_code=trust_remote_code, device_map='auto'  
+#        )  
+#        tokenizer_dir = model.peft_config['default'].base_model_name_or_path  
+#    else:  
+#        model = AutoModelForCausalLM.from_pretrained(  
+#            model_dir, trust_remote_code=trust_remote_code, device_map='auto'  
+#            #model_dir, trust_remote_code=trust_remote_code, device_map='auto',  
+#            #quantization_config=BitsAndBytesConfig(load_in_4bit=True),  
+#            #low_cpu_mem_usage=False,  
+#        )  
+#        tokenizer_dir = model_dir  
+#    tokenizer = AutoTokenizer.from_pretrained(  
+#        tokenizer_dir, trust_remote_code=trust_remote_code, use_fast=False  
+#    )  
+#    return model, tokenizer  
+#  
+#  
+#model, tokenizer = load_model_and_tokenizer(MODEL_PATH, trust_remote_code=True)  
+tokenizer = AutoTokenizer.from_pretrained(  
+    MODEL_PATH,  
+    trust_remote_code=True,  
+    encode_special_tokens=True  
+)  
   
-model, tokenizer = load_model_and_tokenizer(MODEL_PATH, trust_remote_code=True)  
+model = AutoModel.from_pretrained(  
+    MODEL_PATH,  
+    trust_remote_code=True,  
+    #attn_implementation="flash_attention_2", # Use Flash Attention  
+    quantization_config=BitsAndBytesConfig(load_in_4bit=True),  
+    low_cpu_mem_usage=True,  
+    torch_dtype=torch.bfloat16, #using flash-attn must use bfloat16 or float16  
+    device_map="auto").eval()
```
这个运行结果大概是这样的：

![](../../assets/images/Pasted%20image%2020240917232652.png)
