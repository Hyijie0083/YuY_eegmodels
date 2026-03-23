# PROJECT KNOWLEDGE BASE

**Generated:** 2026-03-22T02:56:07Z
**Commit:** 4a512e5
**Branch:** master

## OVERVIEW
ARL EEGModels — Collection of Keras/TensorFlow CNN models for EEG signal processing and classification. Single-file library, not a proper Python package.

## STRUCTURE
```
YuY_eegmodels/
├── EEGModels.py          # All models (EEGNet, DeepConvNet, ShallowConvNet)
├── examples/
│   ├── ERP.py            # Demo script for ERP classification
│   ├── EEGNet-8-2-weights.h5  # Pre-trained weights
│   └── LICENSE
├── README.md
└── LICENSE.txt
```

## WHERE TO LOOK
| Task | Location | Notes |
|------|----------|-------|
| Import models | `from EEGModels import EEGNet, DeepConvNet, ShallowConvNet` | Add to PYTHONPATH first |
| Usage example | `examples/ERP.py` | Downloads 1.5GB MNE sample data |
| Model definitions | `EEGModels.py` lines 55-400 | All models in one file |

## CODE MAP
| Symbol | Type | Location | Role |
|--------|------|----------|------|
| EEGNet | function | EEGModels.py:55-155 | Main CNN model with depthwise/separable convs |
| EEGNet_SSVEP | function | EEGModels.py:160-220 | SSVEP variant |
| DeepConvNet | function | EEGModels.py:285-348 | Deep convolutional network |
| ShallowConvNet | function | EEGModels.py:359-400 | Shallow convolutional network |
| EEGNet_old | function | EEGModels.py:224-281 | Original/deprecated version |

## CONVENTIONS
- **NOT** a proper Python package — no `setup.py`, no `__init__.py`
- Add to PYTHONPATH to use: `export PYTHONPATH=/path/to/YuY_eegmodels:$PYTHONPATH`
- All models accept: `nb_classes`, `Chans`, `Samples` as required params
- Default EEGNet uses: `F1=8`, `D=2`, `F2=16`, `kernLength=64` (EEGNet-8,2)
- Dropout rate default: 0.5
- Sampling rate assumption: 128Hz (adjust kernel lengths for other rates)

## ANTI-PATTERNS (THIS PROJECT)
- No test suite — do NOT expect `pytest` or any tests
- No CI/CD — no GitHub Actions, no Dockerfile
- No linter/formatter configs — no `pyproject.toml`, `.flake8`, etc.
- Dependencies in README only — not pinned in `requirements.txt`

## UNIQUE STYLES
- Single-file distribution (402 lines) containing all 5 model implementations
- Research code from Army Research Lab — prioritized portability over standard packaging
- Manual PYTHONPATH installation (no `pip install` support)
- Pre-trained weights provided: `examples/EEGNet-8-2-weights.h5`

## COMMANDS
```bash
# Add to PYTHONPATH
export PYTHONPATH=/path/to/YuY_eegmodels:$PYTHONPATH

# Install dependencies
pip install tensorflow==2.X mne>=0.17.1 pyriemann>=0.2.5 scikit-learn>=0.20.1 matplotlib>=2.2.3

# Run demo (downloads ~1.5GB)
python examples/ERP.py
```

## NOTES
- `EEGNet_old` is deprecated — use `EEGNet` instead
- SpatialDropout2D works better for ERP, Dropout for oscillatory data
- TensorFlow 2.x only (tested 2.0-2.3)
- DeepExplain compatibility requires extra steps for TF2 (see issue #29)
- License: CC0 1.0 + Apache 2.0 for some portions
