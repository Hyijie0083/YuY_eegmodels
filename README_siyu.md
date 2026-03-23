# Siyu 的 EEG Models 学习项目

> 作者: Siyu  
> 本项目包含 EEG 深度学习模型的学习笔记、实验配置和 PyTorch 实现。

---

## 项目结构

```
YuY_eegmodels/
├── EEGModels.py              # 原始 Keras/TensorFlow 版本
├── EEGModels_PyTorch.py      # PyTorch 实现版本 (Siyu 新增)
├── notes_siyu.md            # 学习笔记 (Siyu 新增)
├── experiments.md            # 实验配置文档 (Siyu 新增)
├── logs_siyu.md             # 学习日志 (Siyu 新增)
├── README_siyu.md           # 本文件
├── README.md                # 原项目 README
├── AGENTS.md                # 项目知识库
└── examples/
    ├── ERP.py                 # Keras 版 ERP 训练示例
    ├── ERP_PyTorch.py         # PyTorch 版 ERP 训练示例
    ├── EEGNet-8-2-weights.h5  # 预训练权重
    ├── example.ipynb           # Jupyter Notebook 示例
    └── LICENSE                 # 许可证
```

---

## Siyu 新增内容

### 1. EEGModels_PyTorch.py

**PyTorch 实现的 EEG 深度学习模型库**

将原始 Keras/TensorFlow 版本转换为 PyTorch，包含以下模型：

| 模型 | 用途 | 状态 |
|------|------|------|
| **EEGNet** | 通用 EEG 分类（ERP、SMR等） | 主力模型 |
| **EEGNet_SSVEP** | SSVEP 目标识别（12类） | 专用变体 |
| **EEGNet_old** | 早期版本 | 已弃用 |
| **DeepConvNet** | 深度卷积网络 | 辅助模型 |
| **ShallowConvNet** | 浅层卷积网络 | 辅助模型 |

**使用示例**：

```python
from EEGModels_PyTorch import EEGNet, DeepConvNet, ShallowConvNet

# 创建模型
model = EEGNet(nb_classes=4, Chans=64, Samples=128)

# 训练
optimizer = torch.optim.Adam(model.parameters())
criterion = nn.CrossEntropyLoss()

for epoch in range(epochs):
    outputs = model(inputs)
    loss = criterion(outputs, labels)
    loss.backward()
    optimizer.step()
```

---

### 2. notes_siyu.md

**完整的学习笔记，包含 8 个核心问题**

| 章节 | 内容 |
|------|------|
| Q1 | Terminal shape 含义详解 |
| Q2 | 4类 ERP vs 12类 SSVEP 任务对比 |
| Q3 | EEGModels_PyTorch.py 的用途 |
| Q4 | 输入输出、原理、作用 |
| Q5 | 时间模式和空间模式提取 |
| Q6 | EEGNet forward() 工作流程 |
| Q7 | dropoutRate=0.5 的作用 |
| Q8 | Block 2 SeparableConv2d 详解 |

**核心知识点**：

- **时间卷积**: `(1, kernLength)` 沿时间轴提取时间模式
- **深度卷积**: `(Chans, 1)` 沿通道轴提取空间模式
- **可分离卷积**: Depthwise + Pointwise，融合时空特征
- **Dropout**: 防止过拟合的正则化技术
- **BatchNorm**: 稳定激活分布

---

### 3. experiments.md

**实验配置文档，详细说明两类任务**

#### 3.1 四类 ERP 分类任务

| 类别 | 全称 | 刺激类型 |
|------|------|----------|
| LA | Left Auditory | 左耳听觉刺激 |
| RA | Right Auditory | 右耳听觉刺激 |
| LV | Left Visual | 左视野视觉刺激 |
| RV | Right Visual | 右视野视觉刺激 |

**实验设置**：
- 数据来源: MNE sample 数据集
- 采样率: 128 Hz
- 时间窗口: 0-1 秒
- 通道数: 64
- 样本点: 128

#### 3.2 12类 SSVEP 目标识别任务

**SSVEP (Steady-State Visual Evoked Potential)**

当受试者注视不同频率的闪烁刺激时，大脑视觉皮层会产生与刺激频率同步的响应。

**刺激频率设计**：
- 低频段: 8-12 Hz
- 中频段: 12-20 Hz
- 高频段: 20-30 Hz

**实验设置**：
- 采样率: 256 Hz
- 时间窗口: 1-5 秒
- 通道数: 8 (枕叶区域)
- 样本点: 256

---

### 4. logs_siyu.md

**学习过程日志，记录学习进度和发现**

---

## 快速开始

### 安装依赖

```bash
# PyTorch 版本
pip install torch>=1.0 numpy

# Keras 版本
pip install tensorflow==2.X mne>=0.17.1 pyriemann>=0.2.5
```

### 运行示例

```bash
# 测试模型
python EEGModels_PyTorch.py

# 运行 ERP 训练 (PyTorch)
python examples/ERP_PyTorch.py
```

---

## 核心概念

### EEG 数据格式

```
输入形状: (batch_size, Chans, Samples, 1)
         = (样本数, 通道数, 时间点, 1)

示例: (16, 64, 128, 1)
      └─ 16个样本 × 64通道 × 128时间点 × 1
```

### EEGNet 架构

```
输入 EEG 
  ↓ [Block 1: 时间和空间特征提取]
    ├─ 时间卷积 (1×64): 提取时间模式
    ├─ 深度卷积 (64×1): 提取空间模式
    └─ 池化 + Dropout
  ↓ [Block 2: 可分离卷积]
    ├─ Depthwise: 逐通道时间分析
    ├─ Pointwise: 1×1混合通道
    └─ 池化 + Dropout
  ↓ [分类器]
    ├─ Flatten
    ├─ Dense (全连接)
    └─ Softmax
  ↓ 类别概率
```

---

## 参考文献

1. Lawhern et al. (2018). EEGNet: a compact convolutional neural network for EEG-based brain-computer interfaces. *Journal of Neural Engineering*, 15(5), 056013.

2. Waytowich et al. (2018). Compact convolutional neural networks for classification of asynchronous steady-state visual evoked potentials. *Journal of Neural Engineering*, 15(6), 066031.

3. Schirrmeister et al. (2017). Deep learning with convolutional neural networks for EEG decoding and visualization. *Human Brain Mapping*, 38(11), 5391-5420.

---

## 许可证

本项目遵循原项目的许可协议：
- Creative Commons Zero 1.0 (CC0 1.0) Public Domain Dedication
- Apache 2.0 License

详见项目根目录的 `LICENSE.txt` 文件。

---

## 联系方式

如有问题或建议，欢迎通过 GitHub Issues 联系。

---

**最后更新**: 2026-03-23  
**作者**: Siyu
