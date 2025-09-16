# GitLab CI A100 Training Pipeline - Readiness Guide

## Overview
This guide provides the complete setup requirements for running the A100 GPU training pipeline in GitLab CI.

## Prerequisites

### 1. GitLab Runner Configuration
- **Runner Tag**: `a100`
- **GPU Access**: NVIDIA A100 GPU
- **CUDA Version**: 11.8 or compatible
- **Docker Runtime**: nvidia-docker2 or containerd with nvidia support

### 2. Required CI Variables
The pipeline uses built-in GitLab CI variables only:
- `CI_PROJECT_DIR` - Project directory path (built-in)
- `CI_COMMIT_SHORT_SHA` - Git commit hash for artifact naming (built-in)

### 3. Infrastructure Requirements
- **Disk Space**: 10GB+ for model artifacts and dependencies
- **Memory**: 32GB+ RAM recommended for A100 training
- **Network**: Access to PyTorch CUDA package repository
- **Storage**: Artifact storage for model outputs (30-day retention)

## Pipeline Jobs

### Test Job (`test`)
- **Image**: `python:3.9-slim`
- **GPU Required**: No
- **Memory Safe**: Yes (uses `LOCAL_LOW_MEMORY=1`)
- **Triggers**: All branches, merge requests

### Training Job (`train_safety_model`)
- **Image**: `nvidia/cuda:11.8-devel-ubuntu20.04`
- **GPU Required**: Yes (A100)
- **Runner Tag**: `a100`
- **Trigger**: Manual only
- **Branches**: `training-safety`, `training/*`

### Fast Training Job (`train_safety_model_fast`)
- **Image**: `python:3.9-slim`
- **GPU Required**: No
- **Trigger**: Manual only
- **Purpose**: Smoke testing without GPU

### Deploy Job (`deploy_models`)
- **Image**: `python:3.9-slim`
- **GPU Required**: No
- **Trigger**: Manual only
- **Dependencies**: `train_safety_model`

## Setup Instructions

### 1. Configure GitLab Runner
```bash
# Register runner with A100 tag
gitlab-runner register \
  --tag-list "a100" \
  --executor "docker" \
  --docker-image "nvidia/cuda:11.8-devel-ubuntu20.04" \
  --docker-runtime "nvidia"
```

### 2. Verify GPU Access
```bash
# Test GPU availability
nvidia-smi
python3 -c "import torch; print(torch.cuda.is_available())"
```

### 3. Test Pipeline
1. Push to `training-safety` branch
2. Manually trigger `train_safety_model_fast` job first
3. If successful, trigger `train_safety_model` job
4. Monitor logs for CUDA initialization

## Troubleshooting

### Common Issues

#### 1. CUDA Not Available
```
CUDA available: False
```
**Solution**: Verify nvidia-docker runtime and GPU access

#### 2. Out of Memory
```
RuntimeError: CUDA out of memory
```
**Solution**: Reduce batch size or use smaller model variants

#### 3. Test Failures
```
Bus error during model loading
```
**Solution**: Tests now use `LOCAL_LOW_MEMORY=1` for memory safety

### Debug Commands
```bash
# Check GPU status
nvidia-smi

# Test PyTorch CUDA
python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"

# Check runner tags
gitlab-runner list --tag a100
```

## Memory Optimization

### Low Memory Mode
- Set `LOCAL_LOW_MEMORY=1` environment variable
- Uses lightweight model variants
- Implements lazy loading
- Reduces memory footprint by ~70%

### Model Loading Strategy
1. **Lazy Loading**: Models loaded on first use
2. **Fallback Models**: Lightweight alternatives for low memory
3. **Memory Cleanup**: Automatic cleanup after training

## Security Considerations

### Safety Module
- Blocks military vehicle counting requests
- Uses rule-based and ML-based detection
- Logs all violations for audit

### Model Artifacts
- Stored securely in GitLab artifacts
- 30-day retention policy
- No sensitive data in model files

## Monitoring

### Metrics Collection
- Training time and accuracy
- GPU utilization
- Memory usage
- Model performance metrics

### Logging
- Comprehensive training logs
- Error tracking and reporting
- Performance benchmarks

## Support

For issues with the A100 training pipeline:
1. Check GitLab CI logs
2. Verify runner configuration
3. Test with `train_safety_model_fast` first
4. Contact system administrator for GPU access issues
