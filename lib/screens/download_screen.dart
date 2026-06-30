import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../config/model_config.dart';
import '../services/model_manager.dart';
import 'chat_screen.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  double _progress = 0.0;
  int _received = 0;
  int _total = ModelConfig.expectedSizeBytes;
  bool _isDownloading = false;
  bool _hasError = false;
  bool _noInternet = false;
  StreamSubscription<ModelInfo>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = ModelManager().statusStream.listen(_onStatusChange);
    _checkAndStart();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  void _onStatusChange(ModelInfo info) {
    if (!mounted) return;
    setState(() {
      _progress = info.progress;
      if (info.status == ModelStatus.error) {
        _hasError = true;
        _isDownloading = false;
        _noInternet = _isNetworkError(info.errorMessage ?? '');
      } else if (info.status == ModelStatus.ready) {
        _isDownloading = false;
        _navigateToChat();
      } else if (info.status == ModelStatus.downloading) {
        _isDownloading = true;
        _hasError = false;
      }
    });
  }

  bool _isNetworkError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('socket') ||
        lower.contains('connection') ||
        lower.contains('timeout') ||
        lower.contains('network') ||
        lower.contains('dns') ||
        lower.contains('host');
  }

  Future<void> _checkAndStart() async {
    if (ModelManager().isReady) {
      _navigateToChat();
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    final partialFile = File('${dir.path}/${ModelConfig.fileName}.part');

    if (await partialFile.exists()) {
      final partialSize = await partialFile.length();
        setState(() {
          _received = partialSize;
          _progress = (partialSize / ModelConfig.expectedSizeBytes).clamp(0.0, 1.0);
        });
    }

    await _startDownload();
  }

  Future<void> _startDownload() async {
    setState(() {
      _isDownloading = true;
      _hasError = false;
      _noInternet = false;
    });

    try {
      await ModelManager().downloadModel(
        onProgress: (progress, received, total) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _received = received;
              _total = total;
            });
          }
        },
      );
      if (mounted) {
        _navigateToChat();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _hasError = true;
          _noInternet = _isNetworkError(e.toString());
        });
      }
    }
  }

  void _onRetry() {
    _startDownload();
  }

  void _navigateToChat() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  String _formatMB(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111B21),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              const Icon(
                Icons.auto_awesome,
                size: 80,
                color: Color(0xFF00A884),
              ),
              const SizedBox(height: 24),
              const Text(
                'Setting up BeSmartAI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _hasError && _noInternet
                    ? 'Connect to WiFi or mobile data to download BeSmartAI (1.12 GB). After this, no internet is needed.'
                    : _hasError
                        ? 'Download interrupted. Your progress is saved — tap Retry to continue.'
                        : _isDownloading
                            ? 'Downloading the AI model. This only happens once — after this, BeSmartAI works fully offline.'
                            : 'Preparing to download the AI model...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 40),
              if (_isDownloading || _progress > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _progress,
                    minHeight: 12,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF00A884),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_formatMB(_received)} / ${_formatMB(_total)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(_progress * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00A884),
                  ),
                ),
              ],
              if (_hasError) ...[
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _isDownloading ? null : _onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF00A884),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                  ),
                ),
              ],
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }
}
