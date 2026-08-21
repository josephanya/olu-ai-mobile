# Consent and Ethics Notice

Olu AI is an offline-first clinical assistant for Community Health Workers (CHWs). It records patient encounters, transcribes speech, and uses an on-device medical LLM to generate clinical guidance and visit documentation.

This notice separates clinical transcription from dedicated benchmark testing so patients are not asked to consent to research uploads of their encounter audio.

## 1. Online Transcription for Care

When the device has network connectivity and a Sahara API key is configured, Olu AI may stream patient encounter audio to Intron's Sahara v2 cloud API for real-time transcription.

This means patient speech may leave the device and be processed by a third-party cloud transcription service. The resulting transcript can be used by Olu AI's local clinical pipeline to support the CHW during the encounter and to prepare visit documentation.

Before using online transcription, the patient should be told:

- their voice may be sent to a third-party cloud API for transcription;
- the purpose is to support transcription during their care encounter;
- the CHW can use offline mode instead when connectivity is unavailable or cloud processing is not appropriate.

## 2. Offline Transcription for Care

When the device is offline, or when Sahara streaming is unavailable, Olu AI uses the local Sherpa-ONNX transcription model. In this mode, the transcription used for care is produced on the device.

Offline mode means the encounter can still be recorded and processed locally for clinical guidance and documentation. It does not require live cloud transcription for the patient's care workflow.

## 3. Benchmark and Research Testing

Olu AI benchmarks Sahara v2, local Sherpa-ONNX, and a third baseline model with dedicated scripted test clips. These clips are deliberately recorded for evaluation with known reference transcripts.

Patient encounter audio is not retained or uploaded for benchmark evaluation. Benchmark results must not update any patient's SOAP note, live guidance, or other CHW-facing clinical content.

If future research requires patient encounter audio, that workflow needs a separate protocol and consent process before it is enabled.

## Operational Requirements

- Do not record a patient encounter until consent has been obtained under the workflow being used.
- Do not use patient encounter audio in benchmark exports.
- Keep benchmark clips scripted and free of patient identifiers.
- Keep API keys and service credentials out of source control. Use local environment variables or platform secure storage.
- Review Intron's current terms and privacy documentation before deployment. The public policy pages could not be reliably extracted during this implementation, so this project does not make claims about Sahara retention periods, access controls, deletion timelines, or training use.

## Suggested CHW Script

Online care mode:

> I would like to record this visit so Olu AI can transcribe it and help prepare your visit notes. Because we are online, your audio may be sent to Intron's Sahara cloud service for transcription. Is that okay?

Offline care mode:

> I would like to record this visit so Olu AI can transcribe it on this device and help prepare your visit notes. Is that okay?