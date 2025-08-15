#!/usr/bin/env bash
set -euo pipefail
infile="${1:-texts.txt}"
rate="${2:-1.0}"
vol="${3:--3}"

./tts_batch.sh "$infile" "$rate" "$vol"

mkdir -p wav_faded wav_padded wav_loudnorm mp3_final

# フェード（0.2s in/out）
for f in utt_*.wav; do
  ffmpeg -y -hide_banner -loglevel error -i "$f" \
    -af "afade=t=in:ss=0:d=0.2,afade=t=out:st=0:d=0.2" \
    "wav_faded/$f"
done

# 末尾0.3s無音追加（apad→atrim）
for f in wav_faded/utt_*.wav; do
  dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$f")
  end=$(awk -v d="$dur" 'BEGIN{printf "%.6f", d + 0.3}')
  ffmpeg -y -hide_banner -loglevel error -i "$f" \
    -af "apad=pad_dur=0.3,atrim=0:$end" \
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

zip -qr tts_outputs_final.zip wav_loudnorm mp3_final index.csv

# OneDrive へコピー（必要なら）
WIN_DST="$(wslpath 'C:\Users\07013\OneDrive\Desktop\0816tts')"
mkdir -p "$WIN_DST"
cp -r tts_outputs_final.zip mp3_final "$WIN_DST"/

echo "Done: tts_outputs_final.zip"
