class ModelConfig {
  static const String modelName = 'BeSmartAI Qwen2.5';
  static const String version = '1.0.0';
  static const String downloadUrl =
      'https://huggingface.co/Qwen/Qwen2.5-1.5B-Instruct-GGUF/resolve/main/qwen2.5-1.5b-instruct-q4_k_m.gguf';
  static const String fileName = 'qwen2.5-1.5b-instruct-q4_k_m.gguf';
  static const String sha256 = '6a1a2eb6d15622bf3c96857206351ba97e1af16c30d7a74ee38970e434e9407e';
  static const int expectedSizeBytes = 1117320736;

  static const int recommendedThreads = 4;
  static const int contextSize = 2048;
  static const int maxTokens = 512;
  static const int nGpuLayers = -1;
  static const double temperature = 0.7;
  static const double topP = 0.95;
}