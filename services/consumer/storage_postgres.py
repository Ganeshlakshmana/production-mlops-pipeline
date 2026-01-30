from __future__ import annotations

import hashlib
import json
import os
from datetime import datetime, timezone
from typing import Any, Dict, Optional

from sqlalchemy import create_engine, text


def db_url_from_env() -> str:
    user = os.environ.get("APP_DB_USER", "mlops")
    pw = os.environ.get("APP_DB_PASSWORD", "mlops")
    name = os.environ.get("APP_DB_NAME", "mlops")
    host = os.environ.get("APP_DB_HOST", "postgres")
    port = os.environ.get("APP_DB_PORT", "5432")
    return f"postgresql+psycopg2://{user}:{pw}@{host}:{port}/{name}"


def sha256_hex(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


class PostgresStore:
    def __init__(self, url: str):
        self.engine = create_engine(url, pool_pre_ping=True)

    def log_ingestion_event(
        self,
        source: str,
        url: Optional[str],
        content_hash: Optional[str],
        event_type: str,
        reason: Optional[str],
    ) -> None:
        q = text("""
            INSERT INTO ingestion_events (source, url, content_hash, event_type, reason)
            VALUES (:source, :url, :content_hash, :event_type, :reason)
        """)
        with self.engine.begin() as conn:
            conn.execute(q, {
                "source": source,
                "url": url,
                "content_hash": content_hash,
                "event_type": event_type,
                "reason": reason,
            })

    def insert_raw_metadata(
    self,
    source: str,
    url: Optional[str],
    security_status: str,
    rejection_reason: Optional[str],
    content_hash: str,
    payload_meta: Dict[str, Any],
    content_type: Optional[str] = None,
    content_length: Optional[int] = None,
    object_bucket: Optional[str] = None,
    object_path: Optional[str] = None,
) -> None:
        q = text("""
        INSERT INTO raw_documents
          (source, url, fetched_at, security_status, rejection_reason,
           content_type, content_length, content_hash, object_bucket, object_path, payload_meta)
        VALUES
          (:source, :url, :fetched_at, :security_status, :rejection_reason,
           :content_type, :content_length, :content_hash, :object_bucket, :object_path, CAST(:payload_meta AS jsonb))
        ON CONFLICT (source, content_hash) DO NOTHING
    """)
        fetched_at = datetime.now(timezone.utc)
        with self.engine.begin() as conn:
            conn.execute(q, {
                "source": source,
                "url": url,
                "fetched_at": fetched_at,
            "security_status": security_status,
            "rejection_reason": rejection_reason,
            "content_type": content_type,
            "content_length": content_length,
            "content_hash": content_hash,
            "object_bucket": object_bucket,
            "object_path": object_path,
            "payload_meta": json.dumps(payload_meta),
        })

