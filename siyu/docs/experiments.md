# EEG Classification Experiments

## 1. 四类 ERP 分类任务 (4-Class ERP Classification)

### 1.1 任务描述

四类 ERP (Event-Related Potential) 分类任务是 **听觉/视觉事件相关电位** 分类实验。

### 1.2 四类具体定义

| 类别 | 全称 | 刺激类型 | 描述 |
|------|------|----------|------|
| LA | Left Auditory | 左耳听觉刺激 | 左耳接受声刺激 |
| RA | Right Auditory | 右耳听觉刺激 | 右耳接受声刺激 |
| LV | Left Visual | 左视野视觉刺激 | 视野左侧接受光刺激 |
| RV | Right Visual | 右视野视觉刺激 | 视野右侧接受光刺激 |

### 1.3 实验设置

- **数据来源**: MNE Python 包提供的 sample 数据集
- **采样率**: 128 Hz
- **时间窗口**: tmin=0s, tmax=1s (刺激前0秒到刺激后1秒)
- **滤波**: 0-40 Hz 带通滤波
- **通道数**: 64 个 EEG 通道
- **样本点**: 128 个时间点 (1秒 × 128Hz)
- **每类试次**: 约 50-60 个 trials

### 1.4 数据形状

```
输入: (batch_size, 64, 128, 1)
     └─ [样本数, 通道数, 时间点, 1]

输出: (batch_size, 4)
     └─ [样本数, 4个类别概率]
```

### 1.5 评价指标

- 分类准确率 (Accuracy)
- 混淆矩阵 (Confusion Matrix)
- 可视化: MNE 采集系统和 ERP 波形

---

## 2. SSVEP 目标识别任务 (SSVEP Target Identification)

### 2.1 任务描述

SSVEP (Steady-State Visual Evoked Potential) — 稳态视觉诱发电位任务

当受试者注视不同频率的闪烁刺激时，大脑视觉皮层会产生与刺激频率同步的响应。通过检测这种稳态响应，可以识别受试者正在注视的目标。

### 2.2 目标数量

**12 类目标识别**

常见的 SSVEP 实验使用 12 个视觉刺激，对应 12 个不同的目标选项。

### 2.3 刺激频率设计

典型的 12 类 SSVEP 实验频率范围:

| 频段 | 频率范围 | 示例 (Hz) |
|------|----------|-----------|
| 低频段 | 8-12 Hz | 8.0, 9.0, 10.0, 11.0, 12.0 |
| 中频段 | 12-20 Hz | 13.0, 14.0, 15.0, 16.0, 17.0 |
| 高频段 | 20-30 Hz | 18.0, 20.0, 22.0, 25.0, 28.0 |

### 2.4 实验设置

- **采样率**: 256 Hz 或更高
- **时间窗口**: 通常 1-5 秒
- **通道数**: 8 个 (枕叶区域主要记录点)
- **样本点**: 256 个时间点
- **频率分辨率**: 1 Hz 步进

### 2.5 数据形状

```
输入: (batch_size, 8, 256, 1)
     └─ [样本数, 通道数, 时间点, 1]

输出: (batch_size, 12)
     └─ [样本数, 12个类别概率]
```

### 2.6 SSVEP 信号特点

1. **周期性响应**: 信号包含与刺激频率及其谐波相关的能量
2. **信噪比**: SSVEP 信号的信噪比相对较高
3. **频率编码**: 不同目标通过不同频率区分
4. **训练需求**: 需针对个体校准以获得最佳性能

---

## 3. 模型配置对比

| 参数 | 4类 ERP 模型 | 12类 SSVEP 模型 |
|------|-------------|-----------------|
| 默认类别数 | 4 | 12 |
| 输入通道 | 64 | 8 |
| 时间样本 | 128 | 256 |
| 采样率 | 128 Hz | 256 Hz |
| 第一层卷积核 | 64 | 256 |
| F1 (时间滤波器) | 8 | 96 |
| D (空间滤波器数) | 2 | 1 |
| F2 (逐点滤波器) | 16 | 96 |

---

## 4. 实验流程

### 4.1 数据预处理

1. **滤波**: 带通滤波 (0.5-40 Hz 或自定义范围)
2. **重采样**: 统一采样率
3. **分段**: 提取事件相关时间段
4. **基线校正**: 去除刺激前 baseline
5. **坏导处理**: 去除坏通道/插值
6. **标准化**: Z-score 标准化

### 4.2 模型训练

```python
# 训练示例
from EEGModels_PyTorch import EEGNet, EEGNet_SSVEP

# ERP 分类
model_erp = EEGNet(nb_classes=4, Chans=64, Samples=128)

# SSVEP 识别
model_ssvep = EEGNet_SSVEP(nb_classes=12, Chans=8, Samples=256)

# 标准 PyTorch 训练流程
criterion = nn.CrossEntropyLoss()
optimizer = torch.optim.Adam(model.parameters())
```

### 4.3 评估

- **留一法交叉验证** (Leave-One-Subject-Out)
- **k折交叉验证** (k-Fold Cross Validation)
- **独立测试集评估**

---

## 5. 参考文献

1. Lawhern et al. (2018). EEGNet: a compact convolutional neural network for EEG-based brain-computer interfaces. *Journal of Neural Engineering*, 15(5), 056013.

2. Waytowich et al. (2018). Compact convolutional neural networks for classification of asynchronous steady-state visual evoked potentials. *Journal of Neural Engineering*, 15(6), 066031.

3. Schirrmeister et al. (2017). Deep learning with convolutional neural networks for EEG decoding and visualization. *Human Brain Mapping*, 38(11), 5391-5420.
