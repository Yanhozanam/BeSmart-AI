import 'package:flutter/foundation.dart';
import '../config/model_config.dart';
import '../services/model_service.dart';

class ModelProvider extends ChangeNotifier {
  final ModelService _service = ModelService();

  ModelInfo get currentModel => _service.currentModel;
  ModelTier get currentTier => _service.currentTier;
  bool get isReady => _service.currentModel.status == ModelStatus.ready;

  ModelProvider() {
    _service.addListener(_onServiceChange);
    _load();
  }

  void _onServiceChange() {
    notifyListeners();
  }

  Future<void> _load() async {
    try {
      await _service.loadState();
    } catch (_) {
      notifyListeners();
    }
  }

  Future<void> download() async {
    await _service.downloadCurrentTier();
    notifyListeners();
  }

  Future<void> deleteModel() async {
    await _service.deleteModel();
    notifyListeners();
  }

  Future<void> switchTier(ModelTier tier) async {
    await _service.setTier(tier);
    notifyListeners();
  }

  bool isModelReady(ModelTier tier) => _service.isModelReady(tier);

  @override
  void dispose() {
    _service.removeListener(_onServiceChange);
    _service.dispose();
    super.dispose();
  }
}