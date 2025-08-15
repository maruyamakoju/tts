#!/usr/bin/env bash
set -euo pipefail
infile="${1:-texts.txt}"
rate="${2:-1.0}"
vol="${3:--3}"

fade_d="0.2"   # フェード秒
pad_d="0.3"    # 末尾無音秒

./tts_batch.sh "$infile" "$rate" "$vol"

mkdir -p wav_faded wav_padded wav_loudnorm mp3_final

# フェード
for f in utt_*.wav; do
  ffmpeg -y -hide_banner -loglevel error -i "$f" \
    -af "afade=t=in:ss=0:d=${fade_d},afade=t=out:st=0:d=${fade_d}" \
    "wav_faded/$f"
done

# 末尾無音付与（apad→atrim）
for f in wav_faded/utt_*.wav; do
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")
  end=$(awk -v d="$dur" -v p="$pad_d" 'BEGIN{printf "%.6f", d + p}')
  ffmpeg -y -hide_banner -loglevel error -i "$f" \
    -af "apad=pad_dur=${pad_d},atrim=0:$end" \
    "wav_padded/$(basename "$f")"
done

# ラウドネス整音
for f in wav_padded/utt_*.wav; do
  ffmpeg -y -hide_banner -loglevel error -i "$f" \
    -af "loudnorm=I=-16:TP=-1.0:LRA=11" -ar 48000 \
    "wav_loudnorm/$(basename "$f")"
done

# 最終MP3
for f in wav_loudnorm/utt_*.wav; do
  base=$(basename "$f" .wav)
  ffmpeg -y -hide_banner -loglevel error -i "$f" \
    -ar 48000 -ac 1 -b:a 128k "mp3_final/${base}.mp3"
done

# index_final.csv（最終WAVの長さを付与）
python - <<'PY'
import csv, subprocess, shlex
def dur(p):
    cmd=f'ffprobe -v error -show_entries format=duration -of csv=p=0 {shlex.quote(p)}'
    return float(subprocess.check_output(cmd, shell=True).decode().strip())
rows=[]
with open("index.csv", encoding="utf-8", newline="") as rf:
    for r in csv.DictReader(rf):
        wid=r["id"]; final=f"wav_loudnorm/utt_{wid}.wav"
        rows.append({**r,"wav_path":final,"duration_sec":f"{dur(final):.3f}"})
with open("index_final.csv","w",encoding="utf-8",newline="") as wf:
    w=csv.DictWriter(wf,fieldnames=["id","text","wav_path","kana","g2p","duration_sec"])
    w.writeheader(); w.writerows(rows)
PY

zip -qr tts_outputs_final.zip wav_loudnorm mp3_final index.csv index_final.csv

# （WSLのみ）OneDriveにコピー：存在すれば実行
if command -v wslpath >/dev/null 2>&1; then
  WIN_DST="$(wslpath 'C:\Users\07013\OneDrive\Desktop\0816tts' 2>/dev/null || true)"
  [ -n "${WIN_DST:-}" ] && { mkdir -p "$WIN_DST"; cp -r tts_outputs_final.zip mp3_final "$WIN_DST/"; }
fi

echo "Done: tts_outputs_final.zip"
