# EEG Models 学习笔记

> 本笔记记录与 Siyu 的对话内容，包含 EEG 深度学习模型的理解与实践。

***

## Q1: Terminal #156-167 中的 shape 具体含义

### 问题

Terminal 中显示了多个模型的输入输出 shape：

```
EEGNet input shape: torch.Size([16, 64, 128, 1]), output shape: torch.Size([16, 4])
EEGNet_SSVEP input shape: torch.Size([16, 8, 256, 1]), output shape: torch.Size([16, 12])
DeepConvNet input shape: torch.Size([16, 64, 128, 1]), output shape: torch.Size([16, 4])
ShallowConvNet input shape: torch.Size([16, 64, 128, 1]), output shape: torch.Size([16, 4])
```

### 解答

#### 输入形状格式

`(batch_size, channels, samples, 1)` — 标准 4D 张量格式

| 维度 | 含义          | EEGNet/DeepConvNet/ShallowConvNet | EEGNet\_SSVEP   |
| -- | ----------- | --------------------------------- | --------------- |
| 0  | batch\_size | 16 (每次处理16个样本)                    | 16              |
| 1  | channels    | 64 (64个EEG通道/电极)                  | 8 (8个SSVEP刺激通道) |
| 2  | samples     | 128 (128个时间采样点)                   | 256 (256个采样点)   |
| 3  | 恒为1         | 单通道(灰度图格式)                        | 单通道             |

#### 输出形状格式

`(batch_size, num_classes)`

| 模型             | num\_classes | 用途           |
| -------------- | ------------ | ------------ |
| EEGNet         | 4            | 4类分类任务       |
| DeepConvNet    | 4            | 4类分类任务       |
| ShallowConvNet | 4            | 4类分类任务       |
| EEGNet\_SSVEP  | 12           | 12类SSVEP目标识别 |

#### 具体示例：EEGNet

```
输入: torch.Size([16, 64, 128, 1])
     └─ 16个样本 × 64通道 × 128时间点 × 1(单通道)

输出: torch.Size([16, 4])
     └─ 16个样本 × 4个类别概率
```

***

## Q2: 四类分类任务和12类SSVEP目标识别的区别

### 问题

能为我说明一下这个4类分类任务和12类SSVEP目标识别任务吗？

### 解答

### 2.1 四类 ERP 分类任务

#### 任务描述

四类 ERP (Event-Related Potential) 分类任务是 **听觉/视觉事件相关电位** 分类实验。

#### 四类具体定义

| 类别 | 全称             | 刺激类型    | 描述        |
| -- | -------------- | ------- | --------- |
| LA | Left Auditory  | 左耳听觉刺激  | 左耳接受声刺激   |
| RA | Right Auditory | 右耳听觉刺激  | 右耳接受声刺激   |
| LV | Left Visual    | 左视野视觉刺激 | 视野左侧接受光刺激 |
| RV | Right Visual   | 右视野视觉刺激 | 视野右侧接受光刺激 |

#### 实验设置

- **数据来源**: MNE Python 包提供的 sample 数据集
- **采样率**: 128 Hz
- **时间窗口**: tmin=0s, tmax=1s (刺激前0秒到刺激后1秒)
- **通道数**: 64 个 EEG 通道
- **样本点**: 128 个时间点 (1秒 × 128Hz)

#### 数据形状

```
输入: (batch_size, 64, 128, 1)
输出: (batch_size, 4)
```

***

### 2.2 SSVEP 目标识别任务

#### 任务描述

SSVEP (Steady-State Visual Evoked Potential) — 稳态视觉诱发电位任务

当受试者注视不同频率的闪烁刺激时，大脑视觉皮层会产生与刺激频率同步的响应。通过检测这种稳态响应，可以识别受试者正在注视的目标。

#### 目标数量

**12 类目标识别**

#### 刺激频率设计

典型的 12 类 SSVEP 实验频率范围:

| 频段  | 频率范围     | 示例 (Hz)                      |
| --- | -------- | ---------------------------- |
| 低频段 | 8-12 Hz  | 8.0, 9.0, 10.0, 11.0, 12.0   |
| 中频段 | 12-20 Hz | 13.0, 14.0, 15.0, 16.0, 17.0 |
| 高频段 | 20-30 Hz | 18.0, 20.0, 22.0, 25.0, 28.0 |

#### 实验设置

- **采样率**: 256 Hz 或更高
- **时间窗口**: 通常 1-5 秒
- **通道数**: 8 个 (枕叶区域主要记录点)
- **样本点**: 256 个时间点

#### SSVEP 信号特点

1. **周期性响应**: 信号包含与刺激频率及其谐波相关的能量
2. **信噪比**: SSVEP 信号的信噪比相对较高
3. **频率编码**: 不同目标通过不同频率区分
4. **训练需求**: 需针对个体校准以获得最佳性能

***

### 2.3 核心差异对比

| 特征    | 4类 ERP         | 12类 SSVEP  |
| ----- | -------------- | ---------- |
| 编码方式  | 空间位置(左右耳/左右视野) | 频率编码(不同Hz) |
| 信号类型  | 瞬态ERP          | 稳态SSVEP    |
| 通道数   | 64             | 8          |
| 时间分辨率 | 128点           | 256点       |

***

## Q3: examples/EEGModels\_PyTorch.py 的 Purpose

### 问题

examples/EEGModels\_PyTorch.py 这个 EEGModels 的 purpose 是什么？

### 解答

#### 核心定位

这是 **ARL EEGModels 的 PyTorch 实现版本**，将原始 Keras/TensorFlow 代码转换为 PyTorch 版本，让 PyTorch 用户也能使用这些 EEG 分类模型。

#### 包含的模型

| 模型                 | 用途                  | 状态   |
| ------------------ | ------------------- | ---- |
| **EEGNet**         | 通用 EEG 分类（ERP、SMR等） | 主力模型 |
| **EEGNet\_SSVEP**  | SSVEP 目标识别（12类）     | 专用变体 |
| **EEGNet\_old**    | 早期版本                | 已弃用  |
| **DeepConvNet**    | 深度卷积网络              | 辅助模型 |
| **ShallowConvNet** | 浅层卷积网络              | 辅助模型 |

#### 使用方式

虽然文件在 `examples/` 目录下，但它是作为**模型库被导入使用**：

```python
from EEGModels_PyTorch import EEGNet, DeepConvNet, ShallowConvNet

model = EEGNet(nb_classes=4, Chans=64, Samples=128)
```

***

## Q4: EEGModels\_PyTorch.py 的输入输出、原理、作用

### 问题

它的输入和输出是什么？原理是什么？作用是什么？

### 解答

#### 4.1 输入输出

##### EEGNet (通用模型)

| 项目     | 格式                                | 示例值                |
| ------ | --------------------------------- | ------------------ |
| **输入** | `(batch_size, Chans, Samples, 1)` | `(16, 64, 128, 1)` |
| **输出** | `(batch_size, nb_classes)`        | `(16, 4)`          |

##### EEGNet\_SSVEP (SSVEP专用)

| 项目     | 格式                                | 示例值               |
| ------ | --------------------------------- | ----------------- |
| **输入** | `(batch_size, Chans, Samples, 1)` | `(16, 8, 256, 1)` |
| **输出** | `(batch_size, nb_classes)`        | `(16, 12)`        |

***

#### 4.2 工作原理

以 **EEGNet** 为例，采用**两阶段卷积 + 分类器**架构：

```
输入 EEG → [Block 1: 时间和空间特征提取] → [Block 2: 可分离卷积] → [全连接层] → 类别概率
```

##### Block 1: 时间和空间特征提取

```python
# 1. 时间卷积 - 提取每个通道的时间模式
self.conv2d_1 = nn.Conv2d(1, F1, kernel_size=(1, kernLength))
# 输入: (16, 1, 64, 128) → 输出: (16, 8, 64, 128)

# 2. 深度卷积 - 学习空间滤波器(类似CSP)
self.depthwise_conv = DepthwiseConv2d(F1, depth_multiplier=D, kernel_size=(Chans, 1))
# 输出: (16, 16, 1, 128)  - 每个时间点压缩为空间特征

# 3. 池化 + Dropout
self.avg_pool_1 = nn.AvgPool2d(kernel_size=(1, 4))  # 降维
```

##### Block 2: 可分离卷积

```python
# 深度可分离卷积 = 逐通道空间卷积 + 逐点1x1卷积
self.separable_conv = SeparableConv2d(F1*D, F2, kernel_size=(1, 16))
# 进一步融合时间和空间信息
```

##### 分类器

```python
self.dense = nn.Linear(F2 * (Samples // 32), nb_classes)  # 全连接 + softmax
```

***

#### 4.3 核心设计思想

| 概念                     | 说明             | 类比               |
| ---------------------- | -------------- | ---------------- |
| **Depthwise Conv**     | 学习空间滤波器（类似CSP） | 独立学习每个时间滤波器的空间模式 |
| **Separable Conv**     | 时间+空间分离卷积      | 先分析时间模式，再组合空间模式  |
| **MaxNorm Constraint** | 权重范数约束 ≤ 1.0   | 防止过拟合，提高泛化能力     |
| **ELU激活**              | 指数线性单元         | 适合EEG这类稀疏信号      |

***

#### 4.4 作用/功能

```
EEG信号 ──→ 特征自动提取 ──→ 分类 ──→ 预测类别

具体任务:
├── 4类 ERP 分类: 区分 左耳/右耳/左视野/右视野 刺激
├── 12类 SSVEP: 识别受试者注视的12个不同频率刺激目标
└── SMR/BCI: 运动想象分类
```

***

#### 4.5 与传统方法对比

| 方法         | 特征提取             | 分类器     |
| ---------- | ---------------- | ------- |
| **传统BCI**  | 人工设计 (频带功率、CSP等) | SVM/LDA |
| **EEGNet** | 自动学习时间和空间滤波器     | 端到端训练   |

**EEGNet 优势**: 无需人工特征工程，自动从原始EEG学习最优表示。

***

## Q5: 数据如何体现时间模式和空间模式

### 问题

数据是如何体现时间模式和空间模式的？

### 解答

#### 5.1 EEG数据的本质

```
EEG数据形状: (batch_size, Chans, Samples, 1)
                = (样本数, 通道数, 时间点, 1)
                = (16,       64,     128,    1)
```

**三个维度代表不同信息**：

| 维度            | 索引   | 含义                 |
| ------------- | ---- | ------------------ |
| `Chans=64`    | 空间位置 | 64个电极在不同头皮位置记录     |
| `Samples=128` | 时间序列 | 128个采样点 = 1秒@128Hz |

***

#### 5.2 时间模式：如何提取

**时间卷积核** `(1, kernLength=64)` — 沿着 **时间轴** 滑动

```python
self.conv2d_1 = nn.Conv2d(1, F1, kernel_size=(1, 64))
# kernel_size=(1, 64): 高度=1(不跨通道), 宽度=64(覆盖64个时间点)
```

**数据流动**：

```
原始: (16, 64, 128, 1)
      └─ 时间维度: 128个点 ─┘
           ↓ 时间卷积核(1×64)
特征图: (16, 64, F1, 128)
      └─ 每个通道都学到 F1=8 个不同的时间滤波器
```

**时间模式的物理意义**：

- α波 (8-12Hz) 的 α节律
- β波 (13-30Hz) 的运动相关 desynchronization
- P300 等事件相关成分

***

#### 5.3 空间模式：如何提取

**深度卷积核** `(Chans, 1)` — 沿着 **通道轴** 滑动

```python
self.depthwise_conv = DepthwiseConv2d(F1, depth_multiplier=D, kernel_size=(64, 1))
# kernel_size=(64, 1): 高度=64(覆盖所有通道), 宽度=1(不跨时间)
```

**数据流动**：

```
输入: (16, 64, F1, 128)  ← 时间卷积后的特征
      └─ 64个通道空间分布
           ↓ 空间深度卷积 (D=2, 所以 F1*D=16)
特征图: (16, 1, 16, 128)  ← 每个时间点压缩为16维空间特征
```

**空间模式的物理意义**：

- C3/Cz/C4 电极的 motor cortex 活动
- Oz 电极的视觉皮层活动
- 空间滤波器 = 学习"哪些电极组合最相关"

***

#### 5.4 可视化理解

*siyu: 我喜欢这个example！*

```
时间模式提取 (沿 Samples 轴):

电极1: [▓▓▓░░▓▓▓░░▓▓▓░░▓▓▓░░▓▓...]  ← 时间滤波器检测的波形模式
电极2: [░░▓▓▓░░▓▓▓░░▓▓▓░░▓▓▓░░▓...]
电极3: [▓▓▓░░▓▓▓░░▓▓▓░░▓▓▓░░▓▓...]
         ↑
      时间卷积核(64点)

空间模式提取 (沿 Chans 轴):

时间点1: [电极1, 电极2, 电极3, ... 电极64]  ← 64维空间向量
          ↓ 空间滤波器1: w=[0.2, -0.1, 0.5, ...]
          → 空间特征值1

时间点2: [电极1, 电极2, 电极3, ... 电极64]
          ↓ 空间滤波器2: w=[-0.3, 0.4, 0.1, ...]
          → 空间特征值2
```

***

#### 5.5 总结

| 操作        | 卷积核               | 作用维度      | 提取什么                 |
| --------- | ----------------- | --------- | -------------------- |
| **时间卷积**  | `(1, kernLength)` | 沿 Samples | 时间滤波器：检测特定频率/事件的时间模式 |
| **深度卷积**  | `(Chans, 1)`      | 沿 Chans   | 空间滤波器：检测特定头皮区域的空间分布  |
| **可分离卷积** | `(1, 16)`         | 混合        | 进一步融合时间和空间信息         |

***

## Q6: EEGNet forward() 工作流程详解

### 问题

请解释 EEGNet 的 forward() 函数的工作流程。

### 解答

#### 完整数据流动过程

```python
def forward(self, x):
    # ============ 输入格式转换 ============
    # (batch, Chans, Samples, 1) -> (batch, 1, Chans, Samples)
    if x.dim() == 4 and x.shape[-1] == 1:
        x = x.permute(0, 3, 1, 2)
    
    # ============ Block 1: 时间和空间特征提取 ============
    x = self.conv2d_1(x)      # 时间卷积
    x = self.bn_1(x)          # 批归一化
    x = self.depthwise_conv(x) # 空间深度卷积
    x = self.bn_2(x)          # 批归一化
    x = F.elu(x)              # 激活函数
    x = self.avg_pool_1(x)    # 池化降维
    x = self.dropout_1(x)     # Dropout
    
    # ============ Block 2: 可分离卷积 ============
    x = self.separable_conv(x) # 深度可分离卷积
    x = self.bn_3(x)          # 批归一化
    x = F.elu(x)              # 激活函数
    x = self.avg_pool_2(x)    # 池化降维
    x = self.dropout_2(x)     # Dropout
    
    # ============ 分类器 ============
    x = self.flatten(x)       # 展平
    x = self.dense(x)         # 全连接
    x = F.softmax(x, dim=1)   # 分类概率
    
    return x
```

***

#### 各阶段 Shape 变化

以 `EEGNet(nb_classes=4, Chans=64, Samples=128)` 为例：

```
输入:              (16, 64, 128, 1)
   ↓ permute
                  (16, 1, 64, 128)
   
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
           Block 1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ↓ conv2d_1     (16, 1, 64, 128) → (16, 8, 64, 128)  [F1=8个时间滤波器]
   ↓ bn_1         shape不变
   ↓ depthwise    (16, 8, 64, 128) → (16, 16, 1, 128)   [D=2, 空间压缩]
   ↓ bn_2         shape不变
   ↓ elu          shape不变
   ↓ avg_pool_1   (16, 16, 1, 128) → (16, 16, 1, 32)    [4倍降采样]
   ↓ dropout_1    shape不变

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
           Block 2
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ↓ separable    (16, 16, 1, 32) → (16, 16, 1, 32)     [通道数不变]
   ↓ bn_3         shape不变
   ↓ elu          shape不变
   ↓ avg_pool_2   (16, 16, 1, 32) → (16, 16, 1, 4)     [8倍降采样]
   ↓ dropout_2    shape不变

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
         Classifier
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

   ↓ flatten      (16, 16, 1, 4) → (16, 64)
   ↓ dense        (16, 64) → (16, 4)                      [4类输出]
   ↓ softmax      shape不变 → (16, 4)                     [概率分布]
```

***

#### 各层作用总结

| 阶段 | 层 | 作用 |
|------|-----|------|
| **输入转换** | `permute` | `(B,C,H,W)` → `(B,1,C,S)` 适配PyTorch卷积 |
| **Block 1** | `conv2d_1` | **时间卷积**: 提取每个通道的时间模式 (8个滤波器) |
| | `depthwise_conv` | **空间卷积**: 学习通道间空间模式 (16个空间滤波器) |
| | `avg_pool_1` | 降维 4×，减少参数 |
| **Block 2** | `separable_conv` | **可分离卷积**: 进一步融合时空特征 |
| | `avg_pool_2` | 降维 8× |
| **分类** | `dense` | 全连接输出4类 |
| | `softmax` | 转为概率分布 |

***

## Q7: dropoutRate=0.5 的作用

### 问题

`dropoutRate=0.5` 的作用是什么？为什么要考虑 dropout？

### 解答

#### 什么是 Dropout？

Dropout 是一种 **正则化技术**，在训练时随机"丢弃"（置零）部分神经元，防止网络过度依赖某些特定神经元。

```
训练时:
┌─────────────────────────────────────────┐
│  Full Network          Dropout Applied   │
│                                         │
│    ○──○──○──○          ○──○──╳──○      │
│    │  │  │  │    →      │  │  │  │      │
│    ○──○──○──○          ○──╳──○──○      │
│    │  │  │  │          │  │  │  │      │
│    ○──○──○──○          ○──○──○──╳      │
└─────────────────────────────────────────┘

推理时:
  使用完整网络（所有神经元参与）
```

***

#### 为什么要用 Dropout？

| 问题 | 原因 | Dropout 的作用 |
|------|------|----------------|
| **过拟合** | 训练数据有限，网络记住了噪声 | 强迫网络学习更鲁棒的特征 |
| **神经元共适应** | 某些神经元总是同时激活 | 打破这种依赖，让每个神经元独立学习 |
| **泛化能力差** | 在新数据上表现差 | 提高模型在新数据上的适应能力 |

***

#### `dropoutRate=0.5` 的含义

```python
dropoutRate=0.5  # 50% 的神经元被随机丢弃
```

```
每层神经元:
○ ○ ○ ○ ○ ○ ○ ○  (8个神经元)
    ↓ 随机丢弃50%
○ ╳ ○ ╳ ○ ○ ╳ ○  (4个存活, 4个被置零)
```

***

#### Dropout 在 EEGNet 中的位置

```python
# Block 1 后
self.dropout_1 = self.dropout_type(dropoutRate)  # 0.5 → 50%丢弃

# Block 2 后  
self.dropout_2 = self.dropout_type(dropoutRate)  # 0.5 → 50%丢弃
```

***

#### 不同 Dropout Rate 的效果

| Rate | 效果 | 适用场景 |
|------|------|----------|
| **0.1-0.2** | 轻微正则化 | 数据充足，简单任务 |
| **0.3-0.5** | 中等正则化 | 标准设置，推荐用于EEG |
| **0.5-0.7** | 强正则化 | 数据少，容易过拟合时 |
| **>0.7** | 过强 | 可能欠拟合 |

***

#### 简单总结

> `dropoutRate=0.5` 的目的是：**防止过拟合，让模型学到更普适的特征**
>
> EEG 数据通常样本量有限，Dropout 尤为重要。

***

## Q8: Block 2 SeparableConv2d 可分离卷积详解

### 问题

我还是不是很能理解 block2 的含义和作用，能结合代码为我详细解释说明一下吗？

### 解答

#### SeparableConv2d 的内部结构

SeparableConv2d = **Depthwise** + **Pointwise** 两步卷积：

```python
class SeparableConv2d(nn.Module):
    def __init__(self, in_channels, out_channels, kernel_size=(1, 16), ...):
        # 步骤1: Depthwise - 逐通道卷积，不混合通道
        self.depthwise = nn.Conv2d(
            in_channels, in_channels,      # 输入=输出通道数
            kernel_size=(1, 16),
            groups=in_channels,             # 关键：分组卷积
            bias=False
        )
        
        # 步骤2: Pointwise - 1x1逐点卷积，混合通道
        self.pointwise = nn.Conv2d(
            in_channels, out_channels,     # 通道变换
            kernel_size=(1, 1),              # 1x1卷积
            bias=False
        )
    
    def forward(self, x):
        x = self.depthwise(x)  # 先深度卷积
        x = self.pointwise(x)  # 再逐点卷积
        return x
```

***

#### 数据流动详解

**输入 Block 2**: Block 1 的输出
```
输入: (16, 16, 1, 32)
      └─ (batch, F1*D=16通道, 1高度, 32时间点)
```

##### Step 1: Depthwise 卷积 `(1, 16)` 沿时间维度

```python
self.depthwise = nn.Conv2d(16, 16, kernel_size=(1, 16), groups=16)
# groups=16 意味着：每个输入通道独立卷积，不跨通道混合
```

```
Channel 1:  [░░░░▓▓▓░░░░░░▓▓▓░░░░░]  →  输出1
Channel 2:  [▓▓▓░░░░▓▓▓░░░░▓▓▓░░░░]  →  输出2
Channel 3:  [░░▓▓▓░░░░░░▓▓▓░░░░░░▓]  →  输出3
... (每个通道独立处理)
Channel 16: [▓░░▓▓░░░▓▓▓░░░▓▓░░▓▓░]  →  输出16

结果: (16, 16, 1, 32→17)  ← 时间维卷积后变小, padding=(0,8)补偿
```

**作用**: 在**每个通道内部**分析时间模式，学习时间滤波器

##### Step 2: Pointwise 卷积 `(1, 1)` 混合通道

```python
self.pointwise = nn.Conv2d(16, 16, kernel_size=(1, 1))
```

```
时间点1的16通道: [ch1, ch2, ch3, ... ch16]
                          ↓ 1x1卷积核
                 融合为1个值 (所有通道信息的加权组合)

时间点2的16通道: [ch1, ch2, ch3, ... ch16]
                          ↓ 1x1卷积核  
                 融合为1个值

结果: (16, 16, 1, 17)  ← 通道数保持，但信息已融合
```

**作用**: **跨通道混合**，将不同空间滤波器的响应组合

***

#### 为什么要分离？

```
标准卷积:          可分离卷积:
┌─────────────┐    ┌─────────────┐
│  所有通道    │    │  Depthwise  │ → 每个通道独立时间分析
│  同时参与    │    │  (分组)     │
│  (Chans×16) │    ├─────────────┤
│             │    │  Pointwise  │ → 1x1混合通道
└─────────────┘    │  (1x1)      │
                   └─────────────┘

参数量对比:
标准卷积: 16输入 × 16输出 × 1×16 kernel = 4096 参数
可分离:   16×1×16 + 16×1×1 = 272 参数  (减少15倍!)
```

***

#### Block 2 的物理意义

```
Block 1 输出 (16个空间特征):
┌──────────────────────────────────────────────┐
│  每个时间点有16个值，代表不同"空间滤波器"的响应 │
│                                               │
│  时间点 t: [f1, f2, f3, f4, ... f16]         │
│             └─ f1=Cz附近活动                   │
│             └─ f2=视觉区活动                   │
│             └─ f3=运动区活动                   │
└──────────────────────────────────────────────┘

Block 2 的 SeparableConv 做什么？

1. Depthwise: 分析每个空间滤波器的时间演变
   f1: [0.1, 0.3, 0.8, 0.2, ...] → 时间模式1
   f2: [0.2, 0.1, 0.4, 0.9, ...] → 时间模式2
   ...

2. Pointwise: 组合不同空间特征
   新特征 = w1×时间模式1 + w2×时间模式2 + ...
   → 学习"哪些空间+时间组合最区分类别"
```

***

#### 总结

| 阶段 | 操作 | 输入→输出 | 核心作用 |
|------|------|----------|----------|
| Block 1 | conv2d + depthwise | `(B,64,H,128)`→`(B,16,H,32)` | 学习时间和空间特征 |
| Block 2 | separable_conv | `(B,16,H,32)`→`(B,16,H,17)` | **融合和优化时空特征** |
| Block 2 | avg_pool | `(B,16,H,17)`→`(B,16,H,2)` | 进一步降维 |

**Block 2 的核心价值**: 进一步提炼特征，将 Block 1 学到的16个空间滤波器响应组合成最终用于分类的特征表示。

***

## 相关文件

| 文件                        | 说明                     |
| ------------------------- | ---------------------- |
| `EEGModels_PyTorch.py`    | PyTorch 实现的 EEG 模型库    |
| `EEGModels.py`            | 原始 Keras/TensorFlow 版本 |
| `experiments.md`          | 实验配置文件                 |
| `examples/ERP.py`         | Keras 版 ERP 训练示例       |
| `examples/ERP_PyTorch.py` | PyTorch 版 ERP 训练示例     |

***

## 参考文献

1. Lawhern et al. (2018). EEGNet: a compact convolutional neural network for EEG-based brain-computer interfaces. *Journal of Neural Engineering*, 15(5), 056013.
2. Waytowich et al. (2018). Compact convolutional neural networks for classification of asynchronous steady-state visual evoked potentials. *Journal of Neural Engineering*, 15(6), 066031.
3. Schirrmeister et al. (2017). Deep learning with convolutional neural networks for EEG decoding and visualization. *Human Brain Mapping*, 38(11), 5391-5420.
