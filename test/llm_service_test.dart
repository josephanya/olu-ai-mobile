import 'package:flutter_test/flutter_test.dart';
import 'package:olu_ai/features/visits/application/llm_service.dart';

void main() {
  test('analyzeVisit returns analysis result', () async {
    final service = LlmService();
    final transcript = "Patient complains of headache and fever.";
    
    final analysis = await service.analyzeVisit(transcript);
    
    expect(analysis, contains('Subjective'));
    expect(analysis, contains('Objective'));
    expect(analysis, contains('Assessment'));
    expect(analysis, contains('Plan'));
  });
}
