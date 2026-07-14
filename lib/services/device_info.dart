import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class DeviceInfo {
  final int ramMB;
  final int freeStorageMB;

  DeviceInfo({
    required this.ramMB,
    required this.freeStorageMB,
  });

  String get recommendedModelTier {
    if (ramMB < 4096 || freeStorageMB < 5000) return 'lite';
    return 'standard';
  }

  static Future<DeviceInfo> detect() async {
    final ram = await _estimateRAM();
    final storage = await _estimateFreeStorage();
    return DeviceInfo(ramMB: ram, freeStorageMB: storage);
  }

  static Future<int> _estimateRAM() async {
    try {
      if (Platform.isAndroid || Platform.isLinux) {
        final content = await File('/proc/meminfo').readAsString();
        final match = RegExp(r'MemTotal:\s+(\d+)').firstMatch(content);
        if (match != null) return int.parse(match.group(1)!) ~/ 1024;
      }
    } catch (e) {
      debugPrint('[DeviceInfo] RAM detection failed: $e');
    }
    return 4096;
  }

  static Future<int> _estimateFreeStorage() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final result = await Process.run('df', ['-k', dir.path]);
      if (result.exitCode == 0) {
        final lines = result.stdout.toString().trim().split('\n');
        if (lines.length >= 2) {
          final parts = lines.last.trim().split(RegExp(r'\s+'));
          if (parts.length >= 4) {
            final kB = int.tryParse(parts[3]);
            if (kB != null) return kB ~/ 1024;
          }
        }
      }
    } catch (e) {
      debugPrint('[DeviceInfo] Storage detection failed: $e');
    }
    return 2048;
  }
}
