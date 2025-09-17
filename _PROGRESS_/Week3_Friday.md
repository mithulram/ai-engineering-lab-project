# Progress Report Week 3 - Friday

| **Task** | **Responsible** | **Resources** | **Status** |
| -------- | --------------- | ------------- | ---------- |
| Implement safety module to block military vehicle counting and log evidence | Security / ML | safety_module.py, test_safety.py | Done — regex + classifier, evidence logging in safety_evidence/ |
| Add CI training pipeline with A100 support and fast-test mode | CI / ML Ops | .gitlab-ci.yml, train_safety_model.py | Done — pipeline present, GPU job manual trigger with a100 tag |
| Add safety monitoring metrics and Grafana dashboard | DevOps | monitoring/grafana/dashboards/week3_safety_monitoring.json | Done — dashboards provisioned, block metrics added |
| Comprehensive safety & integration tests (unit & E2E) | QA | test_safety.py, test_safety_e2e.py | Mostly done — tests added; a small number of minor assertion mismatches remain (local fixes applied) |
| Merge fixes and prepare presentation-ready branch | Release / Maintainer | branch `presentation-ready-20250919-726d21` | Done locally — ready for push after your approval |
