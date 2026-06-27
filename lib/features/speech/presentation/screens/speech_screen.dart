import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/accessibility/widgets/accessible_focus_group.dart';
import '../../../../core/accessibility/widgets/accessible_focus_ring.dart';
import '../../../../core/accessibility/widgets/semantic_container.dart';
import '../../../../core/theme/accessibility_tokens.dart';
import '../../../../core/widgets/accessible_button.dart';
import '../../../../core/widgets/accessible_card.dart';
import '../../domain/models/speech_config.dart';
import '../controllers/speech_controller.dart';

/// An Accessibility-First Screen supporting continuous Live Captioning overlay,
/// TTS pitch/speed customization, noise reduction parameters, and text exports.
class SpeechScreen extends ConsumerStatefulWidget {
  const SpeechScreen({super.key});

  @override
  ConsumerState<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends ConsumerState<SpeechScreen> {
  final ScrollController _scrollController = ScrollController();
  final FocusNode _micFocusNode = FocusNode();
  final FocusNode _rateFocusNode = FocusNode();
  final FocusNode _pitchFocusNode = FocusNode();

  @override
  void dispose() {
    _scrollController.dispose();
    _micFocusNode.dispose();
    _rateFocusNode.dispose();
    _pitchFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 50,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AccessibilityTokens.of(context);
    final theme = Theme.of(context);
    
    final speechState = ref.watch(speechControllerProvider);
    final isListening = speechState.isListening;
    final config = speechState.config;

    // Listen to changes in transcripts to scroll down automatically
    ref.listen(speechControllerProvider, (prev, next) {
      if (prev?.captionLines.length != next.captionLines.length) {
        Future.delayed(const Duration(milliseconds: 50), _scrollToBottom);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Captions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            tooltip: 'Clear captions buffer',
            onPressed: () {
              ref.read(speechControllerProvider.notifier).clearCaptions();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Live Caption Display Box
              Semantics(
                label: 'Transcribed Live Captions text window.',
                child: AccessibleCard(
                  child: Container(
                    height: 250,
                    width: double.infinity,
                    color: theme.colorScheme.background,
                    padding: EdgeInsets.all(tokens.spaceSmall),
                    child: speechState.captionLines.isEmpty
                        ? Center(
                            child: Text(
                              'Click "Start Captions" to transcribe incoming speech in real-time.',
                              style: theme.textTheme.bodyLarge!.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            itemCount: speechState.captionLines.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  speechState.captionLines[index],
                                  style: theme.textTheme.displaySmall!.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ),
              SizedBox(height: tokens.spaceMedium),

              // 2. Microphone Trigger
              AccessibleFocusRing(
                focusNode: _micFocusNode,
                child: AccessibleButton(
                  style: isListening ? AccessibleButtonStyle.filled : AccessibleButtonStyle.outlined,
                  onPressed: () {
                    ref.read(speechControllerProvider.notifier).toggleCaptionMode();
                  },
                  semanticLabel: isListening ? 'Stop continuous live captioning.' : 'Start continuous live captioning.',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isListening ? Icons.stop : Icons.play_arrow),
                        SizedBox(width: tokens.spaceSmall),
                        Text(isListening ? 'STOP CAPTIONS' : 'START CAPTIONS'),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: tokens.spaceLarge),

              const Divider(),
              SizedBox(height: tokens.spaceSmall),

              // 3. Configurations Grid (Focus group)
              AccessibleFocusGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Voice Synthesizer Settings',
                      style: theme.textTheme.titleLarge,
                    ),
                    SizedBox(height: tokens.spaceMedium),

                    // Language Locale selection
                    DropdownButtonFormField<String>(
                      value: config.localeCode,
                      decoration: const InputDecoration(
                        labelText: 'Speech Language',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'en-US', child: Text('English (US)')),
                        DropdownMenuItem(value: 'hi-IN', child: Text('Hindi (हिन्दी)')),
                        DropdownMenuItem(value: 'ml-IN', child: Text('Malayalam (മലയാളം)')),
                        DropdownMenuItem(value: 'ta-IN', child: Text('Tamil (தமிழ்)')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(speechControllerProvider.notifier).updateLocale(value);
                        }
                      },
                    ),
                    SizedBox(height: tokens.spaceMedium),

                    // Speech Rate Slider
                    Semantics(
                      label: 'Adjust speech speaking speed rate.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Speech Rate: ${config.speechRate.toStringAsFixed(2)}x'),
                          AccessibleFocusRing(
                            focusNode: _rateFocusNode,
                            child: Slider(
                              focusNode: _rateFocusNode,
                              value: config.speechRate,
                              min: 0.25,
                              max: 1.0,
                              onChanged: (val) {
                                ref.read(speechControllerProvider.notifier).updateSpeechRate(val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: tokens.spaceMedium),

                    // Pitch Slider
                    Semantics(
                      label: 'Adjust voice pitch.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Voice Pitch: ${config.pitch.toStringAsFixed(2)}'),
                          AccessibleFocusRing(
                            focusNode: _pitchFocusNode,
                            child: Slider(
                              focusNode: _pitchFocusNode,
                              value: config.pitch,
                              min: 0.5,
                              max: 1.5,
                              onChanged: (val) {
                                ref.read(speechControllerProvider.notifier).updatePitch(val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: tokens.spaceMedium),

                    // Voice Gender Toggle
                    DropdownButtonFormField<VoiceGender>(
                      value: config.voiceGender,
                      decoration: const InputDecoration(
                        labelText: 'Voice Synthesizer Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: VoiceGender.values.map((g) {
                        return DropdownMenuItem<VoiceGender>(
                          value: g,
                          child: Text(g.name.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            // Local updates
                          });
                        }
                      },
                    ),
                    SizedBox(height: tokens.spaceMedium),

                    // Noise reduction toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Enable Noise Reduction',
                          style: theme.textTheme.bodyLarge,
                        ),
                        Switch(
                          value: config.noiseReductionEnabled,
                          onChanged: (val) {
                            ref.read(speechControllerProvider.notifier).toggleNoiseReduction(val);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: tokens.spaceLarge),

              const Divider(),
              SizedBox(height: tokens.spaceSmall),

              // 4. Export section
              AccessibleButton(
                style: AccessibleButtonStyle.filled,
                onPressed: speechState.captionLines.isEmpty
                    ? null
                    : () {
                        ref.read(speechControllerProvider.notifier).exportTranscript();
                      },
                semanticLabel: 'Export current captions session to text file.',
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Text('EXPORT SESSION TRANSCRIPT'),
                ),
              ),

              if (speechState.exportPath != null) ...[
                SizedBox(height: tokens.spaceMedium),
                SemanticContainer(
                  isLiveRegion: true,
                  child: Text(
                    'Transcript exported to: ${speechState.exportPath}',
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
