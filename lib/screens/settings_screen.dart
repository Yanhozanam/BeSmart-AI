import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/model_config.dart';
import '../providers/chat_provider.dart';
import '../providers/model_provider.dart';
import '../services/model_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final StorageService _storage = StorageService();
  late String _language;
  late String _modelTier;

  @override
  void initState() {
    super.initState();
    _language = _storage.getLanguage();
    _modelTier = _storage.getModelTier();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection(
            context,
            'Language',
            Icons.language,
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
            Icons.memory,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModelTile('Lite (400MB)', 'lite'),
                _buildModelTile('Standard (900MB)', 'standard'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Consumer<ModelProvider>(
            builder: (context, modelProvider, _) {
              return _buildSection(
                context,
                'Model Management',
                Icons.download,
                _buildModelManagement(modelProvider),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Data',
            Icons.delete_outline,
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _onClearChat,
                  icon: const Icon(Icons.delete, color: AppColors.errorText),
                  label: const Text(
                    'Clear Chat',
                    style: TextStyle(color: AppColors.errorText),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.errorText),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Debug Info',
            Icons.bug_report,
            FutureBuilder<Map<String, String>>(
              future: _getDebugInfo(),
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
              'BeSmartAI v1.0.0',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelManagement(ModelProvider provider) {
    final model = provider.currentModel;

    if (model.status == ModelStatus.error) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error, color: AppColors.errorText, size: 20),
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
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              label: const Text(
                'Retry',
                style: TextStyle(color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      );
    }

    final isReady = model.status == ModelStatus.ready;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isReady ? Icons.check_circle : Icons.cloud_download,
              color: isReady ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              isReady ? '${model.label} ready' : '${model.label} not downloaded',
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
                  onPressed: () => _onDeleteModel(provider),
                  icon: const Icon(Icons.delete_outline, color: AppColors.errorText),
                  label: const Text(
                    'Delete Model',
                    style: TextStyle(color: AppColors.errorText),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.errorText),
                  ),
                )
              : FilledButton.icon(
                  onPressed: () => provider.download(),
                  icon: const Icon(Icons.download),
                  label: const Text('Download Model'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                  ),
                ),
        ),
      ],
    );
  }

  void _onDeleteModel(ModelProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Model', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Remove downloaded model? App will use mock responses until redownloaded.',
          style: TextStyle(color: AppColors.textSecondary),
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
    Widget content,
  ) {
    return Card(
      color: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.primary),
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
            content,
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
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
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

  Widget _buildModelTile(String label, String value) {
    final selected = _modelTier == value;
    return InkWell(
      onTap: () => _onModelTierChanged(value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
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

  void _onLanguageChanged(String lang) async {
    setState(() => _language = lang);
    await _storage.setLanguage(lang);
  }

  void _onModelTierChanged(String tier) async {
    setState(() => _modelTier = tier);
    await _storage.setModelTier(tier);
  }

  Future<Map<String, String>> _getDebugInfo() async {
    final modelPath = await ModelConfig.modelPath;
    final modelFile = File(modelPath);
    final exists = await modelFile.exists();
    final size = exists ? await modelFile.length() : 0;

    return {
      'Model Path': modelPath,
      'File Exists': exists.toString(),
      'File Size': '$size bytes (${(size / 1048576).toStringAsFixed(1)} MB)',
      'Expected Size': '${ModelConfig.expectedSizeBytes} bytes (${(ModelConfig.expectedSizeBytes / 1048576).toStringAsFixed(1)} MB)',
      'Matches Size': (exists && size >= ModelConfig.expectedSizeBytes - 1024).toString(),
    };
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
