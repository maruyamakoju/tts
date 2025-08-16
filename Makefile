SHELL := /bin/bash

IN_TXT := texts.txt
REF_WAV := ref/ref.wav

all: run zip

run:
	./xtts_batch.sh $(IN_TXT) $(REF_WAV)

index:
	awk '!/^\s*#/ && NF{n++; printf("utt_%03d.mp3,%s\n", n, $$0)}' $(IN_TXT) > index_final_xtts.csv

durations:
	@for f in mp3_final_xtts/*.mp3; do \
	  dur=$$(ffprobe -v error -show_entries format=duration -of csv=p=0 $$f); \
	  printf "%s,%.2f\n" $$(basename $$f) $$dur; \
	done | sort > durations.csv

sha:
	( cd mp3_final_xtts && sha256sum *.mp3 ) > SHA256SUMS.txt

zip: index durations sha
	join -t, -1 1 -2 1 <(sort -t, -k1,1 index_final_xtts.csv) <(sort -t, -k1,1 durations.csv) > index_with_duration.csv
	zip -r "tts_xtts_release_$$(date +%Y%m%d_%H%M).zip" mp3_final_xtts index_final_xtts.csv index_with_duration.csv SHA256SUMS.txt

clean:
	rm -rf xtts_out wav_final mp3_final_xtts durations.csv index_with_duration.csv tts_xtts_release_*.zip SHA256SUMS.txt
