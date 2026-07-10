import 'package:flutter/material.dart';
import '../services/device_info.dart';
import '../services/model_manager.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import 'chat_screen.dart';
import 'download_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _checking = true;
  int _ramMB = 0;
  int _freeStorageMB = 0;
  String _recommendedModel = 'lite';
  bool _storageSufficient = true;

  @override
  void initState() {
    super.initState();
    _performCheck();
  }

  Future<void> _performCheck() async {
    final info = await DeviceInfo.detect();
    final recommended = info.recommendedModelTier;

    setState(() {
      _ramMB = info.ramMB;
      _freeStorageMB = info.freeStorageMB;
      _recommendedModel = recommended;
      _storageSufficient = info.freeStorageMB >= 400;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),
              const Icon(
                Icons.auto_awesome,
                size: 80,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'BeSmartAI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your offline study companion',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(flex: 1),
              Card(
                color: AppColors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Device Compatibility Check',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _infoRow(
                        context,
                        'RAM',
                        '${_ramMB}MB',
                        _ramMB >= 4096,
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        context,
                        'Free Storage',
                        '${_freeStorageMB}MB',
                        _freeStorageMB >= 400,
                      ),
                      const SizedBox(height: 8),
                      _infoRow(
                        context,
                        'Recommendation',
                        _recommendedModel == 'standard'
                            ? 'Standard (900MB)'
                            : 'Lite (400MB)',
                        _storageSufficient,
                      ),
                    ],
                  ),
                ),
              ),
              if (!_storageSufficient)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Low storage detected. Only Lite mode available.',
                    style: TextStyle(
                      color: AppColors.errorText,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              const Spacer(flex: 2),
              FilledButton(
                onPressed: _onContinue,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Continue'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value, bool ok) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.warning,
          size: 20,
          color: ok ? AppColors.primary : AppColors.warningText,
        ),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _onContinue() async {
    final storage = StorageService();
    await storage.setOnboardingDone();
    await storage.setModelTier(_recommendedModel);

    if (!mounted) return;

    final modelReady = ModelManager().isReady;
    if (modelReady) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const DownloadScreen()),
      );
    }
  }
}
