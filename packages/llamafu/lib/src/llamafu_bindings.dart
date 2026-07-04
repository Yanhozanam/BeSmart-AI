import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

typedef LlamafuError = Int32;

const int LLAMAFU_SUCCESS = 0;
const int LLAMAFU_ERROR_UNKNOWN = -1;
const int LLAMAFU_ERROR_INVALID_PARAM = -2;

final class LlamafuModelParams extends Struct {
  external Pointer<Utf8> model_path;

  external Pointer<Utf8> mmproj_path;

  @Int32()
  external int n_threads;

  @Int32()
  external int n_ctx;

  @Uint8()
  external int use_gpu;
}

final class LlamafuInferParams extends Struct {
  external Pointer<Utf8> prompt;

  @Int32()
  external int max_tokens;

  @Float()
  external double temperature;
}

// Callback used by the old streaming API (kept for ABI compatibility)
typedef LlamafuStreamCallbackC = Void Function(Pointer<Utf8>, Pointer<Void>);

// Polling-based streaming read
typedef LlamafuReadStreamTokenC = LlamafuError Function(
    Pointer<Void>, Pointer<Pointer<Utf8>>, Pointer<Bool>);

typedef LlamafuReadStreamTokenDart = int Function(
    Pointer<Void>, Pointer<Pointer<Utf8>>, Pointer<Bool>);

// Init
typedef LlamafuInitC = LlamafuError Function(
    Pointer<LlamafuModelParams>, Pointer<Pointer<Void>>);

typedef LlamafuInitDart = int Function(
    Pointer<LlamafuModelParams>, Pointer<Pointer<Void>>);

// Complete (non-streaming)
typedef LlamafuCompleteC = LlamafuError Function(
    Pointer<Void>, Pointer<LlamafuInferParams>, Pointer<Pointer<Utf8>>);

typedef LlamafuCompleteDart = int Function(
    Pointer<Void>, Pointer<LlamafuInferParams>, Pointer<Pointer<Utf8>>);

// Complete streaming (start)
typedef LlamafuCompleteStreamC = LlamafuError Function(
    Pointer<Void>,
    Pointer<LlamafuInferParams>,
    Pointer<NativeFunction<LlamafuStreamCallbackC>>,
    Pointer<Void>);

typedef LlamafuCompleteStreamDart = int Function(
    Pointer<Void>,
    Pointer<LlamafuInferParams>,
    Pointer<NativeFunction<LlamafuStreamCallbackC>>,
    Pointer<Void>);

// Free helpers
typedef LlamafuFreeStringC = Void Function(Pointer<Utf8>);
typedef LlamafuFreeStringDart = void Function(Pointer<Utf8>);

typedef LlamafuFreeC = Void Function(Pointer<Void>);
typedef LlamafuFreeDart = void Function(Pointer<Void>);

final class LlamafuBindings {
  final DynamicLibrary _lib;

  LlamafuBindings._(this._lib);

  late final LlamafuInitDart _llamafuInit;
  late final LlamafuCompleteDart _llamafuComplete;
  late final LlamafuCompleteStreamDart _llamafuCompleteStream;
  late final LlamafuReadStreamTokenDart _llamafuReadStreamToken;
  late final LlamafuFreeStringDart _llamafuFreeString;
  late final LlamafuFreeDart _llamafuFree;

  static Future<LlamafuBindings> init() async {
    DynamicLibrary lib;
    if (Platform.isAndroid) {
      lib = DynamicLibrary.open('libllamafu.so');
    } else if (Platform.isIOS) {
      lib = DynamicLibrary.process();
    } else if (Platform.isMacOS) {
      lib = DynamicLibrary.open('libllamafu.dylib');
    } else if (Platform.isWindows) {
      lib = DynamicLibrary.open('llamafu.dll');
    } else if (Platform.isLinux) {
      lib = DynamicLibrary.open('libllamafu.so');
    } else {
      throw UnsupportedError('Unsupported platform: ${Platform.operatingSystem}');
    }

    final b = LlamafuBindings._(lib);

    b._llamafuInit = lib
        .lookup<NativeFunction<LlamafuInitC>>('llamafu_init')
        .asFunction<LlamafuInitDart>();

    b._llamafuComplete = lib
        .lookup<NativeFunction<LlamafuCompleteC>>('llamafu_complete')
        .asFunction<LlamafuCompleteDart>();

    b._llamafuCompleteStream = lib
        .lookup<NativeFunction<LlamafuCompleteStreamC>>('llamafu_complete_stream')
        .asFunction<LlamafuCompleteStreamDart>();

    b._llamafuReadStreamToken = lib
        .lookup<NativeFunction<LlamafuReadStreamTokenC>>('llamafu_read_stream_token')
        .asFunction<LlamafuReadStreamTokenDart>();

    b._llamafuFreeString = lib
        .lookup<NativeFunction<LlamafuFreeStringC>>('llamafu_free_string')
        .asFunction<LlamafuFreeStringDart>();

    b._llamafuFree = lib
        .lookup<NativeFunction<LlamafuFreeC>>('llamafu_free')
        .asFunction<LlamafuFreeDart>();

    return b;
  }

  int llamafuInit(Pointer<LlamafuModelParams> params, Pointer<Pointer<Void>> outPtr) =>
      _llamafuInit(params, outPtr);

  int llamafuComplete(
          Pointer<Void> instance,
          Pointer<LlamafuInferParams> params,
          Pointer<Pointer<Utf8>> outResult) =>
      _llamafuComplete(instance, params, outResult);

  int llamafuCompleteStream(
          Pointer<Void> instance,
          Pointer<LlamafuInferParams> params,
          Pointer<NativeFunction<LlamafuStreamCallbackC>> callback,
          Pointer<Void> userData) =>
      _llamafuCompleteStream(instance, params, callback, userData);

  int llamafuReadStreamToken(
          Pointer<Void> instance,
          Pointer<Pointer<Utf8>> outToken,
          Pointer<Bool> outCompleted) =>
      _llamafuReadStreamToken(instance, outToken, outCompleted);

  void llamafuFreeString(Pointer<Utf8> str) => _llamafuFreeString(str);

  void llamafuFree(Pointer<Void> instance) => _llamafuFree(instance);
}
