all:
	./tts_pipeline.sh texts.txt 1.0 -3
clean:
	rm -f utt_*.wav index*.csv
	rm -rf mp3 mp3_final wav_* *.zip
