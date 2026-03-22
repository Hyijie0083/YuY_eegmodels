# EEGModels.py 文件说明文档

## 概述

`EEGModels.py` 是一个基于 **Keras 和 TensorFlow** 的脑电信号（EEG）深度学习模型集合库。该库提供了多种专门用于脑电信号处理和分类的卷积神经网络（CNN）架构，包括 EEGNet、DeepConvNet 和 ShallowConvNet 等经典模型。

---

## 环境要求

| 依赖库 | 版本要求 |
|--------|---------|
| TensorFlow | 2.X (已验证 2.0 - 2.3) |
| MNE | >= 0.17.1 (用于ERP分类示例) |
| PyRiemann | >= 0.2.5 |
| scikit-learn | >= 0.20.1 |
| matplotlib | >= 2.2.3 |

---

## 使用方法

```python
# 导入模型
from EEGModels import EEGNet

# 创建模型实例
model = EEGNet(nb_classes=4, Chans=64, Samples=128)

# 编译模型
model.compile(loss='categorical_crossentropy', 
              optimizer='adam', 
              metrics=['accuracy'])

# 训练和预测
fitted = model.fit(X_train, Y_train, ...)
predicted = model.predict(X_test)
```

---

## 模型架构详解

### 1. EEGNet (推荐模型)

**论文引用**: http://iopscience.iop.org/article/10.1088/1741-2552/aace8c/meta

EEGNet 是该库的核心模型，采用了最新的架构设计（非arxiv上的v1/v2旧版本），具有以下特点：

#### 核心创新点

1. **深度可分离卷积 (Depthwise Convolutions)**
   - 学习时间卷积内的空间滤波器
   - 使用 `depth_multiplier` 参数控制空间滤波器数量
   - 类似 FBCSP 算法，在每个时间滤波器内学习空间滤波器
   - 限制自由参数数量，避免过拟合

2. **可分离卷积 (Separable Convolutions)**
   - 深度卷积后接 (1×1) 点卷积
   - 学习如何最优地组合跨时间带的空间滤波器

#### 函数签名

```python
def EEGNet(nb_classes, Chans=64, Samples=128, 
           dropoutRate=0.5, kernLength=64, F1=8, 
           D=2, F2=16, norm_rate=0.25, dropoutType='Dropout'):
```

#### 参数说明

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `nb_classes` | int | - | 分类类别数 |
| `Chans` | int | 64 | EEG通道数 |
| `Samples` | int | 128 | 时间采样点数 |
| `dropoutRate` | float | 0.5 | Dropout比率 |
| `kernLength` | int | 64 | 第一层时间卷积核长度（建议设为采样率的一半） |
| `F1` | int | 8 | 时间滤波器数量 |
| `D` | int | 2 | 每个时间卷积内的空间滤波器数量（空间滤波器数 = F1 × D） |
| `F2` | int | 16 | 点卷积滤波器数量（默认 F2 = F1 × D） |
| `norm_rate` | float | 0.25 | 全连接层权重约束 |
| `dropoutType` | str | 'Dropout' | Dropout类型：'Dropout' 或 'SpatialDropout2D' |

#### 网络架构图

```
输入: (batch, Chans, Samples, 1)
    │
    ▼
┌─────────────────────────────────────┐
│ Block 1                             │
│ ├─ Conv2D(F1, (1, kernLength))     │  # 时间卷积
│ ├─ BatchNormalization              │
│ ├─ DepthwiseConv2D((Chans, 1), D)  │  # 深度空间卷积
│ ├─ BatchNormalization              │
│ ├─ Activation('elu')               │
│ ├─ AveragePooling2D((1, 4))        │
│ └─ Dropout(dropoutRate)            │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ Block 2                             │
│ ├─ SeparableConv2D(F2, (1, 16))    │  # 可分离卷积
│ ├─ BatchNormalization              │
│ ├─ Activation('elu')               │
│ ├─ AveragePooling2D((1, 8))        │
│ └─ Dropout(dropoutRate)            │
└─────────────────────────────────────┘
    │
    ▼
Flatten
    │
    ▼
Dense(nb_classes, kernel_constraint=max_norm(norm_rate))
    │
    ▼
Activation('softmax')
    │
输出: (batch, nb_classes)
```

#### 默认配置 (EEGNet-8,2)

默认参数 `F1=8, D=2` 对应论文中的 **EEGNet-8,2** 模型，这是推荐的起始配置。

#### Dropout 类型选择建议

- **Dropout**: 默认推荐，适用于大多数情况
- **SpatialDropout2D**: 在ERP信号分类中有时效果略好，但在振荡数据集（如SMR、BCI-IV Dataset 2A）上性能显著下降

---

### 2. EEGNet_SSVEP (SSVEP专用变体)

**论文引用**: Waytowich et al. (2018), Journal of Neural Engineering
http://iopscience.iop.org/article/10.1088/1741-2552/aae5d8

专门针对**稳态视觉诱发电位 (SSVEP)** 分类任务优化的 EEGNet 变体。

#### 函数签名

```python
def EEGNet_SSVEP(nb_classes=12, Chans=8, Samples=256, 
                 dropoutRate=0.5, kernLength=256, F1=96, 
                 D=1, F2=96, dropoutType='Dropout'):
```

#### 与标准EEGNet的区别

| 参数 | EEGNet | EEGNet_SSVEP | 说明 |
|------|--------|--------------|------|
| `F1` | 8 | 96 | 更多时间滤波器 |
| `D` | 2 | 1 | 较少空间滤波器 |
| `F2` | 16 | 96 | 更多点卷积滤波器 |
| `kernLength` | 64 | 256 | 更长的卷积核 |

**架构相同，但针对SSVEP的高频特性调整了超参数。**

---

### 3. EEGNet_old (旧版本 - 不推荐)

**论文引用**: https://arxiv.org/abs/1611.08024v2

原始 EEGNet v1 架构，已不再推荐使用。新版本的 EEGNet 性能更好且性质更优。

#### 主要区别
- 使用 **striding** 替代 max-pooling 以提升分类性能和计算速度
- 架构较简单，但性能不如新版本

---

### 4. DeepConvNet (深度卷积网络)

**论文引用**: Schirrmeister et al. (2017), Human Brain Mapping

一个较深的卷积神经网络，包含4个卷积块。

#### 函数签名

```python
def DeepConvNet(nb_classes, Chans=64, Samples=256, dropoutRate=0.5):
```

#### 网络架构

```
输入: (batch, Chans, Samples, 1)
    │
    ▼
┌─────────────────────────────────────┐
│ Block 1                             │
│ ├─ Conv2D(25, (1, 5))              │
│ ├─ Conv2D(25, (Chans, 1))          │
│ ├─ BatchNormalization              │
│ ├─ Activation('elu')               │
│ ├─ MaxPooling2D((1, 2))            │
│ └─ Dropout                         │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ Block 2                             │
│ ├─ Conv2D(50, (1, 5))              │
│ ├─ BatchNormalization              │
│ ├─ Activation('elu')               │
│ ├─ MaxPooling2D((1, 2))            │
│ └─ Dropout                         │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ Block 3                             │
│ ├─ Conv2D(100, (1, 5))             │
│ ├─ BatchNormalization              │
│ ├─ Activation('elu')               │
│ ├─ MaxPooling2D((1, 2))            │
│ └─ Dropout                         │
└─────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────┐
│ Block 4                             │
│ ├─ Conv2D(200, (1, 5))             │
│ ├─ BatchNormalization              │
│ ├─ Activation('elu')               │
│ ├─ MaxPooling2D((1, 2))            │
│ └─ Dropout                         │
└─────────────────────────────────────┘
    │
    ▼
Flatten → Dense(nb_classes) → Softmax
```

#### 实现说明

- 假设输入为 **2秒 EEG 信号，采样率 128Hz**
- 使用 `max_norm` 约束所有卷积层和分类层
- 修改了 BatchNormalization 的默认参数（基于与原作者的私人交流）

**与原始论文的差异**:

| 参数 | 本实现 | 原始论文 |
|------|--------|----------|
| pool_size | (1, 2) | (1, 3) |
| strides | (1, 2) | (1, 3) |
| conv filters | (1, 5) | (1, 10) |

---

### 5. ShallowConvNet (浅层卷积网络)

**论文引用**: Schirrmeister et al. (2017), Human Brain Mapping

与 DeepConvNet 同论文提出的浅层网络，专门针对频带功率特征设计。

#### 函数签名

```python
def ShallowConvNet(nb_classes, Chans=64, Samples=128, dropoutRate=0.5):
```

#### 网络架构

```
输入: (batch, Chans, Samples, 1)
    │
    ▼
┌─────────────────────────────────────┐
│ Block 1                             │
│ ├─ Conv2D(40, (1, 13))             │  # 时间卷积
│ ├─ Conv2D(40, (Chans, 1))          │  # 空间卷积
│ ├─ BatchNormalization              │
│ ├─ Activation(square)              │  # 平方激活
│ ├─ AveragePooling2D((1, 35))       │  # 平均池化
│ ├─ Activation(log)                 │  # 对数激活
│ └─ Dropout                         │
└─────────────────────────────────────┘
    │
    ▼
Flatten → Dense(nb_classes) → Softmax
```

#### 关键特点

1. **平方激活函数**: 提取信号功率
2. **对数激活函数**: 压缩动态范围
3. **大池化窗口**: (1, 35) 平均池化，对应频带特征提取

#### 实现说明

- 假设输入为 **2秒 EEG 信号，采样率 128Hz**
- 卷积核长度约为原始论文的一半（13 vs 25）
- 池化大小和步幅也相应调整

**与原始论文的差异**:

| 参数 | 本实现 | 原始论文 |
|------|--------|----------|
| pool_size | (1, 35) | (1, 75) |
| strides | (1, 7) | (1, 15) |
| conv filters | (1, 13) | (1, 25) |

#### 自定义激活函数

```python
def square(x):
    return K.square(x)

def log(x):
    return K.log(K.clip(x, min_value=1e-7, max_value=10000))
```

---

## 模型选择建议

| 应用场景 | 推荐模型 | 说明 |
|----------|----------|------|
| 通用ERP分类 | **EEGNet** | 轻量、高效、参数少 |
| SSVEP分类 | **EEGNet_SSVEP** | 针对SSVEP优化的超参数 |
| 需要深层特征 | **DeepConvNet** | 更深的网络，更多参数 |
| 频带功率特征 | **ShallowConvNet** | 专门设计用于频带特征 |
| 快速原型验证 | **EEGNet-8,2** | 默认配置，先尝试此模型 |

---

## 采样率适配说明

### EEGNet 采样率适配

EEGNet 默认假设输入信号采样率为 **128Hz**。如需用于其他采样率：

1. **调整卷积核长度**: `kernLength` 应约为采样率的一半
   - 128Hz → kernLength=64
   - 256Hz → kernLength=128

2. **调整池化大小**: 
   - Block 1: AveragePooling2D((1, 4))
   - Block 2: AveragePooling2D((1, 8))

3. **注意**: 上述规则未经充分测试，可能需要针对具体数据集进行调优

### DeepConvNet / ShallowConvNet 采样率适配

这两个模型也假设 **128Hz 采样率**。对于 250Hz 数据：
- 卷积核长度、池化大小和步幅需要相应加倍

---

## 许可证

本项目部分内容属于美国政府作品，不受国内版权保护（17 USC Sec. 105），采用 **CC0 1.0** 许可证全球发布。

其他部分内容受国内版权保护（17 USC Sec. 105），采用 **Apache 2.0** 许可证。

完整许可证文本见项目中的 LICENSE.TXT 文件。
