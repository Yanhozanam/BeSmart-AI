import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../config/model_config.dart';
import '../models/message.dart';

class StorageService {
  static const String _messagesBoxName = 'messages';
  static const String _settingsBoxName = 'settings';

  late Box<Message> _messagesBox;
  late Box _settingsBox;

  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  String _appDirPath = '';

  Future<void> init() async {
    final dir = await getApplicationDocumentsDirectory();
    _appDirPath = dir.path;
    await Hive.initFlutter(_appDirPath);

    Hive.registerAdapter(MessageAdapter());

    _messagesBox = await Hive.openBox<Message>(_messagesBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  List<Message> getMessages() {
    return _messagesBox.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  Future<void> addMessage(Message message) async {
    await _messagesBox.put(message.id, message);
  }

  Future<void> deleteMessage(String id) async {
    await _messagesBox.delete(id);
  }

  Future<void> clearMessages() async {
    await _messagesBox.clear();
  }

  String getLanguage() {
    return _settingsBox.get('language', defaultValue: 'en');
  }

  Future<void> setLanguage(String lang) async {
    await _settingsBox.put('language', lang);
  }

  ModelTier getModelTier() {
    final tierStr = _settingsBox.get('modelTier', defaultValue: 'standard');
    return tierStr == 'lite' ? ModelTier.lite : ModelTier.standard;
  }

  Future<void> setModelTier(ModelTier tier) async {
    await _settingsBox.put('modelTier', tier.name);
  }

  bool getOnboardingDone() {
    return _settingsBox.get('onboardingDone', defaultValue: false);
  }

  Future<void> setOnboardingDone() async {
    await _settingsBox.put('onboardingDone', true);
  }

  Future<void> setDeviceInfo(Map<String, dynamic> info) async {
    await _settingsBox.put('deviceInfo', info);
  }

  Map<String, dynamic>? getDeviceInfo() {
    return _settingsBox.get('deviceInfo');
  }
}
