# MLOps Batch Pipeline (OSS, Production-Style)

This repo is a production-style MLOps pipeline built with open source tooling.
It supports:
- secure ingestion (pre-ingestion security + quarantine)
- transformation + validation
- training + evaluation + MLflow registry
- batch inference
- drift monitoring

## Structure
- services/: long-running services (producer, consumer, serving)
- pipelines/: deterministic batch jobs (transform/train/infer/monitor)
- airflow/dags/: orchestration only
- libs/: shared utilities
- db/: schema/init
- infra/: optional monitoring configs
