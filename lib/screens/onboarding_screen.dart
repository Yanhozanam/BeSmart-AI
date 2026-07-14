import 'package:flutter/material.dart';
import '../config/model_config.dart';
import '../providers/model_provider.dart';
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
  ModelTier _recommendedTier = ModelTier.standard;
  bool _canRunStandard = true;
  ModelTier _selectedTier = ModelTier.standard;

  @override
  void initState() {
    super.initState();
    _performCheck();
  }

  Future<void> _performCheck() async {
    final info = await DeviceInfo.detect();
    final canRunStandard = info.ramMB >= 4096 && info.freeStorageMB >= 5000;
    final recommended = canRunStandard ? ModelTier.standard : ModelTier.lite;

    setState(() {
      _ramMB = info.ramMB;
      _freeStorageMB = info.freeStorageMB;
      _recommendedTier = recommended;
      _selectedTier = recommended;
      _canRunStandard = canRunStandard;
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
              // Mascot + Title
              Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.mascotBadgeBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      size: 40,
                      color: AppColors.mascotBadgeIcon,
                    ),
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
                ],
              ),
              const Spacer(flex: 1),
              // Tier selection cards
              _buildTierCards(),
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

  Widget _buildTierCards() {
    return Column(
      children: [
        const Text(
          'Choose Your Model',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _tierCard(ModelTier.lite),
        const SizedBox(height: 12),
        _tierCard(ModelTier.standard),
        if (!_canRunStandard) ...[
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Standard tier requires 4 GB+ RAM and 5 GB+ storage.',
              style: TextStyle(
                color: AppColors.warningText,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  Widget _tierCard(ModelTier tier) {
    final isSelected = _selectedTier == tier;
    final isRecommended = tier == _recommendedTier;
    final config = _getTierConfig(tier);

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = tier),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDim : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : isRecommended
                    ? AppColors.primary.withValues(alpha: 0.3)
                    : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : AppColors.primaryDim,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    config.icon,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${config.name} Tier',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Recommended',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${config.modelName} • ${config.size}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        config.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _reqBadge(Icons.memory_rounded, config.ramRequired),
                const SizedBox(width: 12),
                _reqBadge(Icons.storage_rounded, config.storageRequired),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _reqBadge(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  _TierConfig _getTierConfig(ModelTier tier) {
    if (tier == ModelTier.lite) {
      return _TierConfig(
        name: 'Lite',
        modelName: ModelConfig.liteModelName,
        size: '924 MB',
        description: 'Qwen 2.5 1.5B — Fast, lightweight',
        ramRequired: '3 GB+ RAM',
        storageRequired: '1.5 GB+ storage',
        icon: Icons.speed_rounded,
      );
    } else {
      return _TierConfig(
        name: 'Standard',
        modelName: ModelConfig.stdModelName,
        size: '3.17 GB',
        description: 'Gemma 4 E2B QAT — Smarter, better reasoning',
        ramRequired: '4 GB+ RAM',
        storageRequired: '5 GB+ storage',
        icon: Icons.psychology_rounded,
      );
    }
  }

  void _onContinue() async {
    final storage = StorageService();
    await storage.setOnboardingDone();
    await storage.setModelTier(_selectedTier);

    if (!mounted) return;

    final modelReady = ModelManager().isReady;
    if (modelReady && ModelManager().info.tier == _selectedTier) {
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

class _TierConfig {
  final String name;
  final String modelName;
  final String size;
  final String description;
  final String ramRequired;
  final String storageRequired;
  final IconData icon;

  const _TierConfig({
    required this.name,
    required this.modelName,
    required this.size,
    required this.description,
    required this.ramRequired,
    required this.storageRequired,
    required this.icon,
  });
}