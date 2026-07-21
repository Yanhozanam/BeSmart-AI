import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/model_config.dart';
import '../l10n/app_localizations.dart';
import '../providers/chat_provider.dart';
import '../providers/model_provider.dart';
import '../services/model_service.dart';
import '../services/device_info.dart';
import '../services/model_manager.dart' hide ModelStatus;
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import 'download_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  late String _language;
  late ModelTier _selectedTier;

  @override
  void initState() {
    super.initState();
    _language = _storage.getLanguage();
    _selectedTier = _storage.getModelTier();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Consumer<ModelProvider>(
        builder: (context, modelProvider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSection(
                context,
                'Language',
                Icons.language_rounded,
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRadioTile('English', 'en'),
                    _buildRadioTile('Français', 'fr'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Model Tier',
                Icons.memory_rounded,
                _buildTierOptions(modelProvider),
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Model Management',
                Icons.download_rounded,
                _buildModelManagement(modelProvider),
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Data',
                Icons.delete_outline_rounded,
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _onClearChat,
                      icon: const Icon(Icons.delete_rounded, color: AppColors.errorText, size: 20),
                      label: const Text(
                        'Clear Chat',
                        style: TextStyle(color: AppColors.errorText, fontSize: 15),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.errorText),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                context,
                'Debug Info',
                Icons.bug_report_rounded,
                FutureBuilder<Map<String, String>>(
                  future: _getDebugInfo(modelProvider.currentTier),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox(
                        height: 20,
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    final data = snapshot.data!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: data.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '${e.key}: ${e.value}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      )).toList(),
                    );
                  },
                ),
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'BeSmart v1.0.0',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTierOptions(ModelProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTierTile(ModelTier.lite, provider),
        const SizedBox(height: 8),
        _buildTierTile(ModelTier.standard, provider),
      ],
    );
  }

  Widget _buildTierTile(ModelTier tier, ModelProvider provider) {
    final isSelected = _selectedTier == tier;
    final tierName = tier == ModelTier.lite ? 'Lite' : 'Standard';
    final modelName = tier == ModelTier.lite ? ModelConfig.liteModelName : ModelConfig.stdModelName;
    final size = tier == ModelTier.lite ? '924 MB' : '3.17 GB';
    final ramReq = tier == ModelTier.lite ? '3 GB+ RAM' : '4 GB+ RAM';
    final storageReq = tier == ModelTier.lite ? '1.5 GB+ storage' : '5 GB+ storage';
    final isActive = tier == provider.currentTier && provider.currentModel.status == ModelStatus.ready;

    return GestureDetector(
      onTap: () => _onTierChanged(tier, provider.currentTier),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDim : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
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
                tier == ModelTier.lite ? Icons.speed_rounded : Icons.psychology_rounded,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 24,
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
                        '$tierName Tier',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (isActive) ...[
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
                            'Active',
                            style: TextStyle(
                              fontSize: 10,
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
                    '$modelName • $size',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTierDescription(tier),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.memory_rounded,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        ramReq,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.storage_rounded,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        storageReq,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  String _getTierDescription(ModelTier tier) {
    if (tier == ModelTier.lite) {
      return 'BeSmart Lite — Fast, lightweight';
    } else {
      return 'BeSmart Standard — Smarter, better reasoning';
    }
  }

  Widget _buildModelManagement(ModelProvider provider) {
    final model = provider.currentModel;
    final tier = provider.currentTier;

    if (model.status == ModelStatus.error) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_rounded, color: AppColors.errorText, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Download failed',
                  style: TextStyle(
                    color: AppColors.errorText,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => provider.download(),
              icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
              label: const Text(
                'Retry',
                style: TextStyle(color: AppColors.primary, fontSize: 15),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      );
    }

    final isReady = model.status == ModelStatus.ready;
    final tierName = tier == ModelTier.lite ? 'Lite' : 'Standard';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isReady ? Icons.check_circle_rounded : Icons.cloud_download_rounded,
              color: isReady ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isReady ? '$tierName model ready' : '$tierName model not downloaded',
              style: TextStyle(
                color: isReady ? AppColors.primary : AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: isReady
              ? OutlinedButton.icon(
                  onPressed: () => _onDeleteModel(tier, provider),
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.errorText, size: 20),
                  label: const Text(
                    'Delete Model',
                    style: TextStyle(color: AppColors.errorText, fontSize: 15),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.errorText),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )
              : FilledButton.icon(
                  onPressed: () => provider.download(),
                  icon: const Icon(Icons.download_rounded, size: 20),
                  label: const Text('Download Model', style: TextStyle(fontSize: 15)),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
        ),
      ],
    );
  }

  void _onLanguageChanged(String lang) async {
    setState(() => _language = lang);
    await _storage.setLanguage(lang);
  }

  void _onTierChanged(ModelTier tier, ModelTier currentTier) async {
    if (tier == _selectedTier) return;

    final tierName = tier == ModelTier.lite ? 'Lite' : 'Standard';
    final currentName = currentTier == ModelTier.lite ? 'Lite' : 'Standard';

    if (tier == ModelTier.standard && !(await _hasEnoughResources())) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Resource Warning',
            style: TextStyle(color: AppColors.textPrimary),
          ),
          content: const Text(
            'Standard tier requires 4 GB+ RAM and 5 GB+ free storage. '
            'Your device may not meet these requirements. Continue anyway?',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Continue', style: TextStyle(color: AppColors.primary)),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Switch Model Tier',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'Switch from $currentName to $tierName? This will delete the $currentName model '
          '(${currentTier == ModelTier.lite ? '924 MB' : '3.17 GB'}) and download the $tierName model '
          '(${tier == ModelTier.lite ? '924 MB' : '3.17 GB'}). You\'ll need to wait for the download.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Switch', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ModelManager().deleteModel(currentTier);

    setState(() => _selectedTier = tier);
    await _storage.setModelTier(tier);

    if (mounted) {
      context.read<ModelProvider>().switchTier(tier);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DownloadScreen()),
      );
    }
  }

  Future<bool> _hasEnoughResources() async {
    final info = await DeviceInfo.detect();
    return info.ramMB >= 4096 && info.freeStorageMB >= 5000;
  }

  Future<Map<String, String>> _getDebugInfo(ModelTier tier) async {
    final modelPath = await ModelConfig.modelPathForTier(tier);
    final modelFile = File(modelPath);
    final exists = await modelFile.exists();
    final size = exists ? await modelFile.length() : 0;

    return {
      'Active Tier': tier.name,
      'Model Path': modelPath,
      'File Exists': exists.toString(),
      'File Size': '$size bytes (${(size / 1048576).toStringAsFixed(1)} MB)',
      'Expected Size': '${ModelConfig.expectedSizeBytesForTier(tier)} bytes (${(ModelConfig.expectedSizeBytesForTier(tier) / 1048576).toStringAsFixed(1)} MB)',
      'Matches Size': (exists && size >= ModelConfig.expectedSizeBytesForTier(tier) - 1024).toString(),
    };
  }

  void _onDeleteModel(ModelTier tier, ModelProvider provider) {
    final tierName = tier == ModelTier.lite ? 'Lite' : 'Standard';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Model', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Remove downloaded $tierName model? App will use mock responses until redownloaded.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              provider.deleteModel();
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.errorText)),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    IconData icon,
    Widget child,
  ) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      shadowColor: AppColors.cardShadow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildRadioTile(String label, String value) {
    final selected = _language == value;
    return InkWell(
      onTap: () => _onLanguageChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.textPrimary : AppColors.textSecondary,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onClearChat() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Clear Chat', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Delete all messages? This cannot be undone.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              context.read<ChatProvider>().clearChat();
              Navigator.pop(ctx);
            },
            child: const Text('Clear', style: TextStyle(color: AppColors.errorText)),
          ),
        ],
      ),
    );
  }
}