#!/usr/bin/env python3
"""Convert Trivy JSON output into a .trivyignore YAML file."""

import argparse
import datetime as dt
import json
from pathlib import Path
from typing import Any, Dict, Iterable, List, Optional


def add_months(date_value: dt.date, months: int) -> dt.date:
    """
    Add months to a date, clamping the day to the last day of the target month.
    """
    if months == 0:
        return date_value

    month_index = date_value.month - 1 + months
    year = date_value.year + month_index // 12
    month = month_index % 12 + 1

    # Clamp day to the last day of the target month.
    next_year = year + (1 if month == 12 else 0)
    next_month = 1 if month == 12 else month + 1
    first_of_next = dt.date(next_year, next_month, 1)
    last_day = first_of_next - dt.timedelta(days=1)
    day = min(date_value.day, last_day.day)
    return dt.date(year, month, day)


def extract_vulnerabilities(data: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Collect vulnerability entries from Trivy JSON output."""
    results = data.get("Results", [])
    if not isinstance(results, list):
        return []

    vulnerabilities: List[Dict[str, Any]] = []
    for result in results:
        if not isinstance(result, dict):
            continue
        for vuln in result.get("Vulnerabilities", []) or []:
            if isinstance(vuln, dict):
                vulnerabilities.append(vuln)
    return vulnerabilities


def normalize_purl(vuln: Dict[str, Any]) -> Optional[str]:
    identifier = vuln.get("PkgIdentifier")
    if isinstance(identifier, dict):
        purl = identifier.get("PURL")
        if isinstance(purl, str) and purl.strip():
            return purl.strip()
    return None


def build_entries(
    vulnerabilities: Iterable[Dict[str, Any]],
    expires_on: dt.date
) -> List[Dict[str, Any]]:
    """Build YAML entries with de-duplication by CVE, merging PURLs."""
    entries: Dict[str, Dict[str, Any]] = {}

    for vuln in vulnerabilities:
        vuln_id = vuln.get("VulnerabilityID")
        title = vuln.get("Title")
        purl = normalize_purl(vuln)

        if not isinstance(vuln_id, str) or not vuln_id.strip():
            continue
        if not isinstance(title, str) or not title.strip():
            continue

        key = vuln_id.strip()
        entry = entries.get(key)
        if entry is None:
            entry = {
                "id": key,
                "statement": title.strip(),
                "purls": set(),
                "expired_at": expires_on.isoformat(),
            }
            entries[key] = entry

        if purl:
            entry["purls"].add(purl)

    merged_entries: List[Dict[str, Any]] = []
    for entry in entries.values():
        purls = sorted(entry["purls"])
        if purls:
            entry["purls"] = purls
        else:
            entry.pop("purls", None)
        merged_entries.append(entry)

    return merged_entries


def write_yaml(entries: List[Dict[str, Any]], output_path: Path) -> None:
    """Write entries to a YAML file without external dependencies."""
    lines: List[str] = ["vulnerabilities:"]
    for entry in entries:
        lines.append(f"  - id: {entry['id']}")
        lines.append(f"    statement: {json.dumps(entry['statement'])}")
        if "purls" in entry:
            lines.append("    purls:")
            for purl in entry["purls"]:
                lines.append(f"      - {json.dumps(purl)}")
        lines.append(f"    expired_at: {entry['expired_at']}")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert Trivy JSON output to .trivyignore YAML."
    )
    parser.add_argument(
        "--input",
        required=True,
        help="Path to the Trivy JSON output file.",
    )
    parser.add_argument(
        "--output",
        required=True,
        help="Path to write the .trivyignore YAML file.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    input_path = Path(args.input)
    output_path = Path(args.output)

    if not input_path.is_file():
        raise FileNotFoundError(f"Input file not found: {input_path}")

    data = json.loads(input_path.read_text(encoding="utf-8"))
    vulnerabilities = extract_vulnerabilities(data)

    expires_on = add_months(dt.date.today(), 6)
    entries = build_entries(vulnerabilities, expires_on)

    write_yaml(entries, output_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
