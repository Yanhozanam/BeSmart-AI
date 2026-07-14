import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../config/model_config.dart';
import 'device_info.dart';
import 'llm_service.dart';

enum ModelStatus { unavailable, downloading, ready, error }

class ModelInfo {
  final ModelStatus status;
  final String displayName;
  final double progress;
  final String? errorMessage;
  final ModelTier tier;

  const ModelInfo({
    this.status = ModelStatus.unavailable,
    this.displayName = '',
    this.progress = 0.0,
    this.errorMessage,
    this.tier = ModelTier.standard,
  });

  bool get isReady => status == ModelStatus.ready;

  ModelInfo copyWith({
    ModelStatus? status,
    String? displayName,
    double? progress,
    String? errorMessage,
    ModelTier? tier,
  }) {
    return ModelInfo(
      status: status ?? this.status,
      displayName: displayName ?? this.displayName,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      tier: tier ?? this.tier,
    );
  }
}

class ModelManager {
  static final ModelManager _instance = ModelManager._internal();
  factory ModelManager() => _instance;
  ModelManager._internal();

  final StreamController<ModelInfo> _statusController =
      StreamController<ModelInfo>.broadcast();

  LLMService _service = MockLLMService();
  ModelInfo _info = const ModelInfo();
  String _modelDirPath = '';
  bool _downloadCanceled = false;
  ModelTier? _loadedTier;

  Stream<ModelInfo> get statusStream => _statusController.stream;
  ModelInfo get info => _info;
  bool get isReady => _info.isReady;

  String get _appModelPath => '$_modelDirPath/${ModelConfig.fileNameForTier(_info.tier)}';
  String get _partialModelPath => '$_modelDirPath/${ModelConfig.fileNameForTier(_info.tier)}.part';

  Future<void> initialize({ModelTier tier = ModelTier.standard}) async {
    _modelDirPath = await ModelConfig.modelDirectory;
    _info = _info.copyWith(tier: tier);

    debugPrint('[ModelManager] Model path: $_appModelPath');
    final modelFile = File(_appModelPath);
    debugPrint('[ModelManager] File exists: ${await modelFile.exists()}');
    if (await modelFile.exists()) {
      debugPrint('[ModelManager] File size: ${await modelFile.length()} bytes');
      debugPrint('[ModelManager] Expected size: ${ModelConfig.expectedSizeBytesForTier(tier)} bytes');
    } else {
      debugPrint('[ModelManager] Model file not found at $_appModelPath');
    }

    if (await _verifyModel(tier)) {
      try {
        await _loadModel(tier: tier);
        _loadedTier = tier;
      } catch (e) {
        debugPrint('[ModelManager] Model load failed during init: $e');
      }
    } else if (await _verifyModel(ModelTier.lite)) {
      try {
        await _loadModel(tier: ModelTier.lite);
        _loadedTier = ModelTier.lite;
      } catch (e) {
        debugPrint('[ModelManager] Lite model load failed during init: $e');
      }
    } else {
      _updateStatus(ModelInfo(
        status: ModelStatus.unavailable,
        tier: tier,
      ));
    }
  }

  Future<bool> _verifyModel(ModelTier tier) async {
    final modelPath = await ModelConfig.modelPathForTier(tier);
    final modelFile = File(modelPath);
    if (!await modelFile.exists()) return false;
    try {
      final size = await modelFile.length();
      return size >= ModelConfig.expectedSizeBytesForTier(tier) - 1024;
    } catch (_) {
      return false;
    }
  }

  Future<void> downloadModel({
    void Function(double progress, int received, int total)? onProgress,
    ModelTier tier = ModelTier.standard,
  }) async {
    _downloadCanceled = false;
    _info = _info.copyWith(tier: tier);
    _updateStatus(ModelInfo(
      status: ModelStatus.downloading,
      displayName: ModelConfig.modelNameForTier(tier),
      progress: 0.0,
      tier: tier,
    ));

    try {
      final modelPath = await ModelConfig.modelPathForTier(tier);
      final modelFile = File(modelPath);
      if (await modelFile.exists()) {
        final size = await modelFile.length();
        if (size >= ModelConfig.expectedSizeBytesForTier(tier) - 1024) {
          await _loadModel(tier: tier);
          return;
        }
        await modelFile.delete();
      }

      final partialPath = modelPath + '.part';
      final partialFile = File(partialPath);
      int startByte = 0;
      if (await partialFile.exists()) {
        startByte = await partialFile.length();
        if (startByte >= ModelConfig.expectedSizeBytesForTier(tier) - 1024) {
          await partialFile.rename(modelFile.path);
          await _loadModel(tier: tier);
          return;
        }
      }

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 30);
      final request = await client.getUrl(
        Uri.parse(ModelConfig.downloadUrlForTier(tier)),
      );
      if (startByte > 0) {
        request.headers.set('Range', 'bytes=$startByte-');
      }
      final response = await request.close();

      if (response.statusCode == 200 || response.statusCode == 206) {
        final headerLength = response.headers.value('content-length');
        final int totalBytes = headerLength != null
            ? startByte + int.parse(headerLength)
            : ModelConfig.expectedSizeBytesForTier(tier);
        int receivedBytes = startByte;

        final sink = partialFile.openWrite(
          mode: startByte > 0 ? FileMode.append : FileMode.write,
        );

        try {
          await for (final chunk in response) {
            if (_downloadCanceled) {
              await sink.close();
              return;
            }
            sink.add(chunk);
            receivedBytes += chunk.length;
            final progress = (receivedBytes / totalBytes).clamp(0.0, 1.0);
            _updateStatus(ModelInfo(
              status: ModelStatus.downloading,
              displayName: ModelConfig.modelNameForTier(tier),
              progress: progress,
              tier: tier,
            ));
            onProgress?.call(progress, receivedBytes, totalBytes);
          }
        } finally {
          await sink.close();
        }

        if (!_downloadCanceled) {
          if (receivedBytes >= totalBytes - 1024) {
            final fileSize = await partialFile.length();
            debugPrint('[ModelManager] Downloaded file size: $fileSize bytes');
            debugPrint('[ModelManager] Expected size: ${ModelConfig.expectedSizeBytesForTier(tier)} bytes');
            if (fileSize < 1000000) {
              throw Exception('Downloaded file is too small - download may have failed');
            }
            await partialFile.rename(modelFile.path);
            await _loadModel(tier: tier);
          } else {
            throw Exception(
              'Download incomplete: $receivedBytes of $totalBytes bytes',
            );
          }
        }
      } else {
        throw Exception('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      _updateStatus(ModelInfo(
        status: ModelStatus.error,
        displayName: ModelConfig.modelNameForTier(tier),
        progress: 0.0,
        errorMessage: e.toString(),
        tier: tier,
      ));
      rethrow;
    }
  }

  void cancelDownload() {
    _downloadCanceled = true;
  }

  Future<void> _loadModel({ModelTier tier = ModelTier.standard, int? contextSize}) async {
    try {
      final modelPath = await ModelConfig.modelPathForTier(tier);
      debugPrint('[ModelManager] Attempting to load model from: $modelPath');
      final file = File(modelPath);
      debugPrint('[ModelManager] File exists: ${await file.exists()}');
      if (await file.exists()) {
        debugPrint('[ModelManager] File size: ${await file.length()} bytes');
      }

      final deviceInfo = await DeviceInfo.detect();
      debugPrint('[ModelManager] Device RAM: ${deviceInfo.ramMB}MB, Free storage: ${deviceInfo.freeStorageMB}MB');

      final real = RealLLMService(
        modelPath: modelPath,
        contextSize: contextSize ?? ModelConfig.contextSizeForTier(tier),
        tier: tier,
      );
      await real.initialize();
      _service.dispose();
      _service = real;
      _loadedTier = tier;

      debugPrint('[ModelManager] Model loaded successfully');
      _updateStatus(ModelInfo(
        status: ModelStatus.ready,
        displayName: ModelConfig.modelNameForTier(tier),
        progress: 1.0,
        tier: tier,
      ));
    } catch (e) {
      _service.dispose();
      _service = MockLLMService();

      if (contextSize == null && ModelConfig.contextSizeForTier(tier) > 512) {
        debugPrint('[ModelManager] Failed with contextSize=${ModelConfig.contextSizeForTier(tier)}, retrying with 512...');
        try {
          await _loadModel(tier: tier, contextSize: 512);
          return;
        } catch (_) {
        }
      }

      debugPrint('[ModelManager] Failed to load model: $e');
      debugPrint('[ModelManager] Stack trace: ${StackTrace.current}');
      _updateStatus(ModelInfo(
        status: ModelStatus.error,
        displayName: ModelConfig.modelNameForTier(tier),
        errorMessage: e.toString(),
        tier: tier,
      ));
      rethrow;
    }
  }

  Future<String> generateResponse(String input) async {
    return _service.generateResponse(input);
  }

  Stream<String> generateStream(String prompt) {
    return _service.generateStream(prompt);
  }

  Future<bool> reloadModel({ModelTier tier = ModelTier.standard}) async {
    _service.dispose();
    _service = MockLLMService();
    if (await _verifyModel(tier)) {
      try {
        await _loadModel(tier: tier);
        return true;
      } catch (e) {
        debugPrint('[ModelManager] Model reload failed: $e');
      }
    } else {
      _updateStatus(ModelInfo(
        status: ModelStatus.unavailable,
        tier: tier,
      ));
    }
    return _info.isReady;
  }

  Future<void> deleteModel(ModelTier tier) async {
    _service.dispose();
    _service = MockLLMService();

    try {
      final modelPath = await ModelConfig.modelPathForTier(tier);
      final file = File(modelPath);
      if (await file.exists()) {
        await file.delete();
      }
      final partialPath = modelPath + '.part';
      final partial = File(partialPath);
      if (await partial.exists()) {
        await partial.delete();
      }
    } catch (e) {
      debugPrint('[ModelManager] Error deleting model: $e');
    }

    if (_loadedTier == tier) {
      _loadedTier = null;
      _updateStatus(ModelInfo(
        status: ModelStatus.unavailable,
        tier: tier,
      ));
    }
  }

  Future<void> cleanup() async {
    try {
      final dir = Directory(_modelDirPath);
      if (await dir.exists()) {
        await for (final entity in dir.list()) {
          if (entity is File) {
            final name = entity.uri.pathSegments.last;
            if (name.endsWith('.part')) {
              await entity.delete();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[ModelManager] Cleanup error: $e');
    }
  }

  void _updateStatus(ModelInfo info) {
    _info = info;
    if (!_statusController.isClosed) {
      _statusController.add(info);
    }
  }

  void dispose() {
    _service.dispose();
    _statusController.close();
  }
}