import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  @override
  void initState() {
    super.initState();
    _provider = context.read<ChatProvider>();
    _provider.addListener(_onProviderChange);
  }

  @override
  void dispose() {
    _provider.removeListener(_onProviderChange);
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onProviderChange() {
    if (_provider.messages.isNotEmpty) {
      _scrollToBottom();
    }
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
                    : 'Download the AI model (1.04 GB) to get real AI responses. Works fully offline after download.',
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
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
        title: const Text(
          'BeSmartAI',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_comment_outlined),
            onPressed: _onNewChat,
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
                          isError ? Icons.error_outline : Icons.cloud_download,
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
                          Icons.chevron_right,
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
                        'Downloading model... ${(modelProvider.currentModel.progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: AppColors.downloadingText,
                          fontSize: 13,
                        ),
                      ),
                    ],
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
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(top: 8, bottom: 8),
                  itemCount: messages.length + (provider.state == ChatState.loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index < messages.length) {
                      return MessageBubble(message: messages[index]);
                    }
                    return Column(
                      children: [
                        const TypingIndicator(),
                        Padding(
                          padding: const EdgeInsets.only(left: 56, top: 4, bottom: 4),
                          child: Text(
                            'BeSmartAI is thinking... (this may take 30-60 seconds)',
                            style: TextStyle(
                              color: AppColors.textSecondary.withOpacity(0.6),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
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
          const SizedBox(height: 60),
          Text(
            _getGreeting(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'How can I help you study today?',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          _buildSuggestionCards(),
        ],
      ),
    );
  }

  Widget _buildSuggestionCards() {
    final suggestions = [
      _SuggestionItem(
        icon: Icons.lightbulb_outline,
        label: 'Explain a concept',
        prompt: 'Explain the concept of ',
      ),
      _SuggestionItem(
        icon: Icons.summarize_outlined,
        label: 'Summarize this text',
        prompt: 'Summarize the following: ',
      ),
      _SuggestionItem(
        icon: Icons.quiz_outlined,
        label: 'Quiz me on a topic',
        prompt: 'Quiz me on the topic of ',
      ),
      _SuggestionItem(
        icon: Icons.edit_note,
        label: 'Help me write an essay',
        prompt: 'Help me write an essay about ',
      ),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: suggestions.map((s) => _buildSuggestionCard(s)).toList(),
    );
  }

  Widget _buildSuggestionCard(_SuggestionItem item) {
    final cardWidth = (MediaQuery.of(context).size.width - 60) / 2;
    return GestureDetector(
      onTap: () => _onSuggestionTap(item.prompt),
      child: Container(
        width: cardWidth,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryDim,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.15),
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
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.textFieldFill,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.add,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {},
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    enabled: !isLoading,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _onSend(),
                    decoration: InputDecoration(
                      hintText: isLoading ? 'BeSmartAI is thinking...' : 'Ask anything...',
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
                const SizedBox(width: 4),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _controller.text.isEmpty
                        ? AppColors.disabledButton
                        : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_upward,
                      color: Colors.white,
                      size: 20,
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
