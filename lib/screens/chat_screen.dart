import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/model_provider.dart';
import '../services/model_service.dart';
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

  void _showModelOptions(BuildContext context, bool isError) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F2C33),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isError ? 'Model Error' : 'Model Not Downloaded',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isError
                    ? 'The AI model failed to load. Try reloading or re-downloading it.'
                    : 'Download the AI model (1.04 GB) to get real AI responses. Works fully offline after download.',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
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
                    backgroundColor: const Color(0xFF00A884),
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
                    side: BorderSide(color: Colors.white.withOpacity(0.3)),
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
      appBar: AppBar(
        title: Consumer<ModelProvider>(
          builder: (context, modelProvider, _) {
            final ready = modelProvider.isReady;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFF00A884),
                  child: Icon(Icons.auto_awesome, size: 18, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('BeSmartAI', style: TextStyle(fontSize: 16)),
                    Text(
                      ready ? 'ready' : 'offline',
                      style: TextStyle(
                        fontSize: 12,
                        color: ready ? Colors.green : Colors.white70,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        backgroundColor: const Color(0xFF1F2C33),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xFF111B21),
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
                    color: isError ? const Color(0xFF5C2E2E) : const Color(0xFF2E3A2E),
                    child: Row(
                      children: [
                        Icon(
                          isError ? Icons.error_outline : Icons.cloud_download,
                          color: isError ? Colors.redAccent : Colors.orangeAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isError
                                ? 'Model error — tap to fix'
                                : 'Model not downloaded — tap to download',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5), size: 18),
                      ],
                    ),
                  ),
                );
              }
              if (modelProvider.currentModel.status == ModelStatus.downloading) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  color: const Color(0xFF1A3A2A),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00A884)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Downloading model... ${(modelProvider.currentModel.progress * 100).toStringAsFixed(0)}%',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
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
                  return _buildEmptyState();
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
                              color: Colors.white.withOpacity(0.4),
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 64,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation with BeSmartAI',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.state == ChatState.loading;
        return Container(
          color: const Color(0xFF1F2C33),
          padding: EdgeInsets.only(
            left: 12,
            right: 8,
            top: 8,
            bottom: MediaQuery.of(context).padding.bottom + 8,
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A3942),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _controller,
                    enabled: !isLoading,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _onSend(),
                    decoration: InputDecoration(
                      hintText: isLoading ? 'BeSmartAI is thinking...' : 'Ask anything...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.send,
                  color: isLoading ? Colors.white24 : const Color(0xFF00A884),
                ),
                onPressed: isLoading ? null : _onSend,
              ),
            ],
          ),
        );
      },
    );
  }
}
