#!/usr/bin/env python3

import argparse
import csv
import sys
from datetime import datetime, timezone


TIME_FORMAT = "%Y-%m-%d %H:%M:%S %Z"


def parse_sar_timestamp(value: str) -> datetime:
    # Expected format:
    # 2026-04-13 04:20:00 UTC
    value = value.strip()

    if value.endswith(" UTC"):
        dt = datetime.strptime(value, TIME_FORMAT)
        return dt.replace(tzinfo=timezone.utc)

    raise ValueError(f"Unsupported timestamp format: {value}")


def parse_cli_timestamp(value: str) -> datetime:
    # Accept either:
    # 2026-04-13 04:20:00
    # 2026-04-13 04:20:00 UTC
    value = value.strip()

    if value.endswith(" UTC"):
        return parse_sar_timestamp(value)

    dt = datetime.strptime(value, "%Y-%m-%d %H:%M:%S")
    return dt.replace(tzinfo=timezone.utc)


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Filter sar CSV data by timestamp range."
    )

    parser.add_argument(
        "input_file",
        help="Input sar CSV file"
    )

    parser.add_argument(
        "--begin",
        required=True,
        help='Begin timestamp, e.g. "2026-04-13 04:30:00"'
    )

    parser.add_argument(
        "--end",
        required=True,
        help='End timestamp, e.g. "2026-04-13 05:20:00"'
    )

    parser.add_argument(
        "-o",
        "--output",
        help="Output file. Defaults to stdout."
    )

    args = parser.parse_args()

    begin_time = parse_cli_timestamp(args.begin)
    end_time = parse_cli_timestamp(args.end)

    if begin_time > end_time:
        print("ERROR: begin timestamp is later than end timestamp", file=sys.stderr)
        return 1

    out_fh = open(args.output, "w", newline="") if args.output else sys.stdout

    try:
        with open(args.input_file, "r", newline="") as in_fh:
            reader = csv.DictReader(in_fh)

            if not reader.fieldnames:
                print("ERROR: input file has no header", file=sys.stderr)
                return 1

            if "timestamp" not in reader.fieldnames:
                print("ERROR: input file does not contain a timestamp column", file=sys.stderr)
                return 1

            writer = csv.DictWriter(out_fh, fieldnames=reader.fieldnames)
            writer.writeheader()

            for row_num, row in enumerate(reader, start=2):
                try:
                    row_time = parse_sar_timestamp(row["timestamp"])
                except ValueError as exc:
                    print(f"WARNING: line {row_num}: {exc}", file=sys.stderr)
                    continue

                if begin_time <= row_time <= end_time:
                    writer.writerow(row)

    finally:
        if args.output:
            out_fh.close()

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
