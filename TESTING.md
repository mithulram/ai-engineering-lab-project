# Testing Guide

## Overview
This document describes how to run tests for the AI Object Counting application, including GPU-dependent tests and memory-safe testing modes.

## Memory-Safe Testing

### Local Development (M1 MacBook Air 8GB)
For local development on memory-constrained systems:

```bash
export LOCAL_LOW_MEMORY=1
export FLASK_DEBUG=0
python -m pytest test_*.py -q --maxfail=1
```

### CI Testing
The CI pipeline automatically sets memory-safe environment variables:
- `LOCAL_LOW_MEMORY=1` - Enables lazy loading and lightweight models
- `FLASK_DEBUG=0` - Disables Flask debug mode

## GPU-Dependent Tests

Some tests require GPU access and will be skipped on CPU-only systems:

### Running GPU Tests
To run GPU-dependent tests, you need:
1. NVIDIA GPU with CUDA support
2. PyTorch with CUDA enabled
3. Set environment variable: `CI_GPU_AVAILABLE=1`

```bash
export CI_GPU_AVAILABLE=1
python -m pytest test_*.py -v
```

### Skipped Tests
The following tests are marked as GPU-dependent and will be skipped on CPU-only systems:
- `test_count_objects_success` - Requires full AI model loading
- `test_safety_e2e` - Requires GPU for safety model inference

## Test Categories

### Unit Tests
- **test_app.py** - API endpoint tests
- **test_safety.py** - Safety module tests
- **test_week2_metrics.py** - Monitoring and metrics tests

### Integration Tests
- **test_safety_e2e.py** - End-to-end safety testing (GPU required)

### Performance Tests
- **test_metrics_scale.py** - Metrics collection performance

## Test Results

### Expected Results (CPU-only)
```
Total Tests: 24
Passed: 22
Skipped: 2 (GPU-dependent)
Failed: 0
```

### Expected Results (GPU-enabled)
```
Total Tests: 24
Passed: 24
Skipped: 0
Failed: 0
```

## Troubleshooting

### Bus Error / Memory Issues
If tests crash with bus errors:
1. Ensure `LOCAL_LOW_MEMORY=1` is set
2. Use `--maxfail=1` to stop after first failure
3. Run tests individually: `pytest test_app.py::TestObjectCountingAPI::test_health -v`

### Import Errors
If you get import errors:
1. Activate virtual environment: `source .venv/bin/activate`
2. Install dependencies: `pip install -r requirements.txt`
3. Check Python version: `python --version` (should be 3.9+)

### GPU Tests Not Running
If GPU tests are not running:
1. Check CUDA availability: `python -c "import torch; print(torch.cuda.is_available())"`
2. Set `CI_GPU_AVAILABLE=1` environment variable
3. Verify PyTorch CUDA installation: `python -c "import torch; print(torch.version.cuda)"`

## CI Pipeline

The GitLab CI pipeline runs tests in two modes:

### Test Job (CPU)
- Runs on `python:3.9-slim` image
- Uses `LOCAL_LOW_MEMORY=1`
- Skips GPU-dependent tests
- Runs on all branches

### Training Jobs (GPU)
- `train_safety_model_fast` - CPU-only smoke test
- `train_safety_model` - Full GPU training (manual trigger, A100 required)

## Best Practices

1. **Always test locally** before pushing
2. **Use memory-safe mode** for local development
3. **Mark GPU tests** with appropriate skip decorators
4. **Document test requirements** in this file
5. **Keep tests fast** - avoid heavy model loading in unit tests
