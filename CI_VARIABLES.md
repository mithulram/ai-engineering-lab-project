# GitLab CI Variables Reference

This document lists all CI variables used in the AI Object Counting application pipeline.

## Built-in GitLab CI Variables

These variables are automatically provided by GitLab CI and do not need to be configured:

| Variable | Purpose | Example Value |
|----------|---------|---------------|
| `CI_PROJECT_DIR` | Project directory path | `/builds/user/ai-engineering-lab-project` |
| `CI_COMMIT_SHORT_SHA` | Git commit hash (short) | `a1b2c3d` |
| `CI_COMMIT_SHA` | Full Git commit hash | `a1b2c3d4e5f6...` |
| `CI_PIPELINE_ID` | Pipeline ID | `12345` |
| `CI_JOB_ID` | Job ID | `67890` |

## Pipeline Variables

These variables are defined in `.gitlab-ci.yml`:

| Variable | Purpose | Default Value |
|----------|---------|---------------|
| `MODEL_ARTIFACTS_DIR` | Directory for model artifacts | `model_artifacts` |
| `SAFETY_MODEL_DIR` | Directory for safety models | `safety_models` |
| `TRAINING_EPOCHS` | Number of training epochs | `10` |
| `BATCH_SIZE` | Training batch size | `32` |
| `LEARNING_RATE` | Training learning rate | `0.001` |
| `PIP_CACHE_DIR` | Pip cache directory | `$CI_PROJECT_DIR/.cache/pip` |
| `PYTHON_VERSION` | Python version | `3.9` |

## Environment Variables

These variables control application behavior:

| Variable | Purpose | Values | Default |
|----------|---------|--------|---------|
| `LOCAL_LOW_MEMORY` | Enable low memory mode | `0`, `1` | `1` |
| `FLASK_DEBUG` | Enable Flask debug mode | `0`, `1` | `0` |
| `API_PORT` | Backend API port | `5001` | `5001` |
| `HF_HOME` | Hugging Face cache directory | Path | `.huggingface_cache` |
| `TRANSFORMERS_CACHE` | Transformers cache directory | Path | `.huggingface_cache` |

## Runner Tags

The pipeline uses the following runner tags:

| Tag | Purpose | Required For |
|-----|---------|--------------|
| `a100` | NVIDIA A100 GPU access | `train_safety_model` job |
| (none) | Default CPU runners | All other jobs |

## Artifact Storage

The pipeline generates the following artifacts:

| Job | Artifacts | Retention |
|-----|-----------|-----------|
| `test` | `test-results.xml`, `test-results/` | 1 week |
| `train_safety_model` | `model_artifacts/`, `safety_models/`, `training_data/` | 30 days |
| `train_safety_model_fast` | `model_artifacts/`, `safety_models/`, `training_data/` | 7 days |
| `deploy_models` | `model_artifacts/`, `safety_models/` | 90 days |

## Required Infrastructure

To run the pipeline successfully, the following infrastructure must be available:

### GitLab Runner Configuration
- **A100 Runner**: Must have tag `a100` and access to NVIDIA A100 GPU
- **CUDA Runtime**: CUDA 11.8 or compatible
- **Docker Runtime**: nvidia-docker2 or containerd with nvidia support
- **Disk Space**: 10GB+ for model artifacts and dependencies
- **Memory**: 32GB+ RAM for A100 training

### Network Access
- **PyTorch CUDA Repository**: Access to download CUDA-enabled PyTorch packages
- **Hugging Face Hub**: Access to download transformer models
- **GitLab Artifacts**: Access to store and retrieve model artifacts

## Security Considerations

### No External Secrets Required
The pipeline does not require any external API keys or secrets:
- No cloud provider credentials
- No Docker registry authentication
- No external service API keys

### Safety Module
- Blocks military vehicle counting requests
- Uses rule-based and ML-based detection
- Logs all violations for audit

## Troubleshooting

### Common Issues

#### CUDA Not Available
```
CUDA available: False
```
**Solution**: Verify nvidia-docker runtime and GPU access on A100 runner

#### Out of Memory
```
RuntimeError: CUDA out of memory
```
**Solution**: Reduce batch size or use smaller model variants

#### Test Failures
```
Bus error during model loading
```
**Solution**: Tests use `LOCAL_LOW_MEMORY=1` for memory safety

### Debug Commands
```bash
# Check GPU status
nvidia-smi

# Test PyTorch CUDA
python3 -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}')"

# Check runner tags
gitlab-runner list --tag a100
```

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
