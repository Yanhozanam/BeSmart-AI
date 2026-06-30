import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../services/identity_interceptor.dart';
import '../services/model_manager.dart';
import '../services/storage_service.dart';

enum ChatState { idle, loading }

int _messageIdCounter = 0;
String _nextId() => 'msg_${DateTime.now().millisecondsSinceEpoch}_${_messageIdCounter++}';

class ChatProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final ModelManager _modelManager = ModelManager();

  List<Message> _messages = [];
  ChatState _state = ChatState.idle;

  List<Message> get messages => _messages;
  ChatState get state => _state;

  ChatProvider() {
    _loadMessages();
  }

  void _loadMessages() {
    _messages = _storage.getMessages();
    notifyListeners();
  }

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    final input = content.trim();

    final userMsg = Message(
      id: _nextId(),
      content: input,
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMsg);
    await _storage.addMessage(userMsg);
    _state = ChatState.loading;
    notifyListeners();

    try {
      final identityKey = IdentityInterceptor().intercept(input);
      if (identityKey != null) {
        final responseText = _resolveResponse(identityKey);
        await _addResponse(responseText);
        _state = ChatState.idle;
        notifyListeners();
        return;
      }

      final String result;
      if (_modelManager.isReady) {
        final prompt = _buildPrompt(input, _messages);
        result = await _modelManager.generateResponse(prompt);
      } else {
        final responseKey = await _modelManager.generateResponse(input);
        result = _resolveResponse(responseKey);
      }

      await _addResponse(result);
    } catch (e) {
      await _addResponse('Sorry, something went wrong. Please try again.');
    }

    _state = ChatState.idle;
    notifyListeners();
  }

  Future<void> _addResponse(String content) async {
    final msg = Message(
      id: _nextId(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
    );
    _messages.add(msg);
    await _storage.addMessage(msg);
  }

  String _buildPrompt(String userMessage, List<Message> history) {
    final buffer = StringBuffer();
    buffer.writeln('<|im_start|>system');
    buffer.writeln('You are BeSmartAI, a helpful offline study assistant for university students. Be concise, clear, and helpful.<|im_end|>');

    final context = history.length > 1 ? history.sublist(0, history.length - 1) : <Message>[];
    for (final msg in context.reversed.take(10).toList().reversed) {
      final role = msg.isUser ? 'user' : 'assistant';
      buffer.writeln('<|im_start|>$role');
      buffer.writeln('${msg.content}<|im_end|>');
    }

    buffer.writeln('<|im_start|>user');
    buffer.writeln('$userMessage<|im_end|>');
    buffer.writeln('<|im_start|>assistant');
    return buffer.toString();
  }

  String _resolveResponse(String key) {
    switch (key) {
      case 'pocketIdentity':
        final lang = _storage.getLanguage();
        return lang == 'fr'
            ? "Je suis BeSmartAI, votre compagnon d'étude hors ligne conçu pour les étudiants."
            : "I'm BeSmartAI, your offline study companion built for students.";
      case 'biuIdentity':
        final lang = _storage.getLanguage();
        return lang == 'fr'
            ? 'J\'ai été créé par Hozanam, un développeur du Burundi.'
            : 'I was created by Hozanam, a developer from Burundi.';
      case 'notChatGPT':
        final lang = _storage.getLanguage();
        return lang == 'fr'
            ? 'Non, je suis BeSmartAI — un assistant hors ligne conçu pour les étudiants.'
            : "No, I'm BeSmartAI — an offline assistant designed for students.";
      case 'mockResponse':
        final lang = _storage.getLanguage();
        return lang == 'fr'
            ? "C'est une excellente question ! En tant que BeSmartAI, je suis là pour vous aider dans vos études. Je peux vous aider avec des explications, des résumés et des conseils d'étude. Sur quelle matière travaillez-vous ?"
            : "That's a great question! As BeSmartAI, I'm here to help you with your studies. I can assist with explanations, summaries, and study tips. What subject are you working on?";
      default:
        return key;
    }
  }

  Future<void> clearChat() async {
    _messages.clear();
    await _storage.clearMessages();
    notifyListeners();
  }
}
