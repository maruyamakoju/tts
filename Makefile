all:
	./tts_pipeline.sh texts.txt 1.0 -3

test:
	echo "テストです。" > _sample.txt
	./tts_pipeline.sh _sample.txt 1.0 -3
	head -n 5 index_final.csv

clean:
	rm -f utt_*.wav index*.csv _sample.txt
	rm -rf mp3 mp3_final wav_* *.zip
