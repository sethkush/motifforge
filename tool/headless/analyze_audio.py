#!/usr/bin/env python3
"""Analyse a headless audio recording against the test's SPIKE_MARK log.

Usage: analyze_audio.py RECORDING.raw START_EPOCH_MS LOG [--rate 48000]

RECORDING.raw is 32-bit float little-endian stereo captured from the
PulseAudio null sink's monitor (parec). START_EPOCH_MS is when parec started.
LOG contains `SPIKE_MARK {...}` lines with epochMs timestamps.

For each playback window (scenario-start/stop, ui-start/stop) it reports:
- rms: overall level (catches "nothing came out");
- sounding_s: length of the continuous sound segment that window produced;
- start_gap_ms: silence in the first 400 ms of the sound (stream start-up);
- dropouts: later runs of digital silence >= 1 ms on both channels while
  playback should be continuous (an underrun writes zeros);
- longest_gap_ms: the longest such dropout.
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
    ap.add_argument("--max-start-gap-ms", type=float, default=300,
                    help="fail if silence in the first 400 ms of a stream exceeds this")
    ap.add_argument("--dropouts-informational", action="store_true",
                    help="report mid-playback dropouts without failing")
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
        # Split [a0, limit) into sound segments separated by >= 300 ms of
        # silence and take the longest one that starts within 2 s of the
        # mark (an earlier note's tail can precede the window's own sound).
        win = level[a0:limit]
        segments = []
        pos = 0
        for s0, n in silent_runs(win, end_gap) + [(len(win), 0)]:
            if s0 > pos:
                segments.append((pos, s0))
            pos = s0 + n
        segments = [g for g in segments if g[0] <= 2 * rate and win[g[0]:g[1]].max() > 1e-4]
        if not segments:
            results.append({"window": label, "error": "no sound"})
            ok = False
            continue
        g0, g1 = max(segments, key=lambda g: g[1] - g[0])
        # Trim to the first and last audible sample: the segment can begin
        # with (short) silence from before the mark.
        audible = np.nonzero(win[g0:g1] > 1e-4)[0]
        a, b = a0 + g0 + int(audible[0]), a0 + g0 + int(audible[-1]) + 1
        seg = level[a:b]
        runs = silent_runs(seg, rate // 1000) if continuous else []
        # Gaps in the first 400 ms are a stream-start stall (device/server
        # warming up); later ones are real dropouts during playback.
        start_runs = [r for r in runs if r[0] < 0.4 * rate]
        mid_runs = [r for r in runs if r[0] >= 0.4 * rate]
        rms = float(np.sqrt(np.mean(audio[a:b] ** 2)))
        r = {
            "window": label,
            "expected_s": round((stop_ms - start_ms) / 1000, 2),
            "sounding_s": round((b - a) / rate, 2),
            "rms": round(rms, 4),
            "start_gap_ms": round(sum(n for _, n in start_runs) / rate * 1000, 1),
            "dropouts": len(mid_runs),
            "longest_gap_ms": round(max((n for _, n in mid_runs), default=0) / rate * 1000, 2),
            "gaps_at_s": [round(float(s0) / rate, 3) for s0, _ in runs[:6]],
        }
        if rms < 1e-3:
            ok = False
        if r["start_gap_ms"] > args.max_start_gap_ms:
            ok = False
        if r["dropouts"] and not args.dropouts_informational:
            ok = False
        results.append(r)

    print("| Window | Window s | Sounding s | RMS | Start gap ms | Dropouts | Longest dropout ms | Gaps at (s into sound) |")
    print("|---|---|---|---|---|---|---|---|")
    for r in results:
        if "error" in r:
            print(f"| {r['window']} | - | - | - | - | - | - | {r['error']} |")
        else:
            print(f"| {r['window']} | {r['expected_s']} | {r['sounding_s']} | {r['rms']} | "
                  f"{r['start_gap_ms']} | {r['dropouts']} | {r['longest_gap_ms']} | {r['gaps_at_s']} |")
    if not results:
        print("| (no playback windows found in log) | | | | | | | |")
        ok = False
    if args.dropouts_informational:
        print("\nDropouts are informational here (known issue, see docs/spikes/m0-audio.md).")
    if args.json:
        with open(args.json, "w") as f:
            json.dump({"ok": ok, "windows": results}, f, indent=2)
    if not ok and not args.report_only:
        sys.exit(1)


if __name__ == "__main__":
    main()
