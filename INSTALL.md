# Setup
python3.11 -m venv xtts311
source xtts311/bin/activate
pip install -r requirements.lock.txt  # or requirements.freeze.txt
# 実行
./xtts_batch.sh texts.txt ref/ref.wav
