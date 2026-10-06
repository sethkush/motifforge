#!/usr/bin/env python3
"""Analyse a headless audio recording against the test's SPIKE_MARK log.

Usage: analyze_audio.py RECORDING.raw START_EPOCH_MS LOG [--rate 48000]

RECORDING.raw is 32-bit float little-endian stereo captured from the
PulseAudio null sink's monitor (parec). START_EPOCH_MS is when parec started.
LOG contains `SPIKE_MARK {...}` lines with epochMs timestamps.

For each playback window (scenario-start/stop, ui-start/stop) it reports:
- rms: overall level (catches "nothing came out");
- sounding_s: length of the continuous sound segment that window produced;
- dropouts: runs of digital silence >= 1 ms on both channels while playback
  should be continuous (an underrun in the audio path writes zeros);
- longest_gap_ms: the longest such run.
Exits non-zero if a window is silent or has dropouts, unless --report-only.
"""

import argparse
import json
import re
import sys

import numpy as np


def windows(marks):
    """Yields (label, start_ms, stop_ms) for each playback window."""
    open_ = {}
    for m in marks:
        ev = m["event"]
        if ev == "scenario-start":
            open_[("scenario", m["index"])] = m
        elif ev == "scenario-stop":
            start = open_.pop(("scenario", m["index"]), None)
            if start:
                label = (
                    f"scenario {m['index']}: lookahead {start['lookaheadMs']} ms, "
                    f"stress {start['stressVoices']}, fx {start['effects']}"
                )
                yield label, start["epochMs"], m["epochMs"], True
        elif ev == "ui-start":
            open_["ui"] = m
        elif ev == "ui-band-off" and "ui" in open_:
            # Band off: only the tapped note sounds, silence is expected.
            yield "ui: band playing", open_.pop("ui")["epochMs"], m["epochMs"], True
        elif ev == "ui-band-on":
            open_["ui"] = m
        elif ev == "ui-stop" and "ui" in open_:
            yield "ui: band playing (after re-enable)", open_.pop("ui")["epochMs"], m["epochMs"], True


def silent_runs(mono_abs, min_len):
    """Start/length of runs where the signal is exactly zero."""
    zero = mono_abs < 1e-7
    if not zero.any():
        return []
    edges = np.diff(np.concatenate(([0], zero.view(np.int8), [0])))
    starts = np.where(edges == 1)[0]
    ends = np.where(edges == -1)[0]
    return [(s, e - s) for s, e in zip(starts, ends) if e - s >= min_len]


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("recording")
    ap.add_argument("start_epoch_ms", type=float)
    ap.add_argument("log")
    ap.add_argument("--rate", type=int, default=48000)
    ap.add_argument("--report-only", action="store_true")
    ap.add_argument("--json", help="write results here")
    args = ap.parse_args()

    audio = np.fromfile(args.recording, dtype="<f4")
    audio = audio[: len(audio) // 2 * 2].reshape(-1, 2)
    level = np.abs(audio).max(axis=1)
    marks = [
        json.loads(m)
        for m in re.findall(r"SPIKE_MARK (\{.*\})", open(args.log, errors="replace").read())
    ]
    rate = args.rate
    results = []
    ok = True
    start_epoch = args.start_epoch_ms
    wins = list(windows(marks))
    # The recorder's start time isn't precise (PulseAudio buffers the
    # monitor), so anchor the timeline on the first sound after the first
    # playback window opens, assuming the first start had the same output
    # latency as later ones. Later starts are reported relative to it.
    if wins:
        search_from = max(int((wins[0][1] - start_epoch - 3000) / 1000 * rate), 0)
        hits = np.nonzero(level[search_from:] > 1e-4)[0]
        if len(hits):
            first_sound_ms = (search_from + hits[0]) / rate * 1000
            offset = first_sound_ms - (wins[0][1] - start_epoch)
            start_epoch -= offset
            print(f"Timeline anchored on the first sound (shift {offset:.0f} ms).\n")
    # Judge each window by the sound segment that starts after its mark:
    # the segment runs until silence of >= 300 ms. Shorter silences inside
    # it are dropouts. Device start-up time is measured in-app instead.
    end_gap = int(0.3 * rate)
    for label, start_ms, stop_ms, continuous in wins:
        a0 = max(int((start_ms - start_epoch - 200) / 1000 * rate), 0)
        limit = min(int((stop_ms - start_epoch + 3000) / 1000 * rate), len(level))
        loud = np.nonzero(level[a0:limit] > 1e-4)[0]
        if not len(loud):
            results.append({"window": label, "error": "no sound"})
            ok = False
            continue
        a = a0 + int(loud[0])
        seg = level[a:limit]
        long_runs = [r for r in silent_runs(seg, end_gap)]
        b = a + (long_runs[0][0] if long_runs else len(seg))
        seg = level[a:b]
        runs = silent_runs(seg, rate // 1000) if continuous else []
        rms = float(np.sqrt(np.mean(audio[a:b] ** 2)))
        r = {
            "window": label,
            "expected_s": round((stop_ms - start_ms) / 1000, 2),
            "sounding_s": round((b - a) / rate, 2),
            "rms": round(rms, 4),
            "dropouts": len(runs),
            "longest_gap_ms": round(max((n for _, n in runs), default=0) / rate * 1000, 2),
            "first_gaps_s": [round((a + s) / rate, 3) for s, _ in runs[:5]],
        }
        if rms < 1e-3 or r["dropouts"]:
            ok = False
        results.append(r)

    print("| Window | Window s | Sounding s | RMS | Dropouts | Longest gap ms |")
    print("|---|---|---|---|---|---|")
    for r in results:
        if "error" in r:
            print(f"| {r['window']} | - | - | - | - | {r['error']} |")
        else:
            print(f"| {r['window']} | {r['expected_s']} | {r['sounding_s']} | {r['rms']} | {r['dropouts']} | {r['longest_gap_ms']} |")
    if not results:
        print("| (no playback windows found in log) | | | | | |")
        ok = False
    if args.json:
        with open(args.json, "w") as f:
            json.dump({"ok": ok, "windows": results}, f, indent=2)
    if not ok and not args.report_only:
        sys.exit(1)


if __name__ == "__main__":
    main()
