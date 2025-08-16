VENV=xtts311
run:
	./xtts_batch.sh texts.txt ref/ref.wav
zip:
	@for f in mp3_final_xtts/*.mp3; do \
	  dur=$$(ffprobe -v error -show_entries format=duration -of csv=p=0 $$f); \
	  printf "%s,%.2f\n" $$(basename $$f) $$dur; \
	done | sort > durations.csv
	join -t, -1 1 -2 1 <(sort -t, -k1,1 index_final_xtts.csv) <(sort -t, -k1,1 durations.csv) > index_with_duration.csv
	zip -r "tts_xtts_release_$$(date +%Y%m%d_%H%M).zip" mp3_final_xtts index_final_xtts.csv index_with_duration.csv
clean:
	rm -rf xtts_out wav_final mp3_final_xtts durations.csv index_with_duration.csv
