import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class DebugLogger {
  static final DebugLogger _instance = DebugLogger._internal();
  factory DebugLogger() => _instance;
  DebugLogger._internal();

  static const int _maxEntries = 50;
  List<String> _entries = [];
  String? _logPath;

  Future<void> init() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      _logPath = '${dir.path}/debug_log.txt';
      final file = File(_logPath!);
      if (await file.exists()) {
        _entries = (await file.readAsString())
            .split('\n')
            .where((l) => l.isNotEmpty)
            .toList();
        if (_entries.length > _maxEntries) {
          _entries = _entries.sublist(_entries.length - _maxEntries);
        }
      }
    } catch (e) {
      debugPrint('[DebugLogger] Init failed: $e');
    }
  }

  void log(String tag, String message) {
    final entry = '[${DateTime.now().toIso8601String()}] $tag: $message';
    debugPrint(entry);
    _entries.add(entry);
    if (_entries.length > _maxEntries) {
      _entries.removeAt(0);
    }
    _writeToFile();
  }

  void logPrompt(String prompt) {
    log('PROMPT', prompt);
  }

  void logResponse(String response) {
    log('RESPONSE', response);
  }

  void logError(String error) {
    log('ERROR', error);
  }

  void _writeToFile() {
    if (_logPath == null) return;
    try {
      final file = File(_logPath!);
      file.writeAsStringSync(_entries.join('\n'));
    } catch (e) {
      debugPrint('[DebugLogger] Write failed: $e');
    }
  }

  List<String> getEntries() => List.unmodifiable(_entries);

  void clear() {
    _entries.clear();
    _writeToFile();
  }
}