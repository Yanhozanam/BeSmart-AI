import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../config/model_config.dart';
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
        _state = ChatState.idle;
        notifyListeners();
        await _addResponse(responseText);
        return;
      }

      if (!_modelManager.isReady) {
        final lang = _storage.getLanguage();
        final msg = lang == 'fr'
            ? "Le modèle n'est pas chargé. Allez dans Paramètres > Télécharger le modèle pour l'installer."
            :             'Model is not loaded. Go to Settings > Download Model to install it.';
        _state = ChatState.idle;
        notifyListeners();
        await _addResponse(msg);
        return;
      }

      final prompt = _buildPrompt(input, _messages);

      final aiMsg = Message(
        id: _nextId(),
        content: '',
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: true,
      );
      _messages.add(aiMsg);
      _state = ChatState.idle;
      notifyListeners();

      final buffer = StringBuffer();

      final stream = _modelManager.generateStream(prompt);
      final timeoutStream = stream.timeout(
        const Duration(seconds: 120),
        onTimeout: (sink) {
          sink.addError(TimeoutException('Inference timed out'));
          sink.close();
        },
      );

      await for (final token in timeoutStream) {
        buffer.write(token);
        _messages[_messages.length - 1] = Message(
          id: aiMsg.id,
          content: buffer.toString(),
          isUser: false,
          timestamp: DateTime.now(),
          isStreaming: true,
        );
        notifyListeners();
      }

      _messages[_messages.length - 1] = Message(
        id: aiMsg.id,
        content: buffer.toString(),
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: false,
      );
      await _storage.addMessage(_messages.last);
      notifyListeners();
    } catch (e) {
      debugPrint('[ChatProvider] Error: $e');
      _state = ChatState.idle;
      notifyListeners();
      final lang = _storage.getLanguage();
      String errMsg;
      if (e is TimeoutException) {
        errMsg = lang == 'fr'
            ? "Cela prend plus de temps que prévu. Essayez une question plus courte."
            : 'This is taking longer than expected. Try a shorter question.';
      } else {
        errMsg = lang == 'fr'
            ? "Désolé, quelque chose s'est mal passé. Veuillez réessayer."
            : 'Sorry, something went wrong. Please try again.';
      }
      await _addResponse(errMsg);
    }
  }

  Future<void> _addResponse(String content) async {
    final msg = Message(
      id: _nextId(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      isStreaming: false,
    );
    _messages.add(msg);
    await _storage.addMessage(msg);
    notifyListeners();
  }

  String _buildPrompt(String userMessage, List<Message> history) {
    final buffer = StringBuffer();
    buffer.writeln('<|im_start|>system');
    buffer.writeln('${ModelConfig.systemPrompt}<|im_end|>');

    final context = history.length > 1 ? history.sublist(0, history.length - 1) : <Message>[];
    for (final msg in context.reversed.take(2).toList().reversed) {
      if (msg.isUser || (!msg.isUser && !msg.isStreaming)) {
        final role = msg.isUser ? 'user' : 'assistant';
        buffer.writeln('<|im_start|>$role');
        buffer.writeln('${msg.content}<|im_end|>');
      }
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
