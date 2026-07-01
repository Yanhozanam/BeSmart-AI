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
  String _errorMessage = '';
  bool _isLoadError = false;
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
        _errorMessage = info.errorMessage ?? '';
        _isLoadError = _progress >= 1.0;
      } else if (info.status == ModelStatus.ready) {
        _isDownloading = false;
        _navigateToChat();
      } else if (info.status == ModelStatus.downloading) {
        _isDownloading = true;
        _hasError = false;
        _errorMessage = '';
        _isLoadError = false;
      }
    });
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
      _errorMessage = '';
      _isLoadError = false;
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
          _errorMessage = e.toString();
          _isLoadError = _progress >= 1.0;
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

  void _skipToChat() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ChatScreen()),
    );
  }

  String _formatMB(int bytes) {
    final mb = bytes / (1024 * 1024);
    return '${mb.toStringAsFixed(0)} MB';
  }

  String _formatError(String msg) {
    // Clean up common error wrappers for readability
    var clean = msg;
    if (clean.startsWith('Exception: ')) {
      clean = clean.substring(11);
    }
    if (clean.startsWith('ArgumentError: ')) {
      clean = clean.substring(15);
    }
    return clean;
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
              Icon(
                Icons.auto_awesome,
                size: 80,
                color: _hasError ? const Color(0xFF9E6A6A) : const Color(0xFF00A884),
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
              _buildStatusText(),
              const SizedBox(height: 40),
              if (_isDownloading || _progress > 0) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _isLoadError ? 1.0 : _progress,
                    minHeight: 12,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isLoadError ? Colors.redAccent : const Color(0xFF00A884),
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _isLoadError ? Colors.redAccent : const Color(0xFF00A884),
                  ),
                ),
              ],
              if (_hasError) ...[
                const SizedBox(height: 24),
                _buildErrorMessage(),
              ],
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText() {
    if (_hasError && _isLoadError) {
      return const Text(
        'Model downloaded successfully but could not be loaded.\n'
        'Your device may not have enough memory.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Colors.white70),
      );
    }
    if (_hasError) {
      return const Text(
        'Download interrupted.\nTap Retry to try again.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Colors.white70),
      );
    }
    if (_isDownloading) {
      return const Text(
        'Wait a little bit, BeSmart is getting ready.\n'
        'Just make sure you are connected to a good WiFi.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: Colors.white70),
      );
    }
    return const Text(
      'Wait a little bit, BeSmart is getting ready.\n'
      'Just make sure you are connected to a good WiFi.',
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 14, color: Colors.white70),
    );
  }

  Widget _buildErrorMessage() {
    final display = _formatError(_errorMessage);

    return Column(
      children: [
        if (display.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: Text(
              display,
              style: const TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              textAlign: TextAlign.center,
            ),
          ),
        const SizedBox(height: 24),
        if (_isLoadError) ...[
          FilledButton.icon(
            onPressed: _isDownloading ? null : _onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00A884),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _isDownloading ? null : _skipToChat,
            icon: const Icon(Icons.chat),
            label: const Text('Continue with Mock AI'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withOpacity(0.3)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              foregroundColor: Colors.white70,
            ),
          ),
        ] else ...[
          FilledButton.icon(
            onPressed: _isDownloading ? null : _onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF00A884),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            ),
          ),
        ],
      ],
    );
  }
}
