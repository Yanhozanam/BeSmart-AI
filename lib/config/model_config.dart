import 'package:path_provider/path_provider.dart';

class ModelConfig {
  static const String modelName = 'BeSmartAI Qwen2.5';
  static const String version = '1.0.0';
  static const String downloadUrl =
      'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q3_k_m.gguf';
  static const String fileName = 'qwen2.5-1.5b-instruct-q3_k_m.gguf';
  static const String sha256 = '';
  static const int expectedSizeBytes = 924455968;

  static const int threads = 4;
  static const int contextSize = 256;
  static const int maxTokens = 150;

  static const String systemPrompt =
      'You are BeSmartAI. Be brief and direct.';
  static const int nGpuLayers = -1;
  static const double temperature = 0.7;
  static const double topP = 0.95;

  static Future<String> get modelDirectory async {
    final docsDir = await getApplicationDocumentsDirectory();
    return docsDir.path;
  }

  static Future<String> get modelPath async {
    final dir = await modelDirectory;
    return '$dir/$fileName';
  }
}