import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/accessibility/widgets/accessible_focus_group.dart';
import '../../../../core/accessibility/widgets/accessible_focus_ring.dart';
import '../../../../core/accessibility/widgets/semantic_container.dart';
import '../../../../core/services/speech_service.dart';
import '../../../../core/theme/accessibility_tokens.dart';
import '../../../../core/widgets/accessible_button.dart';
import '../../../../core/widgets/accessible_card.dart';
import '../../../../core/widgets/accessible_text_field.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/services/prompt_templates.dart';
import '../controllers/chat_controller.dart';

/// An Accessibility-First Conversational UI for the AI Assistant.
/// Key Features:
/// 1. Dropdowns to adjust templates contexts (Translation, Summarization, Planner).
/// 2. Merges bubble message content to simplify screen-reader announcement.
/// 3. Standardizes text-to-speech switches and voice voice typing controls.
class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  final FocusNode _micFocusNode = FocusNode();
  
  bool _isListening = false;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    _micFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleMicListening() async {
    final speechService = ref.read(speechServiceProvider);

    if (_isListening) {
      await speechService.stopListening();
      setState(() {
        _isListening = false;
      });
      return;
    }

    setState(() {
      _isListening = true;
    });

    await speechService.startListening(
      onResult: (words) {
        setState(() {
          _textController.text = words;
          _isListening = false;
        });
      },
      onError: (err) {
        setState(() {
          _isListening = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech error: $err')),
        );
      },
    );
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatControllerProvider.notifier).sendMessage(text);
    _textController.clear();
    FocusScope.of(context).unfocus();
    
    // Auto-scroll after a short frame delay
    Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AccessibilityTokens.of(context);
    final theme = Theme.of(context);
    
    final chatState = ref.watch(chatControllerProvider);
    final isStreaming = chatState.isStreaming;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear conversation history',
            onPressed: () {
              ref.read(chatControllerProvider.notifier).clearHistory();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Prompt settings configuration bar
            Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceMedium, vertical: tokens.spaceSmall),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<PromptMode>(
                      value: chatState.promptMode,
                      decoration: const InputDecoration(
                        labelText: 'Assistant Mode',
                        border: OutlineInputBorder(),
                      ),
                      items: PromptMode.values.map((mode) {
                        return DropdownMenuItem<PromptMode>(
                          value: mode,
                          child: Text(mode.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(chatControllerProvider.notifier).setPromptMode(value);
                        }
                      },
                    ),
                  ),
                  if (chatState.promptMode == PromptMode.translation) ...[
                    SizedBox(width: tokens.spaceSmall),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: chatState.targetLanguage,
                        decoration: const InputDecoration(
                          labelText: 'Translate To',
                          border: OutlineInputBorder(),
                        ),
                        items: const ['Spanish', 'Hindi', 'Malayalam', 'French', 'Tamil']
                            .map((lang) {
                          return DropdownMenuItem<String>(
                            value: lang,
                            child: Text(lang),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            ref.read(chatControllerProvider.notifier).setTargetLanguage(value);
                          }
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Speak Out switch configuration row
            Padding(
              padding: EdgeInsets.symmetric(horizontal: tokens.spaceMedium),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Speak Out Assistant Responses',
                    style: theme.textTheme.bodyMedium,
                  ),
                  Switch(
                    value: chatState.speakOutEnabled,
                    onChanged: (value) {
                      ref.read(chatControllerProvider.notifier).toggleSpeakOut(value);
                    },
                  ),
                ],
              ),
            ),

            const Divider(),

            // Chat conversation messages scrollport
            Expanded(
              child: chatState.messages.isEmpty
                  ? Center(
                      child: Text(
                        'Start a conversation. Try asking "Translate hello" or "Plan my tasks".',
                        style: theme.textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(tokens.spaceMedium),
                      itemCount: chatState.messages.length,
                      itemBuilder: (context, index) {
                        final msg = chatState.messages[index];
                        final isUser = msg.role == MessageRole.user;

                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: SemanticContainer(
                              mergeSemantics: true,
                              label: '${isUser ? 'You said' : 'Assistant said'}: ${msg.text}',
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                                ),
                                child: AccessibleCard(
                                  child: Container(
                                    padding: EdgeInsets.all(tokens.spaceSmall),
                                    child: Text(
                                      msg.text,
                                      style: theme.textTheme.bodyLarge!.copyWith(
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),

            if (isStreaming)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.spaceMedium, vertical: tokens.spaceSmall),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: tokens.spaceSmall),
                    Text(
                      'Assistant is typing...',
                      style: theme.textTheme.bodySmall!.copyWith(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),

            // Input panel section
            AccessibleFocusGroup(
              child: Padding(
                padding: EdgeInsets.all(tokens.spaceMedium),
                child: Row(
                  children: [
                    Expanded(
                      child: AccessibleFocusRing(
                        focusNode: _inputFocusNode,
                        child: AccessibleTextField(
                          controller: _textController,
                          focusNode: _inputFocusNode,
                          label: 'Message AI Assistant',
                          hintText: 'Type or use microphone...',
                        ),
                      ),
                    ),
                    SizedBox(width: tokens.spaceSmall),
                    // Voice Mic input button
                    AccessibleFocusRing(
                      focusNode: _micFocusNode,
                      child: AccessibleButton(
                        style: AccessibleButtonStyle.text,
                        onPressed: _handleMicListening,
                        semanticLabel: _isListening
                            ? 'Listening. Click to stop recording.'
                            : 'Voice typing. Click to record speech.',
                        child: Icon(
                          _isListening ? Icons.mic_off : Icons.mic,
                          color: _isListening ? theme.colorScheme.error : theme.colorScheme.primary,
                          size: 28,
                        ),
                      ),
                    ),
                    SizedBox(width: tokens.spaceSmall),
                    // Send message button
                    AccessibleButton(
                      style: AccessibleButtonStyle.filled,
                      onPressed: _sendMessage,
                      semanticLabel: 'Send message',
                      child: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
