# Consent and Ethics Notice

Olu AI is an offline-first clinical assistant for Community Health Workers (CHWs). It records patient encounters, transcribes speech, and uses an on-device medical LLM to generate clinical guidance and visit documentation.

This notice separates three different data uses that must be explained clearly before recording begins.

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

## 3. Benchmark and Research Uploads

Offline-recorded audio may later be uploaded to Sahara for benchmarking or research evaluation when connectivity returns. This upload is separate from the transcript used for the patient's care.

Benchmark uploads are used to compare ASR model quality, such as Sahara v2, local Sherpa-ONNX, and a third baseline model. They must not update the patient's existing SOAP note, live guidance, or other CHW-facing clinical content.

This is a distinct consent point. Patients should be asked separately whether their offline-recorded audio may later be uploaded for benchmarking or research purposes.

## Operational Requirements

- Do not record a patient encounter until consent has been obtained under the workflow being used.
- Do not treat benchmark or research consent as implied by consent for clinical transcription.
- Do not include patient identifiers in benchmark exports unless the evaluation protocol explicitly requires it and the patient has consented.
- Keep API keys and service credentials out of source control. Use local environment variables or platform secure storage.
- Review Intron's current terms and privacy documentation before deployment. The public policy pages could not be reliably extracted during this implementation, so this project does not make claims about Sahara retention periods, access controls, deletion timelines, or training use.

## Suggested CHW Script

Online care mode:

> I would like to record this visit so Olu AI can transcribe it and help prepare your visit notes. Because we are online, your audio may be sent to Intron's Sahara cloud service for transcription. Is that okay?

Offline care mode:

> I would like to record this visit so Olu AI can transcribe it on this device and help prepare your visit notes. Is that okay?

Benchmark upload:

> If this visit is recorded offline, we may later upload the audio to Sahara only to compare transcription accuracy for research and benchmarking. This will not change your care note. Is that okay?