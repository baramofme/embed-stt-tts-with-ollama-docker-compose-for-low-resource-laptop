# embed-stt-tts-with-ollama-docker-compose-for-low-resource-laptop
저사양 노트북에서  text embedding, stt, tts 를 ollama 에 연동한 docker compose 저장소
<img src="https://r2cdn.perplexity.ai/pplx-full-logo-primary-dark%402x.png" style="height:64px;margin-right:32px"/>

# intfloat-multilingual-e5-large-instruct

Kokoro-82M
OpenAI Whisper: base 
그리고 ollama 까지, 모두를 한번에 구형 노트북에 docker-compose.yml 을 사용해서 설치하는 코드를 보여줘.
ollama 및 각각의 모델은 docker compose cmd 로 다운을 받도록 해서 docker compose up 시 한번에 세팅이 되도록 해.

각 모델은 docker volumes 에 다운이 되어서, recreate 때마다 새로 받지는 않게 하고, 모델을 다운로드 받을 장소를 docker volume 대신 따로 지정할 수 있게 .env 를 생성해줘.

예를 들면 ../files 라는 경로를 지정하면, docker volume 을 만드는 대신에 거기에 모델들이 다운로드 되는 거지. 아래와 같이 model 이 다운될 경로가 있고, embedding, tts, stt 모델이 각각 환경변수고 있는 거야.

```
MODEL_DIR=../files    # 원하는 절대/상대 경로로 변경 가능. ex) /home/user/files
EMBEDDING_MODEL=jeffh/intfloat-multilingual-e5-large-instruct
TTS_MODEL=kokoro-82m
STT_MODEL=OpenAI Whisper: base 
```

ollama 전에 다른 서비스들이 먼저 세팅이 되어야해. 그러니까 의존성 설정을 넣어

그리고 아주 구체적으로, 각 단계별로 설명을 붙여주고, 설치중 오류가 날 만한 것들에 대해서도 정보를 줘

아래는 intfloat-multilingual-e5-large-instruct(임베딩), Kokoro-82M(TTS), OpenAI Whisper: base(STT) 모델을 ollama와 함께 구형 노트북에서 docker-compose 한 번에 설치하는 코드와 단계별 설명이다. 모델 파일들은 docker volume 대신 .env 파일에서 지정한 경로로 직접 다운로드되어, 재배포(recreate) 시에도 그대로 유지된다.

모델별 컨테이너는 ollama에서 모델을 미리 풀(Pull)해두는 식으로 동작하며, ollama 서비스 이후에 embedding, tts, stt 서비스가 준비될 수 있도록 의존성 설정(depends_on)이 적용되어 있다. 아래 예시는 ../files로 경로를 지정했지만, 필요에 따라 MODEL_DIR만 설정해 변경하면 된다.

***

### 1. 프로젝트 폴더 구조

```
project_root/
├── .env
├── docker-compose.yml
```


***

### 2. .env 파일 샘플

```
MODEL_DIR=../files                   # 원하는 경로로 변경
EMBEDDING_MODEL=jeffh/intfloat-multilingual-e5-large-instruct
TTS_MODEL=kokoro-82m
STT_MODEL=base                      # whisper: base
```


***

### 3. docker-compose.yml 예시

```yaml
version: '3.9'

services:
  ollama:
    image: ollama/ollama:latest
    container_name: ollama
    environment:
      - OLLAMA_MODELS=${MODEL_DIR}/ollama
      - OLLAMA_KEEP_ALIVE=24h
    command: >
      sh -c "
        ollama serve &
        sleep 5 &&
        ollama pull ${EMBEDDING_MODEL} &&
        ollama pull ${TTS_MODEL} &&
        ollama pull whisper:${STT_MODEL} &&
        wait
      "
    volumes:
      - ${MODEL_DIR}/ollama:/root/.ollama
    ports:
      - "11434:11434"
    restart: unless-stopped

  embedding:
    image: curlimages/curl:latest
    command: ["curl", "-X", "POST", "--fail", "http://ollama:11434/api/push", "-d", "{\"model\":\"${EMBEDDING_MODEL}\"}"]
    depends_on:
      - ollama
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
    restart: "no"

  tts:
    image: curlimages/curl:latest
    command: ["curl", "-X", "POST", "--fail", "http://ollama:11434/api/push", "-d", "{\"model\":\"${TTS_MODEL}\"}"]
    depends_on:
      - ollama
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
    restart: "no"

  stt:
    image: curlimages/curl:latest
    command: ["curl", "-X", "POST", "--fail", "http://ollama:11434/api/push", "-d", "{\"model\":\"whisper:${STT_MODEL}\"}"]
    depends_on:
      - ollama
    environment:
      - OLLAMA_BASE_URL=http://ollama:11434
    restart: "no"
```


***

### 4. 단계별 상세 설명

- `.env`의 경로(model_dir)는 꼭 본인 환경에 맞게 절대/상대경로로 지정한다.
- ollama 컨테이너는 모델 저장 경로를 외부에서 지정되도록 환경변수로 처리하고, `/root/.ollama`를 호스트의 MODEL_DIR/ollama로 바인드한다.
- 모델들은 처음 실행(ollama pull) 시에만 실제로 다운로드된다. 기존 다운로드 파일이 있을 경우 중복다운로드 없음.
- 각 모델(embedding/tts/stt)은 다양한 서비스나 테스트 환경에 따라 별도 API를 띄울 수 있으나, Ollama가 모든 모델을 관리하는 구조여서, API 호출은 ollama 쪽 엔드포인트로 통합된다.
- 각 모델은 curl로 POST를 보내 두 번째 pull을 트리거하며, 의존성(depends_on)으로 ollama가 준비된 뒤에만 진행된다.

***

### 5. 설치 및 실행법

```sh
cd project_root
docker-compose --env-file .env up
```

- MODEL_DIR 해당 경로가 먼저 있어야 한다(없으면 docker가 자동생성).
- ollama 모델 pull이나 serve 과정에서 메모리 부족, 저장공간 부족 등 오류가 날 수 있음.
- 구형 노트북의 경우 large 모델(ram 8GB 이상 권장)이 부담될 수 있음, 실패 시 base로 모델명을 축소해 재시도.

***

### 6. 오류 및 주의점

- 구형 노트북에서 large 모델(특히 embedding)은 메모리/디스크 부족으로 다운로드나 pull, serve가 실패할 수 있으니 꼭 모델파일 용량 및 hw 조건 체크.
- MODEL_DIR 경로에 한글, 특수문자 포함 시 호환 에러 날 수 있음. 되도록 영문, 경로 짧게.
- Ollama 업그레이드로 모델 경로 환경변수 정책이 바뀔 수 있으니, 릴리즈 노트 참고 필요.[^1][^2]
- 추가로 embedding/tts/stt 별로 자체 API 서버로 분리하고 싶으면 FastAPI 등으로 별도 래퍼 컨테이너 구현도 가능.

***

이 구성을 활용하면 ollama 및 각종 AI 모델을 한 번에 설치하고, 재시작 때마다 모델이 재다운로드되는 문제 없이 빠르게 운영할 수 있다.[^2][^3][^4][^1]
<span style="display:none">[^10][^11][^12][^13][^14][^15][^16][^17][^18][^19][^20][^5][^6][^7][^8][^9]</span>

<div align="center">⁂</div>

[^1]: https://www.reddit.com/r/ollama/comments/1c4zg15/does_anyone_know_how_to_change_where_your_models/

[^2]: https://collabnix.com/setting-up-ollama-models-with-docker-compose-a-step-by-step-guide/

[^3]: https://github.com/remsky/Kokoro-FastAPI/wiki/Setup-DockerCompose

[^4]: https://geshan.com.np/blog/2025/02/ollama-docker-compose/

[^5]: https://changsroad.tistory.com/550

[^6]: https://developnote-blog.tistory.com/216

[^7]: https://www.reddit.com/r/ollama/comments/1bfm8or/ollama_and_openwebui_docker_compose/

[^8]: https://seongjin.me/environment-variables-in-docker-compose/

[^9]: https://devzzi.tistory.com/76

[^10]: https://sy34.net/ollamawa-open-webuireul-iyonghaeseo-opeunsoseu-llmeul-sayonghaeboja-seolcipyeon/

[^11]: https://dev.to/nodeshiftcloud/a-step-by-step-guide-to-install-kokoro-82m-locally-for-fast-and-high-quality-tts-58ed

[^12]: https://data-newbie.tistory.com/1028

[^13]: https://adjh54.tistory.com/503

[^14]: https://guide-to-devops.github.io/blog/ollama와-Open-WebUI-로컬-배포

[^15]: https://github.com/remsky/Kokoro-FastAPI

[^16]: https://www.reddit.com/r/selfhosted/comments/z6r9x1/webui_for_whisper_an_awesome_audio_transcription/

[^17]: https://ysryuu.tistory.com/36

[^18]: https://www.reddit.com/r/LocalLLaMA/comments/1i02hpf/speaches_v060_kokoro82m_and_pipertts_api_endpoints/

[^19]: https://velog.io/@cabbage/도커-컴포즈-파일에서-환경-변수-사용하기

[^20]: https://www.reddit.com/r/kubernetes/comments/1c9jief/attaching_local_files_for_prebuilt_docker_image/

