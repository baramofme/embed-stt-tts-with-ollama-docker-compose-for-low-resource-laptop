FROM python:3.10-slim
WORKDIR /app
RUN apt-get update && apt-get install -y ffmpeg
RUN pip install --upgrade pip
RUN pip install openai-whisper
COPY . /app
CMD ["python", "main.py"]
