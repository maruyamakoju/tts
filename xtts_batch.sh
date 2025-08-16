#!/usr/bin/env bash
set -Eeuo pipefail
export LC_ALL=C.UTF-8 LANG=C.UTF-8
export TOKENIZERS_PARALLELISM=false HF_HUB_DISABLE_TELEMETRY=1 TRANSFORMERS_NO_ADVISORY_WARNINGS=1

IN_TXT="${1:-texts.txt}"
REF_WAV="${2:-ref/ref.wav}"

[[ -s "$IN_TXT" ]] || { echo "入力テキストが見つかりません: $IN_TXT" >&2; exit 1; }
[[ -s "$REF_WAV" ]] || { echo "参照話者が見つかりません: $REF_WAV" >&2; exit 1; }

OUT_WAV_DIR="xtts_out"
OUT_WAV_FINAL_DIR="wav_final"
OUT_MP3_DIR="mp3_final_xtts"
mkdir -p "$OUT_WAV_DIR" "$OUT_WAV_FINAL_DIR" "$OUT_MP3_DIR"

FILTER='highpass=80,lowpass=10000,alimiter=limit=0.97,afade=t=in:ss=0:d=0.02,areverse,afade=t=in:ss=0:d=0.02,areverse,loudnorm=I=-18:TP=-1.5:LRA=11'

i=0
while IFS= read -r line || [[ -n "$line" ]]; do
  [[ -z "${line// }" || "${line:0:1}" == "#" ]] && continue
  ((++i))
  base=$(printf "utt_%03d" "$i")
  wav="$OUT_WAV_DIR/${base}.wav"
  wavf="$OUT_WAV_FINAL_DIR/${base}_final.wav"
  mp3="$OUT_MP3_DIR/${base}.mp3"

  echo "[$base] TTS..."
  if printf 'y\n' | tts --text "$line" \
        --model_name "tts_models/multilingual/multi-dataset/xtts_v2" \
        --language_idx ja \
        --speaker_wav "$REF_WAV" \
        --out_path "$wav"; then
    if [[ -s "$wav" ]]; then
      ffmpeg -nostdin -hide_banner -loglevel error -y -i "$wav" -af "$FILTER" -ar 24000 -ac 1 "$wavf"
      ffmpeg -nostdin -hide_banner -loglevel error -y -i "$wavf" -b:a 192k "$mp3"
      echo "[$base] OK -> $mp3"
    else
      echo "[$base] 失敗: WAV 未生成" >&2
    fi
  else
    echo "[$base] 失敗: tts コマンド" >&2
  fi
done < "$IN_TXT"

echo "----"
echo "生成MP3数: $(find "$OUT_MP3_DIR" -type f -name '*.mp3' | wc -l)"
