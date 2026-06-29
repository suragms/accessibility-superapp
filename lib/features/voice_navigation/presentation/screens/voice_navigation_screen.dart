import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/accessibility/widgets/accessible_focus_ring.dart';
import '../../../../core/accessibility/widgets/semantic_container.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/accessibility_tokens.dart';
import '../../../../core/widgets/accessible_button.dart';
import '../../../../core/widgets/accessible_card.dart';
import '../../domain/command_intent.dart';
import '../controllers/voice_navigation_controller.dart';

/// An Accessibility-First Voice Navigation Interface.
/// Key Features:
/// 1. Radial pulsing visualization during speech listening.
/// 2. liveRegion semantics for real-time state changes readouts.
/// 3. GoRouter integration reacting to parsed navigation intents.
class VoiceNavigationScreen extends ConsumerStatefulWidget {
  const VoiceNavigationScreen({super.key});

  @override
  ConsumerState<VoiceNavigationScreen> createState() => _VoiceNavigationScreenState();
}

class _VoiceNavigationScreenState extends ConsumerState<VoiceNavigationScreen> {
  final FocusNode _micFocusNode = FocusNode();

  @override
  void dispose() {
    _micFocusNode.dispose();
    // Safety check: ensure speech listener is turned off when leaving the screen
    Future.microtask(() {
      if (mounted) {
        ref.read(voiceNavigationControllerProvider.notifier).stopListening();
      }
    });
    super.dispose();
  }

  String _getStatusText(VoiceNavigationState state) {
    if (state.errorMessage != null) {
      return 'Error: ${state.errorMessage}';
    }
    if (state.isProcessing) {
      return 'Processing command...';
    }
    if (state.isListening) {
      if (state.wakeWordActive) {
        return 'Wake word detected!\nSpeak your command now.';
      } else {
        return 'Listening...\nSay "Assistant" to begin.';
      }
    }
    return 'Voice navigation is idle.';
  }

  String _getSemanticStatusText(VoiceNavigationState state) {
    if (state.errorMessage != null) {
      return 'Voice navigation error: ${state.errorMessage}';
    }
    if (state.isProcessing) {
      return 'Processing command.';
    }
    if (state.isListening) {
      if (state.wakeWordActive) {
        return 'Wake word detected. Speak your navigation command now.';
      } else {
        return 'Listening. Say assistant followed by a command.';
      }
    }
    return 'Voice navigation is idle. Tap the button to start.';
  }

  Color _getStatusColor(BuildContext context, VoiceNavigationState state) {
    final theme = Theme.of(context);
    if (state.errorMessage != null) {
      return theme.colorScheme.error;
    }
    if (state.isProcessing) {
      return theme.colorScheme.secondary;
    }
    if (state.isListening) {
      return state.wakeWordActive ? Colors.green : theme.colorScheme.primary;
    }
    return theme.disabledColor;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AccessibilityTokens.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(voiceNavigationControllerProvider);
    final isListening = state.isListening;

    // Set up router listener to navigate on pending intents
    ref.listen<VoiceNavigationState>(voiceNavigationControllerProvider, (previous, next) {
      final pending = next.pendingNavigation;
      if (pending != null) {
        // Clear pending navigation intent in state first
        ref.read(voiceNavigationControllerProvider.notifier).clearPendingNavigation();

        switch (pending) {
          case CommandIntent.home:
            context.goNamed(RouteNames.home);
            break;
          case CommandIntent.aiAssistant:
            context.goNamed(RouteNames.aiAssistant);
            break;
          case CommandIntent.speechToText:
            context.goNamed(RouteNames.speechToText);
            break;
          case CommandIntent.medications:
            context.goNamed(RouteNames.medicationList);
            break;
          case CommandIntent.caregiver:
            context.goNamed(RouteNames.caregiver);
            break;
          case CommandIntent.settings:
            context.goNamed(RouteNames.settings);
            break;
          case CommandIntent.sos:
            context.goNamed(RouteNames.sos);
            break;
          case CommandIntent.goBack:
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(RouteNames.home);
            }
            break;
          case CommandIntent.unknown:
            break;
        }
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Voice Navigation'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, size: 28),
          tooltip: 'Close voice navigation',
          onPressed: () {
            ref.read(voiceNavigationControllerProvider.notifier).stopListening();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: tokens.spaceLarge),
              
              // 1. Pulsing Mic visualization
              Center(
                child: _PulsingMicRing(
                  isListening: isListening,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isListening ? theme.colorScheme.primary : theme.colorScheme.surface,
                      border: Border.all(
                        color: theme.colorScheme.primary,
                        width: tokens.borderThicknessBold,
                      ),
                    ),
                    child: AccessibleFocusRing(
                      focusNode: _micFocusNode,
                      child: AccessibleButton(
                        style: isListening ? AccessibleButtonStyle.filled : AccessibleButtonStyle.outlined,
                        onPressed: () {
                          if (isListening) {
                            ref.read(voiceNavigationControllerProvider.notifier).stopListening();
                          } else {
                            ref.read(voiceNavigationControllerProvider.notifier).startListening();
                          }
                        },
                        semanticLabel: isListening 
                            ? 'Stop voice navigation microphone.' 
                            : 'Start voice navigation microphone.',
                        semanticHint: 'Activate microphone to input voice command.',
                        child: Icon(
                          isListening ? Icons.stop : Icons.mic,
                          size: 48,
                          color: isListening ? theme.colorScheme.onPrimary : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: tokens.spaceXXLarge),

              // 2. Real-time Status announcements (live region)
              SemanticContainer(
                isLiveRegion: true,
                label: _getSemanticStatusText(state),
                child: Container(
                  padding: EdgeInsets.all(tokens.spaceMedium),
                  decoration: BoxDecoration(
                    color: _getStatusColor(context, state).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(tokens.cardCornerRadius),
                    border: Border.all(
                      color: _getStatusColor(context, state),
                      width: tokens.borderThicknessNormal,
                    ),
                  ),
                  child: Text(
                    _getStatusText(state),
                    style: theme.textTheme.headlineSmall!.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(context, state),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              SizedBox(height: tokens.spaceXLarge),

              // 3. User feedback display cards for sight assistance
              AccessibleCard(
                semanticLabel: 'Command recognition details.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Last Spoken Phrase',
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: tokens.spaceXSmall),
                    Text(
                      state.lastCommand.isEmpty ? '(Waiting for input...)' : '"${state.lastCommand}"',
                      style: theme.textTheme.bodyLarge!.copyWith(
                        fontStyle: state.lastCommand.isEmpty ? FontStyle.italic : FontStyle.normal,
                      ),
                    ),
                    const Divider(height: 32),
                    Text(
                      'Recognized Navigation Intent',
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: tokens.spaceXSmall),
                    Text(
                      state.lastIntent == CommandIntent.unknown && state.lastCommand.isEmpty
                          ? '(None)'
                          : state.lastIntent.name.toUpperCase(),
                      style: theme.textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: state.lastIntent == CommandIntent.unknown && state.lastCommand.isNotEmpty
                            ? theme.colorScheme.error
                            : theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: tokens.spaceMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// A smooth expanding radial animation matching mic states.
class _PulsingMicRing extends StatefulWidget {
  final bool isListening;
  final Widget child;

  const _PulsingMicRing({
    required this.isListening,
    required this.child,
  });

  @override
  State<_PulsingMicRing> createState() => _PulsingMicRingState();
}

class _PulsingMicRingState extends State<_PulsingMicRing> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isListening) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(_PulsingMicRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isListening && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isListening && _controller.isAnimating) {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isListening) ...[
              Container(
                width: 120 + (50 * _controller.value),
                height: 120 + (50 * _controller.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity((1.0 - _controller.value) * 0.35),
                ),
              ),
              Container(
                width: 120 + (100 * _controller.value),
                height: 120 + (100 * _controller.value),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withOpacity((1.0 - _controller.value) * 0.15),
                ),
              ),
            ],
            widget.child,
          ],
        );
      },
    );
  }
}
