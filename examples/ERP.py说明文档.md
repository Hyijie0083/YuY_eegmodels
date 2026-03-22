# ERP.py 文件说明文档

## 概述

`ERP.py` 是一个使用 **EEGNet** 深度学习模型对事件相关电位(ERP)脑电数据进行四分类任务的示例脚本。该脚本使用 MNE 工具包提供的样本数据集，展示了从数据预处理到模型训练和评估的完整流程。

---

## 数据集说明

### 数据来源
- **数据集**: MNE Sample Dataset
- **下载地址**: https://martinos.org/mne/stable/manual/sample_dataset.html
- **数据集大小**: 约 1.5GB
- **首次运行**: MNE 会自动下载数据集并提示确认下载位置（默认 `~/mne_data`）

### 四分类任务类别
| 类别代码 | 全称 | 中文说明 |
|---------|------|---------|
| LA | Left-ear auditory stimulation | 左耳听觉刺激 |
| RA | Right-ear auditory stimulation | 右耳听觉刺激 |
| LV | Left visual field stimulation | 左视野视觉刺激 |
| RV | Right visual field stimulation | 右视野视觉刺激 |

---

## 代码结构解析

### 1. 导入依赖库

```python
import numpy as np
import mne
from mne import io
from mne.datasets import sample
from EEGModels import EEGNet
from tensorflow.keras import utils as np_utils
from tensorflow.keras.callbacks import ModelCheckpoint
from tensorflow.keras import backend as K
from pyriemann.estimation import XdawnCovariances
from pyriemann.tangentspace import TangentSpace
from pyriemann.utils.viz import plot_confusion_matrix
from sklearn.pipeline import make_pipeline
from sklearn.linear_model import LogisticRegression
from matplotlib import pyplot as plt
```

**主要依赖库说明：**
- **MNE**: 脑电数据处理和分析的专业工具包
- **EEGModels**: 包含 EEGNet 等深度学习模型的库
- **TensorFlow/Keras**: 深度学习框架
- **PyRiemann**: 基于黎曼几何的脑电信号处理库
- **scikit-learn**: 机器学习工具包

---

### 2. 数据预处理流程

#### 2.1 数据加载
```python
data_path = sample.data_path()
raw_fname = data_path + '/MEG/sample/sample_audvis_filt-0-40_raw.fif'
event_fname = data_path + '/MEG/sample/sample_audvis_filt-0-40_raw-eve.fif'
```

#### 2.2 参数设置
```python
tmin, tmax = -0., 1  # 时间窗口：刺激前0秒到刺激后1秒
event_id = dict(aud_l=1, aud_r=2, vis_l=3, vis_r=4)  # 事件ID映射
```

#### 2.3 数据过滤与读取
```python
raw = io.Raw(raw_fname, preload=True, verbose=False)
raw.filter(2, None, method='iir')  # 高通滤波（2Hz），替代基线校正
events = mne.read_events(event_fname)
raw.info['bads'] = ['MEG 2443']  # 标记坏通道
```

#### 2.4 通道选择与分段
```python
picks = mne.pick_types(raw.info, meg=False, eeg=True, stim=False, eog=False, exclude='bads')
epochs = mne.Epochs(raw, events, event_id, tmin, tmax, proj=False,
                    picks=picks, baseline=None, preload=True, verbose=False)
```

#### 2.5 数据提取与缩放
```python
X = epochs.get_data() * 1000  # 数据格式: (trials, channels, samples)，乘以1000进行缩放
y = labels  # 标签
```

**数据维度：**
- 通道数 (chans): 60
- 采样点数 (samples): 151
- 核数 (kernels): 1

---

### 3. 数据划分

```python
# 50% 训练 / 25% 验证 / 25% 测试
X_train      = X[0:144,]
Y_train      = y[0:144]
X_validate   = X[144:216,]
Y_validate   = y[144:216]
X_test       = X[216:,]
Y_test       = y[216:]
```

---

### 4. EEGNet 模型训练

#### 4.1 数据格式转换
```python
# 标签转one-hot编码
Y_train      = np_utils.to_categorical(Y_train-1)
Y_validate   = np_utils.to_categorical(Y_validate-1)
Y_test       = np_utils.to_categorical(Y_test-1)

# 数据 reshape 为 NHWC 格式: (trials, channels, samples, kernels)
X_train      = X_train.reshape(X_train.shape[0], chans, samples, kernels)
X_validate   = X_validate.reshape(X_validate.shape[0], chans, samples, kernels)
X_test       = X_test.reshape(X_test.shape[0], chans, samples, kernels)
```

#### 4.2 EEGNet-8,2,16 模型配置
```python
model = EEGNet(nb_classes = 4,      # 分类类别数
               Chans = chans,        # 通道数: 60
               Samples = samples,    # 采样点数: 151
               dropoutRate = 0.5,    # Dropout比率
               kernLength = 32,      # 卷积核长度
               F1 = 8,               # 时间卷积滤波器数量
               D = 2,                # 深度乘数（空间滤波器数量 = F1 * D）
               F2 = 16,              # 可分离卷积点滤波器数量
               dropoutType = 'Dropout')
```

**模型参数说明：**
- `F1=8`: 时间卷积层的滤波器数量
- `D=2`: 深度乘数，空间滤波器数量 = F1 × D = 16
- `F2=16`: 可分离卷积中的点卷积滤波器数量
- `kernLength=32`: 时间卷积核长度（样本点数）

#### 4.3 模型编译
```python
model.compile(loss='categorical_crossentropy', 
              optimizer='adam', 
              metrics = ['accuracy'])
```

#### 4.4 训练配置
```python
# 模型检查点回调
checkpointer = ModelCheckpoint(filepath='/tmp/checkpoint.h5', 
                               verbose=1,
                               save_best_only=True)

# 类别权重（用于处理类别不平衡，此处各类别权重相同）
class_weights = {0:1, 1:1, 2:1, 3:1}
```

#### 4.5 模型训练
```python
fittedModel = model.fit(X_train, Y_train, 
                        batch_size = 16,      # 批次大小
                        epochs = 300,         # 训练轮数
                        verbose = 2,          # 输出详细程度
                        validation_data=(X_validate, Y_validate),
                        callbacks=[checkpointer], 
                        class_weight = class_weights)
```

#### 4.6 加载最优权重并测试
```python
model.load_weights('/tmp/checkpoint.h5')
probs       = model.predict(X_test)
preds       = probs.argmax(axis = -1)
acc         = np.mean(preds == Y_test.argmax(axis=-1))
print("Classification accuracy: %f " % (acc))
```

---

### 5. PyRiemann 对比方法

脚本还提供了基于黎曼几何的分类方法作为对比基准：

```python
# 设置 sklearn pipeline
clf = make_pipeline(XdawnCovariances(n_components),  # xDAWN空间滤波 + 协方差估计
                    TangentSpace(metric='riemann'),   # 黎曼切空间映射
                    LogisticRegression())             # 逻辑回归分类器

# 数据 reshape 回 (trials, channels, samples)
X_train      = X_train.reshape(X_train.shape[0], chans, samples)
X_test       = X_test.reshape(X_test.shape[0], chans, samples)

# 训练分类器
clf.fit(X_train, Y_train.argmax(axis = -1))
preds_rg     = clf.predict(X_test)

# 计算准确率
acc2         = np.mean(preds_rg == Y_test.argmax(axis = -1))
```

---

### 6. 结果可视化

```python
names        = ['audio left', 'audio right', 'vis left', 'vis right']

# EEGNet 混淆矩阵
plt.figure(0)
plot_confusion_matrix(preds, Y_test.argmax(axis = -1), names, title = 'EEGNet-8,2')

# xDAWN + RG 混淆矩阵
plt.figure(1)
plot_confusion_matrix(preds_rg, Y_test.argmax(axis = -1), names, title = 'xDAWN + RG')
```

---

## EEGNet 模型架构简介

EEGNet 是一个专为脑电信号设计的轻量级卷积神经网络，其核心特点包括：

### 架构特点
1. **深度可分离卷积**: 结合时间卷积和深度卷积，有效提取时空特征
2. **参数高效**: 模型参数量少，适合小样本脑电数据
3. **可解释性**: 可以可视化学习到的空间滤波器（地形图）

### 网络结构
```
输入 (trials, channels, samples, 1)
    ↓
时间卷积 (F1=8, kernLength=32)
    ↓
Batch Normalization
    ↓
深度卷积 (D=2, 空间滤波)
    ↓
Batch Normalization + ELU激活 + Dropout
    ↓
可分离卷积 (F2=16)
    ↓
Batch Normalization + ELU激活 + Dropout
    ↓
平均池化
    ↓
全连接层 → Softmax → 输出 (4类)
```

---

## 运行说明

### 环境要求
```bash
# 核心依赖
pip install mne
pip install tensorflow
pip install pyriemann
pip install scikit-learn
pip install matplotlib
```

### 运行步骤
1. 确保已安装所有依赖库
2. 首次运行会自动下载 MNE 样本数据集（约1.5GB）
3. 按照提示确认数据集下载位置
4. 运行脚本开始训练和评估

### 预期输出
- 训练过程中的 loss 和 accuracy 变化
- 测试集分类准确率（EEGNet 通常可达 90%+）
- 两个混淆矩阵可视化图表

---

## 参考文献

该脚本基于以下研究工作：

1. **MNE 软件**:
   - Gramfort et al. (2014). MNE software for processing MEG and EEG data. *NeuroImage*, 86, 446-460.
   - Gramfort et al. (2013). MEG and EEG data analysis with MNE-Python. *Frontiers in Neuroscience*, 7.

2. **PyRiemann**:
   - https://github.com/alexandrebarachant/pyRiemann

3. **黎曼几何分类方法**:
   - Barachant & Congedo (2014). A Plug&Play P300 BCI Using Information Geometry. *arXiv:1409.0107*.
   - Congedo et al. (2013). A New generation of Brain-Computer Interface Based on Riemannian Geometry. *arXiv:1310.8115*.

---

## 许可证说明

本项目部分内容属于美国政府作品，不受国内版权保护（17 USC Sec. 105），采用 CC0 1.0 许可证全球发布。

其他部分内容受国内版权保护（17 USC Sec. 105），采用 Apache 2.0 许可证。

完整许可证文本见项目中的 LICENSE.TXT 文件。
