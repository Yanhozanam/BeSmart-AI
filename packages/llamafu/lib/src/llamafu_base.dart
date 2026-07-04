import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'llamafu_bindings.dart' as bindings;

class Llamafu {
  late final bindings.LlamafuBindings _bind;
  late final Pointer<Void> _instance;

  Llamafu._(this._bind, this._instance);

  static const int maxPromptLength = 100000;
  static const int maxTokens = 8192;
  static const double minTemperature = 0.0;
  static const double maxTemperature = 2.0;

  static bool _isValidFilePath(String filePath) => true;

  static bool _isValidParameter(double value, double min, double max) =>
      value >= min && value <= max && value.isFinite;

  static bool _isValidPrompt(String prompt) {
    if (prompt.contains('\0')) return false;
    if (prompt.length > maxPromptLength) return false;
    for (int i = 0; i < prompt.length; i++) {
      final codeUnit = prompt.codeUnitAt(i);
      if (codeUnit < 32 && codeUnit != 9 && codeUnit != 10 && codeUnit != 13) {
        return false;
      }
    }
    return true;
  }

  static Future<Llamafu> init({
    required String modelPath,
    int threads = 4,
    int contextSize = 512,
  }) async {
    if (!_isValidFilePath(modelPath)) {
      throw ArgumentError('Invalid model path: $modelPath');
    }
    if (threads < 1 || threads > 64) {
      throw ArgumentError('Invalid thread count: $threads (must be 1-64)');
    }
    if (contextSize < 1 || contextSize > 32768) {
      throw ArgumentError('Invalid context size: $contextSize (must be 1-32768)');
    }

    final modelFile = File(modelPath);
    if (!await modelFile.exists()) {
      throw ArgumentError('Model file does not exist: $modelPath');
    }

    final b = await bindings.LlamafuBindings.init();

    final modelParams = malloc<bindings.LlamafuModelParams>();
    modelParams.ref.model_path = modelPath.toNativeUtf8();
    modelParams.ref.mmproj_path = nullptr;
    modelParams.ref.n_threads = threads;
    modelParams.ref.n_ctx = contextSize;
    modelParams.ref.use_gpu = 0;

    final outPtr = malloc<Pointer<Void>>();
    final result = b.llamafuInit(modelParams, outPtr);

    if (result != 0) {
      malloc.free(modelParams);
      malloc.free(outPtr);
      throw Exception('Failed to initialize Llamafu (error $result)');
    }

    return Llamafu._(b, outPtr.value);
  }

  Future<String> complete({
    required String prompt,
    int maxTokens = 128,
    double temperature = 0.8,
  }) async {
    if (!_isValidPrompt(prompt)) {
      throw ArgumentError('Invalid prompt');
    }
    if (maxTokens < 1 || maxTokens > Llamafu.maxTokens) {
      throw ArgumentError('Invalid maxTokens: $maxTokens');
    }
    if (!_isValidParameter(temperature, minTemperature, maxTemperature)) {
      throw ArgumentError('Invalid temperature: $temperature');
    }

    final params = malloc<bindings.LlamafuInferParams>();
    params.ref.prompt = prompt.toNativeUtf8();
    params.ref.max_tokens = maxTokens;
    params.ref.temperature = temperature;

    final outResult = malloc<Pointer<Utf8>>();
    final result = _bind.llamafuComplete(_instance, params, outResult);

    malloc.free(params.ref.prompt);
    malloc.free(params);

    if (result != 0) {
      malloc.free(outResult);
      throw Exception('Completion failed (error $result)');
    }

    final text = outResult.value.toDartString();
    _bind.llamafuFreeString(outResult.value);
    malloc.free(outResult);

    return text;
  }

  Stream<String> completeStream({
    required String prompt,
    int maxTokens = 128,
    double temperature = 0.8,
  }) {
    if (!_isValidPrompt(prompt)) {
      throw ArgumentError('Invalid prompt');
    }
    if (maxTokens < 1 || maxTokens > Llamafu.maxTokens) {
      throw ArgumentError('Invalid maxTokens: $maxTokens');
    }
    if (!_isValidParameter(temperature, minTemperature, maxTemperature)) {
      throw ArgumentError('Invalid temperature: $temperature');
    }

    final controller = StreamController<String>();
    _runStream(prompt, maxTokens, temperature, controller);
    return controller.stream;
  }

  void _runStream(
    String prompt,
    int maxTokens,
    double temperature,
    StreamController<String> controller,
  ) async {
    final params = malloc<bindings.LlamafuInferParams>();
    params.ref.prompt = prompt.toNativeUtf8();
    params.ref.max_tokens = maxTokens;
    params.ref.temperature = temperature;

    try {
      final result = _bind.llamafuCompleteStream(
        _instance, params, nullptr, nullptr);

      if (result != 0) {
        throw Exception('Stream start failed (error $result)');
      }

      final outToken = malloc<Pointer<Utf8>>();
      final outCompleted = malloc<Bool>();

      try {
        while (true) {
          outToken.value = nullptr;
          outCompleted.value = false;

          final pollResult = _bind.llamafuReadStreamToken(
            _instance, outToken, outCompleted);

          if (pollResult == 0 && outToken.value != nullptr) {
            final token = outToken.value.toDartString();
            _bind.llamafuFreeString(outToken.value);
            controller.add(token);
          }

          if (outCompleted.value) break;

          if (pollResult != 0) {
            await Future.delayed(const Duration(milliseconds: 10));
          }
        }
      } finally {
        malloc.free(outToken);
        malloc.free(outCompleted);
      }
    } catch (e) {
      controller.addError(e);
    } finally {
      malloc.free(params.ref.prompt);
      malloc.free(params);
      await controller.close();
    }
  }

  void close() {
    _bind.llamafuFree(_instance);
  }
}
