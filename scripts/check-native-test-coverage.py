"""Require each native test file to finish in exactly one successful shard."""
from collections import Counter
from pathlib import Path
import re
import sys


def require_complete(results: Path, test_dir: Path) -> int:
    expected = {p.name for p in test_dir.glob("test_*.gd") if p.name != "test_case.gd"}
    if not expected:
        raise ValueError("no native test files discovered")
    seen: Counter[str] = Counter()
    for shard in range(1, 4):
        log = (results / f"godot-test-logs-{shard}" / f"native-tests-{shard}-3.log").read_text(encoding="utf-8")
        started = Counter(re.findall(r"^START file (test_[^\s]+\.gd)$", log, re.MULTILINE))
        finished = Counter(re.findall(r"^END   file (test_[^\s]+\.gd) \| \d+ ms$", log, re.MULTILINE))
        if not started or started != finished:
            raise ValueError(f"shard {shard}: incomplete native test file list")
        summaries = re.findall(r"^(\d+) passed, (\d+) failed$", log, re.MULTILINE)
        if len(summaries) != 1 or int(summaries[0][0]) < len(started) or summaries[0][1] != "0":
            raise ValueError(f"shard {shard}: missing or unsuccessful native test summary")
        seen.update(finished)
    missing = sorted(expected - seen.keys())
    extra = sorted(seen.keys() - expected)
    duplicate = sorted(name for name, count in seen.items() if count != 1)
    if missing or extra or duplicate:
        raise ValueError(f"test coverage mismatch: missing={missing}, extra={extra}, duplicate={duplicate}")
    return len(expected)


if __name__ == "__main__":
    count = require_complete(Path(sys.argv[1]), Path("game/tests"))
    print(f"Native test coverage: {count} files finished exactly once across all 3 successful shards.")
