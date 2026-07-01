import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../config/model_config.dart';
import 'device_info.dart';
import 'llm_service.dart';

enum ModelStatus { unavailable, downloading, ready, error }

class ModelInfo {
  final ModelStatus status;
  final String displayName;
  final double progress;
  final String? errorMessage;

  const ModelInfo({
    this.status = ModelStatus.unavailable,
    this.displayName = '',
    this.progress = 0.0,
    this.errorMessage,
  });

  bool get isReady => status == ModelStatus.ready;
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

  Stream<ModelInfo> get statusStream => _statusController.stream;
  ModelInfo get info => _info;
  bool get isReady => _info.isReady;

  String get _appModelPath =>
      '$_modelDirPath/${ModelConfig.fileName}';
  String get _partialModelPath =>
      '$_modelDirPath/${ModelConfig.fileName}.part';

  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    _modelDirPath = dir.path;

    debugPrint('[ModelManager] Model path: $_appModelPath');
    final modelFile = File(_appModelPath);
    debugPrint('[ModelManager] File exists: ${await modelFile.exists()}');
    if (await modelFile.exists()) {
      debugPrint('[ModelManager] File size: ${await modelFile.length()} bytes');
      debugPrint('[ModelManager] Expected size: ${ModelConfig.expectedSizeBytes} bytes');
    } else {
      debugPrint('[ModelManager] Model file not found at $_appModelPath');
    }

    if (await _verifyModel()) {
      try {
        await _loadModel();
      } catch (e) {
        debugPrint('[ModelManager] Model load failed during init: $e');
      }
    } else {
      _updateStatus(const ModelInfo(
        status: ModelStatus.unavailable,
      ));
    }
  }

  Future<bool> _verifyModel() async {
    final modelFile = File(_appModelPath);
    if (!await modelFile.exists()) return false;
    try {
      final size = await modelFile.length();
      return size >= ModelConfig.expectedSizeBytes - 1024;
    } catch (_) {
      return false;
    }
  }

  Future<void> downloadModel({
    void Function(double progress, int received, int total)? onProgress,
  }) async {
    _downloadCanceled = false;
    _updateStatus(const ModelInfo(
      status: ModelStatus.downloading,
      displayName: ModelConfig.modelName,
      progress: 0.0,
    ));

    try {
      final modelFile = File(_appModelPath);
      if (await modelFile.exists()) {
        final size = await modelFile.length();
        if (size >= ModelConfig.expectedSizeBytes - 1024) {
          await _loadModel();
          return;
        }
        await modelFile.delete();
      }

      final partialFile = File(_partialModelPath);
      int startByte = 0;
      if (await partialFile.exists()) {
        startByte = await partialFile.length();
        if (startByte >= ModelConfig.expectedSizeBytes - 1024) {
          await partialFile.rename(modelFile.path);
          await _loadModel();
          return;
        }
      }

      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 30);
      final request = await client.getUrl(
        Uri.parse(ModelConfig.downloadUrl),
      );
      if (startByte > 0) {
        request.headers.set('Range', 'bytes=$startByte-');
      }
      final response = await request.close();

      if (response.statusCode == 200 || response.statusCode == 206) {
        final headerLength = response.headers.value('content-length');
        final int totalBytes = headerLength != null
            ? startByte + int.parse(headerLength)
            : ModelConfig.expectedSizeBytes;
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
              displayName: ModelConfig.modelName,
              progress: progress,
            ));
            onProgress?.call(progress, receivedBytes, totalBytes);
          }
        } finally {
          await sink.close();
        }

        if (!_downloadCanceled) {
          if (receivedBytes >= totalBytes - 1024) {
            await partialFile.rename(modelFile.path);
            await _loadModel();
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
        displayName: ModelConfig.modelName,
        progress: 0.0,
        errorMessage: e.toString(),
      ));
      rethrow;
    }
  }

  void cancelDownload() {
    _downloadCanceled = true;
  }

  Future<void> _loadModel() async {
    try {
      debugPrint('[ModelManager] Attempting to load model from: $_appModelPath');
      final file = File(_appModelPath);
      debugPrint('[ModelManager] File exists: ${await file.exists()}');
      if (await file.exists()) {
        debugPrint('[ModelManager] File size: ${await file.length()} bytes');
      }

      final deviceInfo = await DeviceInfo.detect();
      debugPrint('[ModelManager] Device RAM: ${deviceInfo.ramMB}MB, Free storage: ${deviceInfo.freeStorageMB}MB');

      final real = RealLLMService(
        modelPath: _appModelPath,
      );
      await real.initialize();
      _service.dispose();
      _service = real;

      debugPrint('[ModelManager] Model loaded successfully');
      _updateStatus(const ModelInfo(
        status: ModelStatus.ready,
        displayName: ModelConfig.modelName,
        progress: 1.0,
      ));
    } catch (e) {
      _service.dispose();
      _service = MockLLMService();
      debugPrint('[ModelManager] Failed to load model: $e');
      debugPrint('[ModelManager] Stack trace: ${StackTrace.current}');
      _updateStatus(ModelInfo(
        status: ModelStatus.error,
        displayName: ModelConfig.modelName,
        errorMessage: e.toString(),
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

  Future<bool> reloadModel() async {
    _service.dispose();
    _service = MockLLMService();
    if (await _verifyModel()) {
      try {
        await _loadModel();
      } catch (e) {
        debugPrint('[ModelManager] Model reload failed: $e');
      }
    } else {
      _updateStatus(const ModelInfo(
        status: ModelStatus.unavailable,
      ));
    }
    return _info.isReady;
  }

  Future<void> deleteModel() async {
    _service.dispose();
    _service = MockLLMService();

    try {
      final file = File(_appModelPath);
      if (await file.exists()) {
        await file.delete();
      }
      final partial = File(_partialModelPath);
      if (await partial.exists()) {
        await partial.delete();
      }
    } catch (e) {
      debugPrint('[ModelManager] Error deleting model: $e');
    }

    _updateStatus(const ModelInfo(
      status: ModelStatus.unavailable,
    ));
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
