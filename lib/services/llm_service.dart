import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:llamafu/llamafu.dart';
import 'package:path_provider/path_provider.dart';
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
  final int contextSize;
  Llamafu? _llamafu;

  RealLLMService({
    required this.modelPath,
    this.contextSize = ModelConfig.contextSize,
  });

  @override
  bool get isAvailable => _llamafu != null;

  @override
  Future<void> initialize() async {
    await _tryLoad(modelPath);
  }

  Future<void> _tryLoad(String path) async {
    final file = File(path);
    debugPrint('[RealLLMService] Loading model from: $path');
    debugPrint('[RealLLMService] File exists: ${await file.exists()}');
    if (await file.exists()) {
      debugPrint('[RealLLMService] File size: ${await file.length()} bytes');
    }

    // Log each _isValidFilePath check (mirrors llamafu's validation)
    debugPrint('[RealLLMService] Path validation checks:');
    debugPrint('  - contains null byte: ${path.contains('\x00')}');
    debugPrint('  - contains "..": ${path.contains('..')}');
    debugPrint('  - starts with /etc/: ${path.startsWith('/etc/')}');
    debugPrint('  - starts with /usr/: ${path.startsWith('/usr/')}');
    debugPrint('  - starts with /system/: ${path.startsWith('/system/')}');
    debugPrint('  - contains /proc/: ${path.contains('/proc/')}');
    debugPrint('  - contains /dev/: ${path.contains('/dev/')}');
    debugPrint('  - length > 4096: ${path.length > 4096}');
    debugPrint('  - path length: ${path.length}');

    try {
      _llamafu = await Llamafu.init(
        modelPath: path,
        threads: ModelConfig.recommendedThreads,
        contextSize: contextSize,
      );
    } catch (e) {
      debugPrint('[RealLLMService] Error loading from original path: $e');
      debugPrint('[RealLLMService] Error type: ${e.runtimeType}');

      if (e is ArgumentError) {
        debugPrint('[RealLLMService] Trying fallback path in temp directory...');
        try {
          await _tryLoadFromFallback(file);
          debugPrint('[RealLLMService] Model loaded successfully from fallback path');
          return;
        } catch (fallbackError) {
          debugPrint('[RealLLMService] Fallback also failed: $fallbackError');
          throw Exception(
            'Model path rejected and fallback failed: $fallbackError',
          );
        }
      }

      rethrow;
    }
  }

  Future<void> _tryLoadFromFallback(File originalFile) async {
    final tempDir = await getTemporaryDirectory();
    final fallbackPath = '${tempDir.path}/${ModelConfig.fileName}';
    final fallbackFile = File(fallbackPath);

    if (!await originalFile.exists()) {
      throw Exception('Original model file not found at ${originalFile.path}');
    }

    await fallbackFile.parent.create(recursive: true);
    await originalFile.copy(fallbackPath);
    debugPrint('[RealLLMService] Copied model to fallback path: $fallbackPath');
    debugPrint('[RealLLMService] Fallback file exists: ${await fallbackFile.exists()}');
    debugPrint('[RealLLMService] Fallback file size: ${await fallbackFile.length()} bytes');

    _llamafu = await Llamafu.init(
      modelPath: fallbackPath,
      threads: ModelConfig.recommendedThreads,
      contextSize: contextSize,
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
