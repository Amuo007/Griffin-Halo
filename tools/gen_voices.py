#!/usr/bin/env python3
"""Generate cutscene voice lines with edge-tts. Run from project root."""
import re, os, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STORY = os.path.join(ROOT, "scripts", "autoload", "StoryData.gd")
OUT = os.path.join(ROOT, "audio", "voices")
EDGE = os.path.join(ROOT, ".tools-venv", "bin", "edge-tts")

VOICE_MAP = {
    "griffin": ("en-US-GuyNeural", "+0%", "+2Hz"),
    "marcus": ("en-US-ChristopherNeural", "-6%", "-4Hz"),
    "elena": ("en-US-JennyNeural", "+0%", "+0Hz"),
    "vera": ("en-US-AriaNeural", "-8%", "-2Hz"),
    "narrator": ("en-GB-RyanNeural", "+0%", "+0Hz"),
}

def parse():
    src = open(STORY).read()
    scenes = {}
    cur = None
    for m in re.finditer(r'"(\w+)": \{"lines": \[(.*?)\]', src, re.S):
        name, body = m.group(1), m.group(2)
        lines = re.findall(r'\{"speaker": "(\w+)", "text": "(.*?)", "seconds"', body)
        scenes[name] = lines
    # intro scene has "scene" key before lines
    m = re.search(r'"intro": \{"scene":.*?"lines": \[(.*?)\]', src, re.S)
    if m:
        scenes["intro"] = re.findall(r'\{"speaker": "(\w+)", "text": "(.*?)", "seconds"', m.group(1))
    return scenes

def main():
    os.makedirs(OUT, exist_ok=True)
    scenes = parse()
    total = sum(len(v) for v in scenes.values())
    print(f"scenes: {list(scenes.keys())} total lines: {total}")
    done = 0
    for scene, lines in scenes.items():
        for i, (speaker, text) in enumerate(lines):
            out = os.path.join(OUT, f"{scene}_{i:02d}.mp3")
            if os.path.exists(out) and os.path.getsize(out) > 1000:
                done += 1
                continue
            voice, rate, pitch = VOICE_MAP[speaker]
            text = text.replace('\\"', '"').replace("&", "and")
            cmd = [EDGE, "--voice", voice, "--rate", rate, "--pitch", pitch,
                   "--text", text, "--write-media", out]
            r = subprocess.run(cmd, capture_output=True, text=True)
            if r.returncode != 0:
                print(f"FAIL {scene}_{i}: {r.stderr[:200]}")
                sys.exit(1)
            done += 1
            print(f"[{done}/{total}] {scene}_{i:02d} ({speaker})")
    print("voices complete")

if __name__ == "__main__":
    main()
