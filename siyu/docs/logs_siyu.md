# SiYu Project Change Logs

> 用于记录每个项目的改动历史，基于 Git 版本控制

---

## 项目列表

| 项目名称 | 路径 | 创建日期 | 最近更新 |
|---------|------|---------|---------|
| YuY_eegmodels | /Users/siyu/Documents/GitHub/YuY_eegmodels | - | - |

---

## YuY_eegmodels 改动记录

### 2026-03-22

#### 初始化项目
- **分支**: master
- **远程**: origin (up to date)
- **状态**: 干净工作区

#### 已有文件
- `EEGModels.py` - EEG CNN 模型库
- `examples/ERP.py` - ERP 分类演示脚本
- `examples/EEGNet-8-2-weights.h5` - 预训练权重
- `README.md` / `LICENSE.txt`

---

## 其他项目改动记录

（后续添加其他项目）

---

## 使用说明

### 记录规范
1. 每次重要改动后更新此文件
2. 包含日期、项目名、改动类型、具体内容
3. 使用 Git 命令辅助追踪变更

### 推荐 Git 工作流
```bash
# 查看变更
git status
git diff

# 提交变更
git add .
git commit -m "描述"

# 推送前查看日志
git log --oneline
```

### 改动类型标签
- `[ADD]` - 新增功能/文件
- `[MOD]` - 修改现有功能
- `[FIX]` - 修复问题
- `[DEL]` - 删除功能/文件
- `[REF]` - 重构代码
- `[DOC]` - 文档更新

---

*由 Trae AI + git-version-control skill 生成*
