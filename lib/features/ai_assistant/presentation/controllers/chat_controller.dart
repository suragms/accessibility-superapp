import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/tts_service.dart';
import '../../data/repositories/history_repository.dart';
import '../../data/services/ai_stream_service.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/services/prompt_templates.dart';
import '../../domain/services/safety_layer.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool isStreaming;
  final PromptMode promptMode;
  final String targetLanguage;
  final bool speakOutEnabled;
  final String? errorMessage;

  const ChatState({
    required this.messages,
    required this.isStreaming,
    required this.promptMode,
    required this.targetLanguage,
    required this.speakOutEnabled,
    this.errorMessage,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isStreaming,
    PromptMode? promptMode,
    String? targetLanguage,
    bool? speakOutEnabled,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      promptMode: promptMode ?? this.promptMode,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      speakOutEnabled: speakOutEnabled ?? this.speakOutEnabled,
      errorMessage: errorMessage, // Reset if null
    );
  }
}

/// Controller driving conversation cycles, streaming responses, and safety scanning.
class ChatController extends StateNotifier<ChatState> {
  final AiStreamService streamService;
  final HistoryRepository historyRepository;
  final TtsService ttsService;

  StreamSubscription<String>? _streamSubscription;

  ChatController({
    required this.streamService,
    required this.historyRepository,
    required this.ttsService,
  }) : super(const ChatState(
          messages: [],
          isStreaming: false,
          promptMode: PromptMode.general,
          targetLanguage: 'Spanish',
          speakOutEnabled: false,
        )) {
    loadMessages();
  }

  /// Loads cached conversation threads.
  Future<void> loadMessages() async {
    final cached = await historyRepository.loadHistory();
    state = state.copyWith(messages: cached);
  }

  /// Modifies active prompt templates.
  void setPromptMode(PromptMode mode) {
    state = state.copyWith(promptMode: mode);
  }

  /// Modifies translation target language.
  void setTargetLanguage(String language) {
    state = state.copyWith(targetLanguage: language);
  }

  /// Toggles automatic response vocalization.
  void toggleSpeakOut(bool value) {
    state = state.copyWith(speakOutEnabled: value);
    if (!value) {
      ttsService.stop();
    }
  }

  /// Processes user inputs and initiates LLM stream pipelines.
  Future<void> sendMessage(String text, {bool isVoice = false}) async {
    if (text.trim().isEmpty) return;

    // 1. Add user message
    final userMsg = ChatMessage(
      id: const Uuid().v4(),
      role: MessageRole.user,
      text: text,
      timestamp: DateTime.now(),
      isVoice: isVoice,
    );

    state = state.copyWith(
      messages: [...state.messages, userMsg],
      errorMessage: null,
    );

    // 2. Scan content safety
    final safety = SafetyLayer.checkPrompt(text);

    if (!safety.isSafe) {
      final warnMsg = ChatMessage(
        id: const Uuid().v4(),
        role: MessageRole.assistant,
        text: safety.alertMessage ?? 'Safety violation warning.',
        timestamp: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, warnMsg]);
      await historyRepository.saveHistory(state.messages);
      return;
    }

    if (safety.isEmergency) {
      final emergencyMsg = ChatMessage(
        id: const Uuid().v4(),
        role: MessageRole.assistant,
        text: safety.alertMessage ?? 'Potential emergency detected. Trigger SOS?',
        timestamp: DateTime.now(),
      );
      state = state.copyWith(messages: [...state.messages, emergencyMsg]);
      await historyRepository.saveHistory(state.messages);
      if (state.speakOutEnabled) {
        await ttsService.speak(emergencyMsg.text);
      }
      return;
    }

    // 3. Initiate Streaming Responses
    final systemPrompt = PromptTemplates.getPrompt(
      state.promptMode,
      targetLanguage: state.targetLanguage,
    );

    final assistantMsgId = const Uuid().v4();
    final assistantPlaceholder = ChatMessage(
      id: assistantMsgId,
      role: MessageRole.assistant,
      text: '',
      timestamp: DateTime.now(),
    );

    state = state.copyWith(
      messages: [...state.messages, assistantPlaceholder],
      isStreaming: true,
    );

    StringBuffer streamAccumulator = StringBuffer();
    await _streamSubscription?.cancel();

    _streamSubscription = streamService
        .sendMessageStream(text, systemPrompt)
        .listen(
      (chunk) {
        streamAccumulator.write(chunk);
        
        // Update placeholder bubble text
        state = state.copyWith(
          messages: state.messages.map((m) {
            if (m.id == assistantMsgId) {
              return ChatMessage(
                id: m.id,
                role: m.role,
                text: streamAccumulator.toString(),
                timestamp: m.timestamp,
              );
            }
            return m;
          }).toList(),
        );
      },
      onError: (err) {
        state = state.copyWith(
          isStreaming: false,
          errorMessage: 'Failed to process AI stream: ${err.toString()}',
        );
      },
      onDone: () async {
        state = state.copyWith(isStreaming: false);
        await historyRepository.saveHistory(state.messages);
        
        // Speak out completion if enabled
        if (state.speakOutEnabled) {
          final finalText = streamAccumulator.toString();
          await ttsService.speak(finalText);
        }
      },
    );
  }

  /// Clears logs.
  Future<void> clearHistory() async {
    await historyRepository.clearHistory();
    await _streamSubscription?.cancel();
    state = state.copyWith(
      messages: [],
      isStreaming: false,
      errorMessage: null,
    );
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }
}

// Global repositories definitions for providers
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository();
});

final aiStreamServiceProvider = Provider<AiStreamService>((ref) {
  return AiStreamService();
});

/// Riverpod provider for ChatController.
final chatControllerProvider =
    StateNotifierProvider<ChatController, ChatState>((ref) {
  final stream = ref.watch(aiStreamServiceProvider);
  final repo = ref.watch(historyRepositoryProvider);
  final tts = ref.watch(ttsServiceProvider);
  return ChatController(
    streamService: stream,
    historyRepository: repo,
    ttsService: tts,
  );
});
