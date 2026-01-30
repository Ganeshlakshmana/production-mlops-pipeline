# Streaming Topics & Event Contract

## Topics
- `raw_content_events`  
  Main topic. Producer publishes raw records pulled from APIs.

- `raw_content_events_dlq`  
  Dead-letter queue (DLQ). Consumer publishes events that are rejected/quarantined with reason.

## Event contract (JSON)

### Required fields
- `event_id` (string, UUID recommended): unique id for idempotency in streaming layer
- `source` (string): data source name (e.g., "api_news", "api_forum")
- `fetched_at` (string ISO-8601 UTC): when record was fetched/received
- `url` (string, optional but recommended): original URL (if applicable)
- `payload` (object): raw data returned by the API (lightweight metadata OK)
- `content` (string, optional): raw text content if API directly provides it

### Example
```json
{
  "event_id": "c1c4e0b5-1d25-4f2d-9a5b-6a38b4b6c7d1",
  "source": "api_demo",
  "fetched_at": "2026-01-30T17:30:00Z",
  "url": "https://example.com/article/123",
  "payload": {
    "title": "Example Title",
    "lang": "en"
  },
  "content": "raw text body..."
}
