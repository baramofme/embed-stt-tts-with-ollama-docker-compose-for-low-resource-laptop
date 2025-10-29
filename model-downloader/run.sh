# model-downloader/run.sh
#!/bin/bash
set -e
MODEL_DIR=${MODEL_DIR:-/files}

mkdir -p "${MODEL_DIR}"

# 1. 다운 가능한 실제 경로와 파일명은 인터넷에서 확인한 링크로 교체
# intfloat-multilingual-e5-large-instruct
wget -O "${MODEL_DIR}/intfloat-multilingual-e5-large-instruct-q8_0.gguf" "https://huggingface.co/jeffh/intfloat-multilingual-e5-large-instruct/resolve/main/intfloat-multilingual-e5-large-instruct-q8_0.gguf"

# Kokoro-82M
wget -O "${MODEL_DIR}/kokoro-82m.onnx" "https://github.com/kokoron81/kokoro/releases/download/v0.19/kokoro-v0_19.onnx"

# Whisper: base
wget -O "${MODEL_DIR}/whisper-base.bin" "https://huggingface.co/openai/whisper/resolve/main/ggml-model-base.bin"

echo "모델 다운 완료. MODEL_DIR=${MODEL_DIR}"
