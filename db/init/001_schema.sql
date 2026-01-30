-- db/init/001_schema.sql
-- Production principles:
-- 1) Postgres stores metadata + pointers (fast queries, lineage).
-- 2) MinIO stores raw blobs, artifacts, reports.
-- 3) Pre-ingestion security gate yields ACCEPTED/QUARANTINED/REJECTED.
-- 4) Every ingestion attempt writes an audit event.

CREATE TABLE IF NOT EXISTS raw_documents (
  id BIGSERIAL PRIMARY KEY,
  source TEXT NOT NULL,
  url TEXT,
  fetched_at TIMESTAMPTZ NOT NULL DEFAULT now(),

  -- Pre-ingestion security decision
  security_status TEXT NOT NULL CHECK (security_status IN ('ACCEPTED','QUARANTINED','REJECTED')),
  rejection_reason TEXT,

  -- Lightweight metadata
  content_type TEXT,
  content_length BIGINT,

  -- Dedup/idempotency
  content_hash TEXT NOT NULL,

  -- Object storage pointer (null if REJECTED)
  object_bucket TEXT,
  object_path TEXT,

  -- Safe small metadata only (never the full body)
  payload_meta JSONB,

  UNIQUE (source, content_hash)
);

CREATE INDEX IF NOT EXISTS idx_raw_documents_fetched_at ON raw_documents(fetched_at);
CREATE INDEX IF NOT EXISTS idx_raw_documents_security_status ON raw_documents(security_status);

CREATE TABLE IF NOT EXISTS ingestion_events (
  id BIGSERIAL PRIMARY KEY,
  source TEXT NOT NULL,
  url TEXT,
  content_hash TEXT,
  event_type TEXT NOT NULL CHECK (event_type IN ('ACCEPTED','QUARANTINED','REJECTED')),
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ingestion_events_created_at ON ingestion_events(created_at);

-- Output of transformation stage
CREATE TABLE IF NOT EXISTS processed_documents (
  id BIGSERIAL PRIMARY KEY,
  raw_id BIGINT REFERENCES raw_documents(id),
  url TEXT,
  domain TEXT,
  title TEXT,
  body_text TEXT,
  language TEXT,
  processed_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Predictions always include model name+version for reproducibility
CREATE TABLE IF NOT EXISTS predictions (
  id BIGSERIAL PRIMARY KEY,
  processed_id BIGINT REFERENCES processed_documents(id),
  model_name TEXT NOT NULL,
  model_version TEXT NOT NULL,
  score DOUBLE PRECISION NOT NULL,
  decision TEXT NOT NULL,
  predicted_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Drift metrics history
CREATE TABLE IF NOT EXISTS drift_metrics (
  id BIGSERIAL PRIMARY KEY,
  model_name TEXT NOT NULL,
  model_version TEXT NOT NULL,
  window_start TIMESTAMPTZ NOT NULL,
  window_end TIMESTAMPTZ NOT NULL,
  metric_name TEXT NOT NULL,
  metric_value DOUBLE PRECISION NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
