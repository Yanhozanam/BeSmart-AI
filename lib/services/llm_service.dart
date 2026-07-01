import 'package:llamafu/llamafu.dart';
import '../config/model_config.dart';

abstract class LLMService {
  Future<String> generateResponse(String input);
  Stream<String> generateStream(String prompt);
  bool get isAvailable;
  Future<void> initialize();
  void dispose();
}

class MockLLMService implements LLMService {
  @override
  bool get isAvailable => true;

  @override
  Future<void> initialize() async {}

  @override
  void dispose() {}

  @override
  Future<String> generateResponse(String input) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return "That's a great question! As BeSmartAI, I'm here to help you with your studies. I can assist with explanations, summaries, and study tips. What subject are you working on?";
  }

  @override
  Stream<String> generateStream(String prompt) async* {
    final words = "That's a great question! As BeSmartAI, I'm here to help you with your studies. I can assist with explanations, summaries, and study tips. What subject are you working on?".split(' ');
    for (final word in words) {
      yield '$word ';
      await Future.delayed(const Duration(milliseconds: 60));
    }
  }
}

class RealLLMService implements LLMService {
  final String modelPath;
  Llamafu? _llamafu;

  RealLLMService({
    required this.modelPath,
  });

  @override
  bool get isAvailable => _llamafu != null;

  @override
  Future<void> initialize() async {
    _llamafu = await Llamafu.init(
      modelPath: modelPath,
      threads: ModelConfig.recommendedThreads,
      contextSize: ModelConfig.contextSize,
    );
  }

  @override
  Future<String> generateResponse(String prompt) async {
    if (_llamafu == null) throw Exception('Model not initialized');
    return await _llamafu!.complete(
      prompt: prompt,
      maxTokens: ModelConfig.maxTokens,
      temperature: ModelConfig.temperature,
    );
  }

  @override
  Stream<String> generateStream(String prompt) async* {
    if (_llamafu == null) throw Exception('Model not initialized');
    yield* _llamafu!.completeStream(
      prompt: prompt,
      maxTokens: ModelConfig.maxTokens,
      temperature: ModelConfig.temperature,
    );
  }

  @override
  void dispose() {
    _llamafu?.close();
  }
}
