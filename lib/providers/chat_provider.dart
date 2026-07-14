import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../config/model_config.dart';
import '../services/identity_interceptor.dart';
import '../services/model_manager.dart';
import '../services/storage_service.dart';
import '../services/llm_service.dart';
import '../utils/debug_logger.dart';

enum ChatState { idle, loading }

int _messageIdCounter = 0;
String _nextId() => 'msg_${DateTime.now().millisecondsSinceEpoch}_${_messageIdCounter++}';

class ChatProvider extends ChangeNotifier {
  final StorageService _storage = StorageService();
  final ModelManager _modelManager = ModelManager();
  final DebugLogger _logger = DebugLogger();

  List<Message> _messages = [];
  ChatState _state = ChatState.idle;
  int _promptLogCount = 0;
  final int _maxPromptLogs = 3;

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
            : 'Model is not loaded. Go to Settings > Download Model to install it.';
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

      final fullResponse = buffer.toString();
      final sanitized = sanitizeGemmaHistory(fullResponse);
      _messages[_messages.length - 1] = Message(
        id: aiMsg.id,
        content: sanitized,
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
    final sanitized = sanitizeGemmaHistory(content);
    final msg = Message(
      id: _nextId(),
      content: sanitized,
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
    buffer.writeln('<bos>');
    buffer.writeln('<|turn>system');
    buffer.writeln('${ModelConfig.systemPrompt}<turn|>');
    buffer.writeln('<|turn>user');
    buffer.writeln('$userMessage<turn|>');
    buffer.writeln('<|turn>model');

    final prompt = buffer.toString();
    if (_promptLogCount < _maxPromptLogs) {
      debugPrint('[ChatProvider] Raw prompt #${_promptLogCount + 1}: $prompt');
      _logger.logPrompt(prompt);
      _promptLogCount++;
    }

    return prompt;
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

  /// Regenerates the last AI response
  Future<void> regenerateLastResponse() async {
    // Find the last user message
    int lastUserIndex = -1;
    for (int i = _messages.length - 1; i >= 0; i--) {
      if (_messages[i].isUser) {
        lastUserIndex = i;
        break;
      }
    }

    if (lastUserIndex == -1) return;

    final userMessage = _messages[lastUserIndex];
    
    // Remove all messages after the last user message
    _messages.removeRange(lastUserIndex + 1, _messages.length);
    
    // Re-send the message
    _state = ChatState.loading;
    notifyListeners();

    try {
      if (!_modelManager.isReady) {
        final lang = _storage.getLanguage();
        final msg = lang == 'fr'
            ? "Le modèle n'est pas chargé. Allez dans Paramètres > Télécharger le modèle pour l'installer."
            : 'Model is not loaded. Go to Settings > Download Model to install it.';
        _state = ChatState.idle;
        notifyListeners();
        await _addResponse(msg);
        return;
      }

      final prompt = _buildPrompt(userMessage.content, _messages);

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

      final fullResponse = buffer.toString();
      final sanitized = sanitizeGemmaHistory(fullResponse);
      _messages[_messages.length - 1] = Message(
        id: aiMsg.id,
        content: sanitized,
        isUser: false,
        timestamp: DateTime.now(),
        isStreaming: false,
      );
      await _storage.addMessage(_messages.last);
      notifyListeners();
    } catch (e) {
      debugPrint('[ChatProvider] Regenerate error: $e');
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

  /// Sends feedback (thumbs up/down) for a message
  void sendFeedback(int messageIndex, {required bool isPositive}) {
    // In a real app, this would send to analytics/backend
    debugPrint('[ChatProvider] Feedback for message $messageIndex: ${isPositive ? 'positive' : 'negative'}');
    // Could persist feedback locally or send to analytics
  }

  /// Cancels the current generation
  void cancelGeneration() {
    // The ModelManager's stream will be cancelled when we stop listening
    // For now, just set state to idle
    _state = ChatState.idle;
    notifyListeners();
  }
}