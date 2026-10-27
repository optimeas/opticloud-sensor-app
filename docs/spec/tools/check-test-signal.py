#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
"""Checks the test signal in device data exported from optiCLOUD as CSV.

The group `test` is described in docs/spec/sensors.md. The export needs the columns `timestamp` (milliseconds since
1970) and `testCounter`; `testSine` is checked where it is present. Rows without `testCounter`, such as event values
or samples of the command `sendNow`, are skipped for the counter.

Usage: check-test-signal.py EXPORT.csv [--send-rate SECONDS]

Without --send-rate the send rate is taken from the data: the most common time between two successive ticks.
The exit code is 0 when no sample was lost, the app did not pause, and every testSine belongs to its time stamp.
"""

import argparse
import csv
import math
import sys
from collections import Counter
from datetime import datetime

PERIOD_MS = 60000
SINE_RESOLUTION = 0.001


def expected_sine(ts):
    """testSine for a time stamp, rounded half away from zero to the resolution (see sensors.md)."""
    value = math.sin(2 * math.pi * (ts % PERIOD_MS) / PERIOD_MS)
    scaled = value / SINE_RESOLUTION
    return math.copysign(math.floor(abs(scaled) + 0.5), scaled) * SINE_RESOLUTION


def number(text):
    text = (text or "").strip()
    return float(text) if text else None


def local_time(ts):
    return datetime.fromtimestamp(ts / 1000).strftime("%Y-%m-%d %H:%M:%S")


def duration(ms):
    seconds = round(ms / 1000)
    if seconds < 120:
        return f"{seconds} s"
    return f"{seconds // 60} min {seconds % 60} s"


def read(path):
    with open(path, newline="", encoding="utf-8-sig") as file:
        reader = csv.DictReader(file)
        missing = {"timestamp", "testCounter"} - set(reader.fieldnames or [])
        if missing:
            sys.exit(f"{path}: no column {' and no column '.join(sorted(missing))}. Was the group test selected?")
        rows = []
        for row in reader:
            ts = number(row["timestamp"])
            if ts is None:
                continue
            rows.append((int(ts), number(row.get("testCounter")), number(row.get("testSine"))))
    rows.sort(key=lambda row: row[0])
    return rows


def main():
    parser = argparse.ArgumentParser(description="Checks the test signal in a CSV export from optiCLOUD.")
    parser.add_argument("export", help="CSV export of the device data")
    parser.add_argument("--send-rate", type=int, help="send rate in whole seconds, 1 to 3600")
    args = parser.parse_args()

    rows = read(args.export)
    ticks = [(ts, int(counter)) for ts, counter, _ in rows if counter is not None]
    if not ticks:
        sys.exit(f"{args.export}: no row has a testCounter. Was the group test selected?")

    steps = [later[0] - earlier[0] for earlier, later in zip(ticks, ticks[1:]) if later[1] == earlier[1] + 1]
    if args.send_rate:
        send_rate = args.send_rate
        rate_source = "given"
    elif steps:
        send_rate = max(1, Counter(round(step / 1000) for step in steps).most_common(1)[0][0])
        rate_source = "from the data"
    else:
        send_rate = 2
        rate_source = "assumed"
    max_age_ms = max(10, 2 * send_rate) * 1000

    lost, pauses, restarts, repeated = [], [], [], []
    for (ts0, counter0), (ts1, counter1) in zip(ticks, ticks[1:]):
        if counter1 == 1 and counter0 != 0:
            restarts.append(ts1)
        elif counter1 == counter0:
            repeated.append((ts1, counter1))
        elif counter1 > counter0 + 1:
            lost.append((ts0, ts1, counter0, counter1))
        elif counter1 < counter0:
            restarts.append(ts1)
        # A gap before a restart is a pause too: the app did not run in between.
        if counter1 != counter0 and counter1 <= counter0 + 1 and ts1 - ts0 > max_age_ms:
            pauses.append((ts0, ts1))

    wrong = [(ts, sine, expected_sine(ts)) for ts, _, sine in rows
             if sine is not None and abs(sine - expected_sine(ts)) > SINE_RESOLUTION / 2 + 1e-9]
    sines = sum(1 for _, _, sine in rows if sine is not None)
    lost_count = sum(counter1 - counter0 - 1 for _, _, counter0, counter1 in lost)

    first, last = ticks[0][0], ticks[-1][0]
    print(f"File:        {args.export}")
    print(f"Ticks:       {len(ticks)}, {local_time(first)} to {local_time(last)} ({duration(last - first)})")
    print(f"Send rate:   {send_rate} s ({rate_source}); a pause is longer than {max_age_ms // 1000} s")
    print(f"Runs:        {len(restarts) + 1}" + "".join(f"\n             started again at {local_time(ts)}" for ts in restarts))
    print(f"Lost:        {lost_count} samples")
    for ts0, ts1, counter0, counter1 in lost:
        print(f"             {counter1 - counter0 - 1} between {local_time(ts0)} and {local_time(ts1)} "
              f"(testCounter {counter0} to {counter1})")
    print(f"Pauses:      {len(pauses)}")
    for ts0, ts1 in pauses:
        print(f"             {duration(ts1 - ts0)} from {local_time(ts0)} to {local_time(ts1)}")
    if repeated:
        print(f"Repeated:    {len(repeated)} ticks with the same testCounter as the one before")
    print(f"testSine:    {sines} checked, {len(wrong)} wrong")
    for ts, sine, expected in wrong[:20]:
        print(f"             {local_time(ts)}: {sine:g}, expected {expected:g}")
    if len(wrong) > 20:
        print(f"             and {len(wrong) - 20} more")

    ok = not lost and not pauses and not wrong
    print("Result:      " + ("OK" if ok else "problems found"))
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
