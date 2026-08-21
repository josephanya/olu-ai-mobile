# Olu AI

Olu AI is an offline-first mobile assistant for Community Health Workers (CHWs). It records patient encounters, transcribes speech, gives live clinical guidance during the visit, and prepares post-visit documentation with a local medical LLM.

The current direction is the Sahara v2 integration for the CodeSwitch Africa Challenge: Sahara improves online transcription quality for African code-switched speech, while Olu AI keeps clinical reasoning local and available offline.

## Core Architecture

Sahara is used only as an ASR engine. It does not generate clinical guidance, SOAP notes, diagnoses, suggestions, or other clinical output.

Clinical guidance and documentation always come from the local Llama 3 medical model. The LLM consumes a plain transcript, regardless of whether that transcript came from Sahara streaming ASR or local Sherpa-ONNX.

```text
Audio captured from phone mic
   |
   v
Connectivity available?
   |
   +-- Online  -> Sahara v2 streaming ASR
   |
   +-- Offline -> Sherpa-ONNX local ASR
   |
   v
Unified transcript stream
   |
   v
Local Llama 3 medical model
   |
   +-- Live guidance during encounter
   +-- Post-visit SOAP-style documentation
```

For offline encounters, Olu AI can later upload the stored audio to Sahara for benchmark-only re-transcription. That benchmark transcript is stored beside the clinical transcript and must not update the CHW-facing note, guidance, or care workflow.

## What Works Offline

- Encounter recording
- Local Sherpa-ONNX transcription
- Live clinical guidance
- Post-visit analysis and documentation
- Patient and visit storage
- Bluetooth earpiece whisper mode for private CHW guidance

## What Improves Online

- Real-time Sahara v2 code-switching transcription when an API key is configured
- Automatic fallback to local Sherpa-ONNX if Sahara cannot start or fails during an encounter
- Background benchmark upload for offline encounters once connectivity returns

## Consent and Data Use

Read [CONSENT.md](CONSENT.md) before recording patient encounters or enabling Sahara cloud transcription.

The consent model separates three uses:

- Online transcription for care: patient audio may be streamed to Intron Sahara for transcription.
- Offline transcription for care: transcription used for care stays on-device.
- Benchmark/research upload: offline-recorded audio may later be uploaded to Sahara only for ASR evaluation, not for changing clinical output.

Do not treat benchmark consent as implied by care transcription consent.

## Sahara Integration

The app uses two Sahara surfaces:

| Surface | Role |
|---|---|
| Streaming STT WebSocket | Online real-time encounter transcription |
| File Upload REST API | Benchmark-only re-transcription of offline recordings |

Supported ASR source values stored with visits:

- `sahara_streaming`
- `sherpa_local`
- `mixed`

Benchmark transcriptions are stored with source `sahara_v2_benchmark` and `usedForClinicalPipeline = false`.

## Benchmark Export

Phase 5 adds a pure Dart benchmark runner at [tool/benchmark_runner.dart](tool/benchmark_runner.dart). It exports ASR comparison rows for clips with hand-transcribed references.

```sh
dart run tool/benchmark_runner.dart \
  --database /path/to/db.sqlite \
  --clips benchmark/clips.json \
  --out benchmark/results \
  --openai-api-key "$OPENAI_API_KEY"
```

The runner can compare:

- local Sherpa-ONNX;
- Sahara v2 benchmark transcripts;
- a third baseline, currently OpenAI Whisper API or precomputed Whisper transcripts.

Outputs:

- `asr_benchmark.csv`
- `asr_benchmark.json`

Each row includes clip id, model, WER, latency, language pair, accent/region, noise level, device, capture mode, reference transcript, and hypothesis transcript. WER uses `(substitutions + insertions + deletions) / reference word count`.

## Secrets

Copy [.env.example](.env.example) to `.env` for local development and never commit real keys.

The Flutter app currently reads Sahara credentials with a compile-time define:

```sh
flutter run --dart-define=SAHARA_API_KEY=your_sahara_key
```

The benchmark runner also reads these environment variables:

- `SAHARA_API_KEY`
- `OPENAI_API_KEY`

## Setup

Install dependencies:

```sh
flutter pub get
```

Generate Drift database code after schema changes:

```sh
dart run build_runner build --delete-conflicting-outputs
```

Run the app:

```sh
flutter run --dart-define=SAHARA_API_KEY=your_sahara_key
```

Run tests:

```sh
flutter test
```

Run analyzer:

```sh
flutter analyze
```

## Model Management

Olu AI uses a hybrid model strategy to balance developer convenience with production app size.

### Local Development

For development, you can bundle models with the app to avoid slow first-run downloads.

1. Download the Sherpa and LLM models listed below.
2. Keep the model directories enabled in the `pubspec.yaml` assets section.
3. On first run, the app copies bundled model files into persistent app storage.

### Production Release

For production, keep the initial app bundle smaller by downloading models on demand.

1. Remove or comment out the model asset lines in `pubspec.yaml`.
2. Let the setup flow download required models on first run.

## Sherpa Model Setup

Sherpa-ONNX provides local, offline streaming transcription.

1. Create `models/sherpa` in the project root.
2. Download these files from [Hugging Face](https://huggingface.co/csukuangfj/sherpa-onnx-streaming-zipformer-en-2023-06-26/tree/main):
   - `encoder-epoch-99-avg-1-chunk-16-left-64.int8.onnx`
   - `decoder-epoch-99-avg-1-chunk-16-left-64.int8.onnx`
   - `joiner-epoch-99-avg-1-chunk-16-left-64.int8.onnx`
   - `tokens.txt`
3. Place the files inside `models/sherpa`.

## LLM Model Setup

The app uses a Llama 3 3B medical model for local visit analysis and real-time guidance.

1. Create `models/llm` in the project root.
2. Download `LLAMA3-3B-Medical-COT.Q4_K_M.gguf` from [Hugging Face](https://huggingface.co/alpha-ai/LLAMA3-3B-Medical-COT-GGUF/resolve/main/LLAMA3-3B-Medical-COT.Q4_K_M.gguf).
3. Rename it to `medical_llama.gguf` and place it inside `models/llm`.

## Key Project Files

- [docs/SAHARA_INTEGRATION.md](docs/SAHARA_INTEGRATION.md): architecture and implementation spec
- [CONSENT.md](CONSENT.md): patient consent and benchmark ethics notice
- [tool/benchmark_runner.dart](tool/benchmark_runner.dart): ASR benchmark exporter
- [lib/services/sahara_streaming_client.dart](lib/services/sahara_streaming_client.dart): Sahara streaming client
- [lib/services/asr_router.dart](lib/services/asr_router.dart): ASR source routing and fallback
- [lib/services/benchmark_sync_worker.dart](lib/services/benchmark_sync_worker.dart): background Sahara benchmark upload worker
