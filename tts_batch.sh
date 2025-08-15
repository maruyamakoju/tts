#!/usr/bin/env bash
set -euo pipefail

infile="${1:-texts.txt}"   # 1行=1文のテキスト
rate="${2:-1.0}"           # 0.5～2.0 (ffmpeg atempo)
vol="${3:--3}"             # dB (ffmpeg volume)

rm -f utt_*.wav index.csv
mkdir -p mp3

# ---- 合成（辞書DLを1回に抑える）----
python - <<'PY' "$infile"
import sys, wave, numpy as np
import pyopenjtalk as oj

infile = sys.argv[1]
sr = 48000
n = 1
with open(infile, 'r', encoding='utf-8') as f:
    for line in f:
        text = line.strip()
        if not text:
            continue
        y, _ = oj.tts(text)         # float64 -1..1
        y16 = (np.clip(y, -1, 1) * 32767).astype(np.int16)
        fn = f"utt_{n:03d}.wav"
        with wave.open(fn, 'wb') as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(sr)
            wf.writeframes(y16.tobytes())
        print(f"saved: {fn}")
        n += 1
PY

# ---- 一次MP3化（速度/音量をここで適用）----
for f in utt_*.wav; do
  base="${f%.wav}"
  ffmpeg -y -hide_banner -loglevel error -i "$f" \
    -af "atempo=${rate},volume=${vol}dB" \
    -ar 48000 -ac 1 -b:a 128k "mp3/${base}.mp3"
done

# ---- index.csv（id,text,wav_path,duration_sec）----
: > index.csv
echo "id,text,wav_path,duration_sec" >> index.csv
n=1
while IFS= read -r line; do
  [ -z "$line" ] && continue
  fname=$(printf "utt_%03d.wav" "$n")
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$fname")
  printf "%03d,\"%s\",%s,%.3f\n" "$n" "$line" "$fname" "$dur" >> index.csv
  n=$((n+1))
done < "$infile"

zip -qr tts_outputs.zip utt_*.wav mp3 index.csv
echo "Done: tts_outputs.zip"
