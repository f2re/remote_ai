#!/usr/bin/env python3
"""Проверка ответа notarytool --wait --output-format json до staple/release."""
import json
import sys
import uuid
from pathlib import Path


def verify(data: object) -> tuple[str, str]:
    if not isinstance(data, dict):
        raise ValueError("Apple notarytool не вернул JSON-объект")
    status = data.get("status")
    submission_id = data.get("id")
    if status != "Accepted":
        raise ValueError(f"Apple notarization не принята (status={status!r})")
    if not isinstance(submission_id, str):
        raise ValueError("Ответ Apple не содержит submission ID")
    try:
        parsed_id = uuid.UUID(submission_id)
    except (ValueError, AttributeError) as exc:
        raise ValueError("Некорректный Apple notarytool submission ID") from exc
    return status, str(parsed_id)


def main() -> int:
    if len(sys.argv) != 2:
        print("Использование: verify-notarization.py <notarytool-output.json>", file=sys.stderr)
        return 2
    try:
        payload = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
        status, submission_id = verify(payload)
    except (OSError, ValueError, json.JSONDecodeError) as exc:
        print(f"::error::Проверка notarization: {exc}", file=sys.stderr)
        return 1
    print(f"Apple notarization: {status} (submission {submission_id})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
