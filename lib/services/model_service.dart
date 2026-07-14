import 'dart:async';
import 'package:flutter/foundation.dart';
import 'model_manager.dart' as mgr;
import '../config/model_config.dart';

enum ModelStatus { notDownloaded, downloading, ready, error }

class ModelInfo {
  final ModelTier tier;
  final int sizeMB;
  final ModelStatus status;
  final double progress;
  final String? error;

  const ModelInfo({
    this.tier = ModelTier.standard,
    this.sizeMB = 900,
    this.status = ModelStatus.notDownloaded,
    this.progress = 0.0,
    this.error,
  });

  ModelInfo copyWith({
    ModelTier? tier,
    int? sizeMB,
    ModelStatus? status,
    double? progress,
    String? error,
  }) {
    return ModelInfo(
      tier: tier ?? this.tier,
      sizeMB: sizeMB ?? this.sizeMB,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: error ?? this.error,
    );
  }

  String get label =>
      tier == ModelTier.lite ? 'Lite (924 MB)' : 'Standard (3.17 GB)';
}

class ModelService extends ChangeNotifier {
  final mgr.ModelManager _manager = mgr.ModelManager();
  ModelInfo _currentModel = const ModelInfo();
  final _progressController = StreamController<double>.broadcast();
  StreamSubscription<mgr.ModelInfo>? _subscription;

  Stream<double> get progressStream => _progressController.stream;
  ModelInfo get currentModel => _currentModel;
  ModelTier get currentTier => _currentModel.tier;

  ModelService() {
    _subscription = _manager.statusStream.listen(_onManagerStatus);
  }

  void _onManagerStatus(mgr.ModelInfo info) {
    ModelStatus status;
    switch (info.status) {
      case mgr.ModelStatus.ready:
        status = ModelStatus.ready;
        break;
      case mgr.ModelStatus.error:
        status = ModelStatus.error;
        break;
      case mgr.ModelStatus.downloading:
        status = ModelStatus.downloading;
        break;
      case mgr.ModelStatus.unavailable:
        status = ModelStatus.notDownloaded;
        break;
    }

    _currentModel = _currentModel.copyWith(
      tier: info.tier,
      status: status,
      progress: info.progress,
      error: info.errorMessage,
      sizeMB: info.tier == ModelTier.lite ? 924 : 3170,
    );

    if (!_progressController.isClosed) {
      _progressController.add(info.progress);
    }
    notifyListeners();
  }

  Future<void> setTier(ModelTier tier) async {
    if (tier == _currentModel.tier && _currentModel.status == ModelStatus.ready) {
      return;
    }
    await _manager.initialize(tier: tier);
    if (_manager.isReady) {
      _currentModel = _currentModel.copyWith(tier: tier, status: ModelStatus.ready);
    } else {
      _currentModel = _currentModel.copyWith(tier: tier, status: ModelStatus.notDownloaded);
    }
    notifyListeners();
  }

  Future<void> downloadCurrentTier() async {
    _currentModel = _currentModel.copyWith(status: ModelStatus.downloading, progress: 0.0);
    notifyListeners();
    try {
      await _manager.downloadModel(
        onProgress: (progress, received, total) {
          if (!_progressController.isClosed) {
            _progressController.add(progress);
          }
        },
        tier: _currentModel.tier,
      );
    } catch (e) {
      _currentModel = _currentModel.copyWith(status: ModelStatus.error, error: e.toString());
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteModel() async {
    await _manager.deleteModel(_currentModel.tier);
    _currentModel = _currentModel.copyWith(status: ModelStatus.notDownloaded);
    notifyListeners();
  }

  Future<void> loadState() async {
    if (_manager.isReady) {
      _currentModel = _currentModel.copyWith(status: ModelStatus.ready);
    } else {
      _currentModel = _currentModel.copyWith(status: ModelStatus.notDownloaded);
    }
    notifyListeners();
  }

  Future<bool> checkModelExists() async {
    return _manager.isReady;
  }

  Future<bool> tryInitializeModel() async {
    final success = await _manager.reloadModel(tier: _currentModel.tier);
    return success;
  }

  bool isModelReady(ModelTier tier) {
    return _currentModel.status == ModelStatus.ready && _currentModel.tier == tier;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _progressController.close();
    super.dispose();
  }
}