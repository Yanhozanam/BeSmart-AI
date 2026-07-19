import 'package:path_provider/path_provider.dart';

enum ModelTier { lite, standard }

class ModelConfig {
  // LITE TIER - Qwen2.5-1.5B-Instruct-Q3_K_M
  static const String liteModelName = 'BeSmartAI Qwen2.5';
  static const String liteDownloadUrl =
      'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q3_k_m.gguf';
  static const String liteFileName = 'qwen2.5-1.5b-instruct-q3_k_m.gguf';
  static const int liteExpectedSizeBytes = 924455968;
  static const int liteContextSize = 256;
  static const int liteMaxTokens = 150;

  // STANDARD TIER - Gemma 2 2B IT Q4_K_M
  static const String stdModelName = 'BeSmartAI Gemma 2 2B';
  static const String stdDownloadUrl =
      'https://huggingface.co/bartowski/gemma-2-2b-it-GGUF/resolve/main/gemma-2-2b-it-Q4_K_M.gguf';
  static const String stdFileName = 'gemma-2-2b-it-Q4_K_M.gguf';
  static const int stdExpectedSizeBytes = 1600000000;
  static const int stdContextSize = 4096;
  static const int stdMaxTokens = 512;

  // SHARED
  static const int threads = 4;
  static const double temperature = 0.7;
  static const double topP = 0.95;
  static const String systemPrompt = 'You are BeSmartAI. Be brief and direct.';

  static String modelNameForTier(ModelTier tier) =>
      tier == ModelTier.lite ? liteModelName : stdModelName;
  static String downloadUrlForTier(ModelTier tier) =>
      tier == ModelTier.lite ? liteDownloadUrl : stdDownloadUrl;
  static String fileNameForTier(ModelTier tier) =>
      tier == ModelTier.lite ? liteFileName : stdFileName;
  static int expectedSizeBytesForTier(ModelTier tier) =>
      tier == ModelTier.lite ? liteExpectedSizeBytes : stdExpectedSizeBytes;
  static int contextSizeForTier(ModelTier tier) =>
      tier == ModelTier.lite ? liteContextSize : stdContextSize;
  static int maxTokensForTier(ModelTier tier) =>
      tier == ModelTier.lite ? liteMaxTokens : stdMaxTokens;

  static Future<String> get modelDirectory async {
    final docsDir = await getApplicationDocumentsDirectory();
    return docsDir.path;
  }

  static Future<String> modelPathForTier(ModelTier tier) async {
    final dir = await modelDirectory;
    return '$dir/${fileNameForTier(tier)}';
  }

  static Future<String> partialModelPathForTier(ModelTier tier) async {
    final dir = await modelDirectory;
    return '$dir/${fileNameForTier(tier)}.part';
  }
}