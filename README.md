# embed-stt-tts-with-ollama-docker-compose-for-low-resource-laptop
저사양 노트북에서  text embedding, stt, tts 를 ollama 에 연동한 docker compose 저장소

구형 노트북에서 Ollama를 Docker Compose로 띄우고, intfloat-multilingual-e5-large-instruct, Kokoro-82M, OpenAI Whisper: base 모델까지 자동 다운로드/설치하는 사례별 compose 파일 코드를 아래처럼 구성할 수 있다. 각각의 모델은 Ollama에서 지원하는 경우 Ollama pull 로, Whisper와 Kokoro-82M은 별도 컨테이너로 세팅하는 구성이 대중적이다.​

Step 1: docker-compose.yml 전체 예시
text
version: '3'

services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    ports:
      - "11434:11434"
    volumes:
      - ollama_data:/root/.ollama
    restart: unless-stopped
    # Ollama 시작시 모델 자동 pull 명령 실행(설치)
    entrypoint: /bin/bash -c "ollama serve & sleep 5 && ollama pull jeffh/intfloat-multilingual-e5-large-instruct && ollama pull kokoro:82m && ollama pull whisper:base && wait"
    # 모델 이름은 실제 Ollama 등록명을 확인 필요 (`kokoro:82m` 등은 예시, 최신 모델명 확인)
    
  kokoro-fastapi:
    image: remsky/kokoro-fastapi:latest
    container_name: kokoro
    ports:
      - "5001:5001"
    restart: unless-stopped
    # 별도 REST TTS API 용 공식 kokoro-fastapi 이미지
    # 실제 FastAPI 로 제공

  whisper:
    build:
      context: ./whisper
      dockerfile: Dockerfile
    container_name: whisper
    ports:
      - "9000:9000"
    restart: unless-stopped
    # whisper 컨테이너 예시 (커스텀 빌드 필요, 아래 Dockerfile 참고)

volumes:
  ollama_data:
Step 2: Whisper Dockerfile 예시
whisper 디렉토리에 아래 Dockerfile 파일 배치

text
FROM python:3.10-slim
WORKDIR /app
RUN apt-get update && apt-get install -y ffmpeg
RUN pip install --upgrade pip
RUN pip install openai-whisper
COPY . /app
CMD ["python", "main.py"]
Step 3: 주요 단계별 설명
Ollama 서비스
Ollama 서비스는 entrypoint에 모델 자동 pull을 넣어놓으면 시작 후 모델 설치가 자동화됨.​

모델명은 Ollama 공식 웹사이트의 명칭을 반드시 확인해 최신 버전으로 입력(예시: jeffh/intfloat-multilingual-e5-large-instruct).

모델 설치는 인터넷 연결에 따라 수 분 이상이 소요될 수 있다.

ollama가 Docker에서 메모리 제한 또는 네트워크 오류 발생시 pull이 실패할 수 있다. 이때는 docker exec -it ollama ollama pull <모델명> 방식으로 수동 재설치 가능.​

Kokoro-82M 서비스
FastAPI 기반 REST API TTS 서버 이미지를 제공하는 공식 Docker 이미지를 사용한다.​

서비스 포트(5001)는 변경 가능. 높은 동시 요청(실시간 합성)은 사양 영향 받으므로, 저사양에서는 합성속도가 느릴 수 있다.

Whisper 서비스
Whisper는 huggingface, openai-whisper 등의 빌드 방식이 존재. 예시 Dockerfile 기준으로 직접 빌드한다.

Whisper는 ffmpeg 의존성이 꼭 필요하므로 apt-get 설치 추가.

CPU 환경에 최적화된 base 모델 사용(large는 구형 노트북에서 느릴 수 있음).

PyTorch, numpy 등 추가 패키지가 필요할 수 있으니 설치 중 ImportError가 나면 requirements.txt에 추가한다.​

Step 4: 설치 전 체크리스트 및 오류 대응
docker-compose는 최신 버전 사용 권장, 오래된 노트북에서 OS별로 설치법 상이할 수 있음.

entrypoint의 shell 명령어 실행이 올라마 환경마다 달라 오류가 날 수 있음. 실패시 entrypoint없이 docker compose up 후 별도 docker exec로 모델 설치를 권장.​

Ollama pull 중 네트워크 다운/모델 OS 공간 부족 오류가 빈번히 발생. 꼭 디스크 여유 및 네트워크 상태 체크.

Whisper 컨테이너 빌드 중 ffmpeg 설치 실패, 메모리 부족, PyTorch 설치 중 오래 걸리는 현상 주의.

Kokoro-82M 컨테이너 실행시 권한 오류, 포트 중복 여부 확인.

Step 5: 실행 명령 요약
bash
docker compose pull
docker compose up -d
설치 후 모델이 정상 설치되었는지 Ollama API (curl localhost:11434/api/tags)로 확인하거나, 각 서비스 컨테이너 내부에서 직접 테스트하면 된다.

구체적 모델명 업데이트, 빌드 관련 requirements 추가 조정, docker-compose entrypoint 사용시 컨테이너 부팅 순서(실행 지연 등) 등에 유의하면 설치가 잘 된다.​
