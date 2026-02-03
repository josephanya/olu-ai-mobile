import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
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
    const localModelPath = 'models/llm/tinyllama.gguf';
    if (await File(localModelPath).exists()) {
      return localModelPath;
    }
    return _downloadModelIfNeeded();
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
You are a clinical assistant for a Community Health Worker (CHW). 
The CHW is currently in a patient encounter.
Listen to the transcript and provide 1-2 VERY SHORT, ACTIONABLE suggestions for the CHW.
Suggestions should be about what to ask or check next.

Examples:
- "Ask about the duration of the cough."
- "Check if the child has a sunken fontanelle."
- "Ask if the patient has any known allergies."

Be extremely concise. Use at most 15 words.
""";

    final prompt = "$systemPrompt\n\nTranscript:\n$transcript\n\nSuggestion:";
    _llama!.sendPrompt(prompt);

    // For live guidance, we wait less time or until a newline/stop signal
    return _waitForResponse(timeout: const Duration(milliseconds: 3000));
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

  Future<String> _downloadModelIfNeeded() async {
    final docDir = await getApplicationDocumentsDirectory();
    final modelPath = '${docDir.path}/tinyllama.gguf';
    final file = File(modelPath);

    if (!await file.exists()) {
      const url =
          'https://huggingface.co/TheBloke/TinyLlama-1.1B-Chat-v1.0-GGUF/resolve/main/tinyllama-1.1b-chat-v1.0.Q4_K_M.gguf';

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        await file.writeAsBytes(response.bodyBytes);
      } else {
        throw Exception('Failed to download LLM model');
      }
    }
    return modelPath;
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
