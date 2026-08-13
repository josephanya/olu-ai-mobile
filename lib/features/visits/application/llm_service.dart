import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:llama_cpp_dart/llama_cpp_dart.dart';
import 'package:path_provider/path_provider.dart';

class LlmService {
  LlamaParent? _llama;
  bool _isInitialized = false;
  Completer<String>? _currentCompleter;
  final StringBuffer _responseBuffer = StringBuffer();

  Future<void> initialize() async {
    if (_isInitialized) return;

    final modelPath = await _getModelPath();

    final loadCommand = LlamaLoad(
      path: modelPath,
      modelParams: ModelParams(),
      contextParams: ContextParams(),
      samplingParams: SamplerParams(),
    );

    _llama = LlamaParent(loadCommand);

    await _llama!.init();

    _llama!.stream.listen(
      (data) {
        final text = data.toString();
        _responseBuffer.write(text);
      },
      onError: (e) {
        if (_currentCompleter?.isCompleted == false) {
          _currentCompleter?.completeError(e);
        }
      },
    );

    _isInitialized = true;
  }

  Future<String> _getModelPath() async {
    // 1. Check for local project directory (Desktop/Local dev with direct access)
    const localModelPath = 'models/llm/medical_llama.gguf';
    if (await File(localModelPath).exists()) {
      return localModelPath;
    }

    // 2. Check for the model in the app's documents directory
    //    (downloaded by ModelManagerService during setup)
    final docDir = await getApplicationDocumentsDirectory();
    final persistentPath = '${docDir.path}/medical_llama.gguf';

    if (await File(persistentPath).exists()) {
      return persistentPath;
    }

    // 3. Try to copy from bundled assets (for emulator/mobile dev)
    try {
      final data = await rootBundle.load('models/llm/medical_llama.gguf');
      final bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(persistentPath).writeAsBytes(bytes);
      debugPrint('Copied medical_llama.gguf from assets');
      return persistentPath;
    } catch (_) {
      // Not bundled
    }

    throw Exception(
      'LLM model not found. Please run the setup process first.',
    );
  }

  Future<String> getLiveGuidance(String transcript) async {
    if (!_isInitialized) {
      await initialize();
    }

    // If already busy, just return the last guidance or skip this frame
    if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
      return "";
    }

    _currentCompleter = Completer<String>();
    _responseBuffer.clear();

    const systemPrompt = """
You are a clinical decision-support assistant helping a Community Health Worker (CHW) during a live patient visit in a resource-limited setting.

Analyze the transcript and respond in EXACTLY this format (one line each, no extra text):

DIFFERENTIAL: Top 2-3 likely conditions ranked by probability
NEXT STEPS: 1-2 immediate actions the CHW should take (exams, rapid tests, vitals)
GUIDANCE: One specific question the CHW should ask the patient next

Rules:
- Keep each line under 15 words.
- Prioritize conditions common in community health settings.
- Refine your differential based on ALL information in the transcript, not just the latest statement.
- If the transcript is too brief to assess, respond only with GUIDANCE suggesting what to ask first.
""";

    final prompt = "$systemPrompt\n\nTranscript:\n$transcript\n\nInsights:";
    _llama!.sendPrompt(prompt);

    // For live guidance, we wait less time
    return _waitForResponse(timeout: const Duration(milliseconds: 3500));
  }

  Future<String> analyzeVisit(String transcript) async {
    if (!_isInitialized) {
      await initialize();
    }

    if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
      throw Exception('LlmService is busy');
    }

    _currentCompleter = Completer<String>();
    _responseBuffer.clear();

    const systemPrompt = """
You are a clinical decision support assistant for Community Health Workers (CHWs).
Analyze the patient consultation transcript and provide a comprehensive clinical summary.

Generate the following sections:

## SOAP Notes
- **Subjective**: Chief complaint and symptoms reported by the patient
- **Objective**: Observable findings mentioned (vitals, physical exam if any)
- **Assessment**: Clinical impression based on the information
- **Plan**: Recommended next steps

## Differential Diagnosis
List the top 3 most likely conditions based on symptoms, ranked by probability:
1. [Most likely diagnosis] - Brief reasoning
2. [Second possibility] - Brief reasoning  
3. [Third possibility] - Brief reasoning

## Recommended Treatment
For the most likely diagnosis, suggest:
- **Immediate actions**: What the CHW can do now
- **Medications**: OTC or standard treatments (if applicable)
- **Home care**: Patient education and self-care instructions
- **Follow-up**: When to reassess

## Red Flags & Referral
⚠️ List any warning signs that require immediate referral to a healthcare facility.

Be concise but thorough. Do not include speculative information not present in the text.

Use simple language appropriate for community health settings.
""";

    final prompt = "$systemPrompt\n\nTranscript:\n$transcript\n\nAnalysis:";
    _llama!.sendPrompt(prompt);
    return _waitForResponse();
  }

  Future<String> _waitForResponse(
      {Duration timeout = const Duration(seconds: 1)}) async {
    int lastLength = 0;
    int stableCount = 0;
    final startTime = DateTime.now();

    while (true) {
      await Future.delayed(const Duration(milliseconds: 200));

      if (_responseBuffer.length == lastLength && lastLength > 0) {
        stableCount++;
        if (stableCount >= 2) {
          // 400ms of stability
          _currentCompleter?.complete(_responseBuffer.toString());
          break;
        }
      } else {
        stableCount = 0;
      }

      lastLength = _responseBuffer.length;

      if (DateTime.now().difference(startTime) > timeout * 10) {
        // Safety break
        _currentCompleter?.complete(_responseBuffer.toString());
        break;
      }

      if (_responseBuffer.length > 20000) {
        _currentCompleter?.complete(_responseBuffer.toString());
        break;
      }
    }
    return _currentCompleter!.future;
  }

  void dispose() {
    _llama?.dispose();
  }
}

final llmServiceProvider = Provider<LlmService>((ref) {
  final service = LlmService();
  ref.onDispose(() => service.dispose());
  return service;
});
