# Olu AI App

Olu AI is an open-source, offline-first mobile application that allows Community Health Workers (CHWs) to record and analyze patient encounters using AI. Unlike traditional transcription tools, Olu AI **actively listens** during the encounter, providing a real-time transcript and **AI-powered guidance** to help CHWs identify red flags and ask the right questions in the moment.

### Sherpa Model Setup (Local Reference)

The application uses Sherpa-ONNX with a streaming Zipformer model for real-time, offline transcription. To keep the repository size small, the large model files are excluded from version control.

> [!NOTE]
> **Mobile Emulators:** Since emulators are isolated from your computer's files, they will always download the models (~50MB) on the first run. The instructions below are for reference or if you run the app on a platform with direct filesystem access.

1. Create a folder: `models/sherpa` in the root of the project.
2. Download the following files from [Hugging Face](https://huggingface.co/csukuangfj/sherpa-onnx-streaming-zipformer-en-2023-06-26/tree/main):
   - `encoder-epoch-99-avg-1.int8.onnx`
   - `decoder-epoch-99-avg-1.onnx`
   - `joiner-epoch-99-avg-1.onnx`
   - `tokens.txt`
3. Place these files inside the `models/sherpa` folder.

### LLM Model Setup (Optional for Local Dev)

The application uses TinyLlama GGUF for offline visit analysis and real-time guidance.

1. Create a folder: `models/llm` in the root of the project.
2. Download `tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf` from [Hugging Face](https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf).
3. Rename the file to `tinyllama.gguf` and place it inside the `models/llm` folder.

> [!NOTE] 
> If these files are missing, the application will attempt to download them automatically on the first run (Total approx. 650MB).
