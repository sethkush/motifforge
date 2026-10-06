#!/usr/bin/env python3
"""Regression tests for analyze_audio.py on synthetic recordings.

Run: python3 tool/headless/test_analyze_audio.py
"""
import json
import os
import subprocess
import sys
import tempfile

import numpy as np

RATE = 48000
HERE = os.path.dirname(os.path.abspath(__file__))


def analyse(signal, *extra):
    d = tempfile.mkdtemp()
    np.repeat(signal.astype("<f4"), 2).tofile(f"{d}/r.raw")
    with open(f"{d}/log", "w") as f:
        f.write('SPIKE_MARK {"event":"scenario-start","index":0,"lookaheadMs":100,'
                '"stressVoices":0,"effects":true,"epochMs":1000}\n')
        f.write('SPIKE_MARK {"event":"scenario-stop","index":0,"epochMs":4000}\n')
    p = subprocess.run(
        [sys.executable, f"{HERE}/analyze_audio.py", f"{d}/r.raw", "0", f"{d}/log",
         "--json", f"{d}/out.json", *extra],
        capture_output=True, text=True)
    return p.returncode, json.load(open(f"{d}/out.json"))


def tone(seconds=6):
    x = np.zeros(RATE * seconds)
    x[RATE:4 * RATE] = 0.1  # sound from 1 s to 4 s, matching the marks
    return x


def check(name, cond):
    print(("PASS " if cond else "FAIL ") + name)
    return cond


ok = True
rc, r = analyse(tone())
w = r["windows"][0]
ok &= check("clean tone passes", rc == 0 and w["dropouts"] == 0 and w["start_gap_ms"] == 0)
ok &= check("sounding length ~3 s", abs(w["sounding_s"] - 3.0) < 0.01)

x = tone()
x[int(1.5 * RATE):int(1.5 * RATE) + 480] = 0  # 10 ms dropout 0.5 s in
rc, r = analyse(x)
w = r["windows"][0]
ok &= check("mid-playback dropout fails", rc == 1 and w["dropouts"] == 1)
ok &= check("dropout located at 0.5 s", w["gaps_at_s"] == [0.5])
ok &= check("dropout length 10 ms", abs(w["longest_gap_ms"] - 10) < 0.1)

rc, r = analyse(x, "--dropouts-informational")
ok &= check("--dropouts-informational reports but passes", rc == 0 and r["windows"][0]["dropouts"] == 1)

x = tone()
x[int(1.1 * RATE):int(1.1 * RATE) + RATE // 4] = 0  # 250 ms stall right after start
rc, r = analyse(x, "--max-start-gap-ms", "100")
ok &= check("start stall counted separately", r["windows"][0]["start_gap_ms"] > 200 and r["windows"][0]["dropouts"] == 0)
ok &= check("start stall over limit fails", rc == 1)

rc, r = analyse(np.zeros(RATE * 6))
ok &= check("silence fails", rc == 1 and "error" in r["windows"][0])

sys.exit(0 if ok else 1)
