#!/usr/bin/env bash
set -euo pipefail

infile="${1:-texts.txt}"   # 1行=1文
rate="${2:-1.0}"           # 0.5～2.0
vol="${3:--3}"             # dB

rm -f utt_*.wav index.csv
mkdir -p mp3

# ---- 合成（辞書DLは初回のみ）----
python - <<'PY' "$infile"
import sys, wave, csv, numpy as np, pyopenjtalk as oj
infile = sys.argv[1]
sr = 48000
rows = []
n = 1
with open(infile, 'r', encoding='utf-8') as f:
    for line in f:
        text = line.strip()
        if not text:
            continue
        # 合成
        y, _ = oj.tts(text)            # float64 -1..1
        y16 = (np.clip(y, -1, 1) * 32767).astype(np.int16)
        fn = f"utt_{n:03d}.wav"
        with wave.open(fn, 'wb') as wf:
            wf.setnchannels(1); wf.setsampwidth(2); wf.setframerate(sr)
            wf.writeframes(y16.tobytes())
        # メタ（かな / g2p）
        kana = oj.g2p(text, kana=True)
        g2p  = oj.g2p(text)
        rows.append([f"{n:03d}", text, fn, kana, g2p])
        print(f"saved: {fn}")
        n += 1

# 一次CSV（ここでは長さは入れない。後段で最終wavの長さを入れる）
with open("index.csv", "w", encoding="utf-8", newline="") as wf:
    w = csv.writer(wf)
    w.writerow(["id","text","wav_path","kana","g2p"])
    w.writerows(rows)
PY

# ---- 一次MP3化（速度/音量適用）----
for f in utt_*.wav; do
  base="${f%.wav}"
  ffmpeg -y -hide_banner -loglevel error -i "$f" \
    -af "atempo=${rate},volume=${vol}dB" \
    -ar 48000 -ac 1 -b:a 128k "mp3/${base}.mp3"
done

zip -qr tts_outputs.zip utt_*.wav mp3 index.csv
echo "Done: tts_outputs.zip"
