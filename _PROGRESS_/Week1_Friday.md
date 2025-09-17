# Progress Report Week 1 - Friday

| **Task** | **Responsible** | **Resources** | **Status** |
| -------- | --------------- | ------------- | ---------- |
| Transfer notebook 3-step pipeline to Python backend and implement `/api/count` and `/api/correct` endpoints | Backend team / Mithul | app.py, model_pipeline.py, tests/test_app.py | Done — endpoints implemented, SQLite DB persisted |
| Replace mock APIs with real AI models (SAM, ResNet-50, DistilBERT) | ML team | model_pipeline.py, .huggingface_cache | Done — models load on CPU, fallback removed |
| Save results to DB with schema (timestamp, path, item_type, count, correction) | Backend team | models.py / ORM | Done — SQLite schema created and used |
| Add basic monitoring endpoints (/metrics, /api/status) | DevOps | monitoring.py, prometheus client | Done — metrics endpoint present |
| Unit tests and reproducibility docs | QA / Docs | test_app.py, README.MD, RUN_INSTRUCTIONS.md | Done — tests added (initial suite), docs present |
