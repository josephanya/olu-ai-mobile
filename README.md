# Olu AI App

Olu AI is an open-source, offline-first mobile application that allows Community Health Workers (CHWs) to record and analyze patient encounters using AI. Unlike traditional transcription tools, Olu AI **actively listens** during the encounter, providing a real-time transcript and **AI-powered guidance** to help CHWs identify red flags and ask the right questions in the moment.

### Model Management Strategy

Olu AI uses a hybrid strategy to balance developer convenience with production app size.

#### 🛠️ Local Development (Emulators/Mobile)
To avoid high data usage and slow downloads during development, you should bundle the models with your app.
1.  **Download**: Follow the Sherpa and LLM instructions below to download the models manually.
2.  **Enable Assets**: Ensure the model directories are uncommented in your `pubspec.yaml` assets section.
3.  **Run**: On the first run, the app will copy these files from the assets to the phone's persistent storage.

#### 🚀 Production Release
To keep the initial app bundle small (standard size), you should download models on-demand.
1.  **Disable Assets**: Comment out or remove the model lines in `pubspec.yaml`.
2.  **On-First-Run**: When the user opens the app for the first time, it will automatically download the required models (~850MB total) from HuggingFace.

---

### Sherpa Model Setup (Local Reference)

The application uses Sherpa-ONNX with a streaming Zipformer model for real-time, offline transcription.

1. Create a folder: `models/sherpa` in the root of the project.
2. Download the following files from [Hugging Face](https://huggingface.co/csukuangfj/sherpa-onnx-streaming-zipformer-en-2023-06-26/tree/main):
   - `encoder-epoch-99-avg-1.int8.onnx`
   - `decoder-epoch-99-avg-1.onnx`
   - `joiner-epoch-99-avg-1.onnx`
   - `tokens.txt`
3. Place these files inside the `models/sherpa` folder.

### LLM Model Setup (Optional for Local Dev)

The application uses a specialized Llama 3 3B Medical model for offline visit analysis and real-time guidance.

1. Create a folder: `models/llm` in the root of the project.
2. Download `LLAMA3-3B-Medical-COT.Q4_K_M.gguf` from [Hugging Face](https://huggingface.co/alpha-ai/LLAMA3-3B-Medical-COT-GGUF/resolve/main/LLAMA3-3B-Medical-COT.Q4_K_M.gguf).
3. Rename the file to `medical_llama.gguf` and place it inside the `models/llm` folder.
