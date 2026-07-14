import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/model_config.dart';
import '../providers/chat_provider.dart';
import '../providers/model_provider.dart';
import '../services/model_service.dart';
import '../theme/app_colors.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart';
import 'download_screen.dart';
import 'settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  late ChatProvider _provider;
  bool _showAttachSheet = false;
  OverlayEntry? _attachSheetEntry;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ChatProvider>();
    _provider.addListener(_onProviderChange);
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChange);
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _removeAttachSheet();
    super.dispose();
  }

  void _onProviderChange() {
    if (_provider.messages.isNotEmpty) {
      _scrollToBottom();
    }
  }

  void _onTextChanged() {
    setState(() {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _focusNode.unfocus();
    _provider.sendMessage(text);
  }

  void _onNewChat() {
    _provider.clearChat();
  }

  void _onSuggestionTap(String prompt) {
    _controller.text = prompt;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: prompt.length),
    );
    _focusNode.requestFocus();
  }

  void _toggleAttachSheet() {
    if (_showAttachSheet) {
      _removeAttachSheet();
    } else {
      _showAttachSheetOverlay();
    }
  }

  void _showAttachSheetOverlay() {
    final overlay = Overlay.of(context);
    _attachSheetEntry = OverlayEntry(
      builder: (context) => _AttachSheet(
        onClose: _removeAttachSheet,
        onAttachTap: _onAttachTap,
      ),
    );
    overlay.insert(_attachSheetEntry!);
    setState(() => _showAttachSheet = true);
  }

  void _removeAttachSheet() {
    _attachSheetEntry?.remove();
    _attachSheetEntry = null;
    setState(() => _showAttachSheet = false);
  }

  void _onAttachTap(String type) {
    _removeAttachSheet();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$type attachment coming soon'),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _showModelOptions(BuildContext context, bool isError) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isError ? 'Model Error' : 'Model Not Downloaded',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isError
                    ? 'The AI model failed to load. Try reloading or re-downloading it.'
                    : 'Download the AI model to get real AI responses. Works fully offline after download.',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DownloadScreen()),
                    );
                  },
                  icon: Icon(isError ? Icons.refresh : Icons.download),
                  label: Text(isError ? 'Reload Model' : 'Download Model'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.background,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.divider),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Open Settings'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        title: const Text(
          'Study with Beso',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () {
              // Overflow menu - could show new chat, settings, etc.
              _onNewChat();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Consumer<ModelProvider>(
            builder: (context, modelProvider, _) {
              if (modelProvider.currentModel.status == ModelStatus.error ||
                  modelProvider.currentModel.status == ModelStatus.notDownloaded) {
                final isError = modelProvider.currentModel.status == ModelStatus.error;
                return GestureDetector(
                  onTap: () => _showModelOptions(context, isError),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    color: isError ? AppColors.errorBg : AppColors.warningBg,
                    child: Row(
                      children: [
                        Icon(
                          isError ? Icons.error_outline : Icons.cloud_download_rounded,
                          color: isError ? AppColors.errorText : AppColors.warningText,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isError
                                ? 'Model error — tap to fix'
                                : 'Model not downloaded — tap to download',
                            style: TextStyle(
                              color: isError
                                  ? AppColors.errorText
                                  : AppColors.warningText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                );
              }
              if (modelProvider.currentModel.status == ModelStatus.downloading) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: AppColors.downloadingBg,
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Downloading ${modelProvider.currentTier == ModelTier.lite ? "Lite" : "Standard"} model... ${(modelProvider.currentModel.progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppColors.downloadingText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (modelProvider.currentModel.status == ModelStatus.ready) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  color: AppColors.primaryDim,
                  child: Text(
                    '${modelProvider.currentTier == ModelTier.lite ? ModelConfig.liteModelName : ModelConfig.stdModelName} ready',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, provider, _) {
                final messages = provider.messages;
                if (messages.isEmpty) {
                  return _buildLandingScreen();
                }
                return Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.only(top: 8, bottom: 8),
                      itemCount: messages.length + (provider.state == ChatState.loading ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index < messages.length) {
                          return MessageBubble(
                            message: messages[index],
                            onRegenerate: () => _provider.regenerateLastResponse(),
                            onFeedback: (isPositive) => _provider.sendFeedback(index, isPositive: isPositive),
                          );
                        }
                        return const TypingIndicator();
                      },
                    ),
                    // Stop generating pill
                    if (provider.state == ChatState.loading)
                      Positioned(
                        bottom: 100,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: _StopGeneratingPill(
                            onStop: () => _provider.cancelGeneration(),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildLandingScreen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          // Mascot + greeting
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.mascotBadgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  size: 24,
                  color: AppColors.mascotBadgeIcon,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGreeting(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'How can I help you study today?',
                    style: TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          _buildSuggestionGrid(),
        ],
      ),
    );
  }

  Widget _buildSuggestionGrid() {
    final suggestions = [
      _SuggestionItem(
        icon: Icons.lightbulb_outline_rounded,
        label: 'Explain a concept',
        prompt: 'Explain the concept of ',
      ),
      _SuggestionItem(
        icon: Icons.summarize_rounded,
        label: 'Summarize this text',
        prompt: 'Summarize the following: ',
      ),
      _SuggestionItem(
        icon: Icons.quiz_rounded,
        label: 'Quiz me on a topic',
        prompt: 'Quiz me on the topic of ',
      ),
      _SuggestionItem(
        icon: Icons.edit_note_rounded,
        label: 'Help me write an essay',
        prompt: 'Help me write an essay about ',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemCount: suggestions.length,
      itemBuilder: (context, index) => _buildSuggestionCard(suggestions[index]),
    );
  }

  Widget _buildSuggestionCard(_SuggestionItem item) {
    return GestureDetector(
      onTap: () => _onSuggestionTap(item.prompt),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.suggestionChipBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              item.icon,
              color: AppColors.primary,
              size: 24,
            ),
            const SizedBox(height: 12),
            Text(
              item.label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.state == ChatState.loading;
        return Container(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.inputFill,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attach button
                IconButton(
                  icon: Icon(
                    _showAttachSheet ? Icons.close_rounded : Icons.add_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: _toggleAttachSheet,
                ),
                // Text field
                Expanded(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 140),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      enabled: !isLoading,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _onSend(),
                      maxLines: null,
                      minLines: 1,
                      decoration: InputDecoration(
                        hintText: isLoading ? 'Beso is thinking...' : 'Ask anything...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 12,
                        ),
                      ),
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                // Send button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _controller.text.isEmpty
                        ? AppColors.disabledButton
                        : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: isLoading ? null : _onSend,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StopGeneratingPill extends StatelessWidget {
  final VoidCallback onStop;

  const _StopGeneratingPill({required this.onStop});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onStop,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.stopPillBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.stopPillText.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.stop_rounded,
              size: 16,
              color: AppColors.stopPillText,
            ),
            const SizedBox(width: 8),
            const Text(
              'Stop generating',
              style: TextStyle(
                color: AppColors.stopPillText,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttachSheet extends StatelessWidget {
  final VoidCallback onClose;
  final Function(String) onAttachTap;

  const _AttachSheet({
    required this.onClose,
    required this.onAttachTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onTap: onClose,
          behavior: HitTestBehavior.translucent,
          child: Container(
            margin: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: _AttachSheetContent(
              onClose: onClose,
              onAttachTap: onAttachTap,
            ),
          ),
        ),
      ),
    );
  }
}

class _AttachSheetContent extends StatefulWidget {
  final VoidCallback onClose;
  final Function(String) onAttachTap;

  const _AttachSheetContent({
    required this.onClose,
    required this.onAttachTap,
  });

  @override
  State<_AttachSheetContent> createState() => _AttachSheetContentState();
}

class _AttachSheetContentState extends State<_AttachSheetContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _controller.reverse();
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      _AttachItem(
        icon: Icons.photo_library_rounded,
        label: 'Photo',
        description: 'Choose from gallery',
        onTap: () => widget.onAttachTap('Photo'),
      ),
      _AttachItem(
        icon: Icons.camera_alt_rounded,
        label: 'Camera',
        description: 'Take a photo',
        onTap: () => widget.onAttachTap('Camera'),
      ),
      _AttachItem(
        icon: Icons.insert_drive_file_rounded,
        label: 'File',
        description: 'Attach a document',
        onTap: () => widget.onAttachTap('File'),
      ),
      _AttachItem(
        icon: Icons.mic_rounded,
        label: 'Voice',
        description: 'Record voice message',
        onTap: () => widget.onAttachTap('Voice'),
        comingSoon: true,
      ),
    ];

    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onTap: () {}, // Prevent tap from closing
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Add to chat',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                          onPressed: _close,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // 2x2 grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.1,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) =>
                          _buildAttachTile(items[index]),
                    ),
                    const SizedBox(height: 24),
                    // Recent section
                    Row(
                      children: [
                        const Text(
                          'Recent',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _close,
                          child: const Text(
                            'Clear all',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'No recent attachments',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
         ),
        ),
    );
  }

  Widget _buildAttachTile(_AttachItem item) {
    return GestureDetector(
      onTap: item.comingSoon
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Voice input coming soon'),
                  duration: const Duration(seconds: 1),
                  backgroundColor: AppColors.surface,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            }
          : () {
              _close();
              item.onTap();
            },
      child: Container(
        decoration: BoxDecoration(
          color: item.comingSoon ? AppColors.disabledButton : AppColors.suggestionChipBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.comingSoon
                ? Colors.transparent
                : AppColors.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              item.icon,
              color: item.comingSoon ? AppColors.textMuted : AppColors.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: TextStyle(
                color: item.comingSoon ? AppColors.textMuted : AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.description,
              style: TextStyle(
                color: item.comingSoon ? AppColors.textMuted : AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
            if (item.comingSoon) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warningBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Coming soon',
                  style: TextStyle(
                    color: AppColors.warningText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AttachItem {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;
  final bool comingSoon;

  const _AttachItem({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    this.comingSoon = false,
  });
}

class _SuggestionItem {
  final IconData icon;
  final String label;
  final String prompt;

  const _SuggestionItem({
    required this.icon,
    required this.label,
    required this.prompt,
  });
}