# TTS Pipeline (pyopenjtalk + ffmpeg)

## 使い方
```bash
./tts_pipeline.sh texts.txt 1.0 -3
# 件数
ls -1 mp3_final | wc -l
# 確認（kana/g2p/長さsecを含む）
head -n 5 index_final.csv


```
