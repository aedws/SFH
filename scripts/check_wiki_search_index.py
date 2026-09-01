#!/usr/bin/env python3
"""Fail the wiki build when search can route its first hit back to the dashboard home."""

from __future__ import annotations

import json
import sys
from pathlib import Path


def main() -> int:
    index_path = Path(sys.argv[1] if len(sys.argv) > 1 else ".wiki-site/search/search_index.json")
    if not index_path.is_file():
        raise SystemExit(f"Wiki search index is missing: {index_path}")

    payload = json.loads(index_path.read_text(encoding="utf-8"))
    documents = payload.get("docs", [])
    root_locations = {"", "./", "index.html", "/"}
    indexed_roots = [doc for doc in documents if doc.get("location") in root_locations]
    if indexed_roots:
        raise SystemExit("Dashboard home leaked into search_index.json and can cause a search-result home loop.")

    detail_locations = [
        str(doc.get("location", ""))
        for doc in documents
        if str(doc.get("location", "")).startswith("development-status/")
    ]
    if not detail_locations:
        raise SystemExit("Development status detail page is missing from search_index.json.")

    print(
        "WIKI_SEARCH_INDEX_OK "
        f"documents={len(documents)} dashboard_roots=0 detail_hits={len(detail_locations)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
