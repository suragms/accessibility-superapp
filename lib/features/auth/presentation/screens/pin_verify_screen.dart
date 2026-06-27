import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/accessibility_tokens.dart';
import '../../../../core/widgets/accessible_button.dart';
import '../controllers/auth_notifier.dart';

/// An Accessibility-First PIN Verification Screen.
/// Key Features:
/// 1. Custom large numeric keypads (min 48dp) suitable for motor/sighted difficulties.
/// 2. Implements high contrast empty/filled circle indicators showing code progress.
/// 3. Standardizes haptic confirmations upon number entry and triggers auto-submission.
class PinVerifyScreen extends ConsumerStatefulWidget {
  const PinVerifyScreen({super.key});

  @override
  ConsumerState<PinVerifyScreen> createState() => _PinVerifyScreenState();
}

class _PinVerifyScreenState extends ConsumerState<PinVerifyScreen> {
  final List<int> _enteredPin = [];
  static const int _pinLength = 4;

  void _onKeyPress(int number) {
    if (_enteredPin.length >= _pinLength) return;

    HapticFeedback.lightImpact();

    setState(() {
      _enteredPin.add(number);
    });

    if (_enteredPin.length == _pinLength) {
      _submitPin();
    }
  }

  void _onBackspace() {
    if (_enteredPin.isEmpty) return;
    
    HapticFeedback.mediumImpact();

    setState(() {
      _enteredPin.removeLast();
    });
  }

  void _submitPin() {
    final pinStr = _enteredPin.join();
    ref.read(authNotifierProvider.notifier).loginWithPin(pinStr);
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AccessibilityTokens.of(context);
    final theme = Theme.of(context);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is Authenticated) {
        context.goNamed(RouteNames.home);
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              label: 'PIN error: ${next.errorMessage}',
              child: Text(next.errorMessage),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
        setState(() {
          _enteredPin.clear(); // Reset upon validation error
        });
      }
    });

    final state = ref.watch(authNotifierProvider);
    final isLoading = state is AuthLoading;

    // Helper builder for Keypad Buttons
    Widget buildKeypadButton(String label, VoidCallback? onPressed, {String? semanticLabel}) {
      return Semantics(
        button: true,
        label: semanticLabel ?? 'Number key $label',
        child: AccessibleButton(
          style: AccessibleButtonStyle.outlined,
          onPressed: onPressed,
          child: Text(
            label,
            style: theme.textTheme.displayMedium!.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Enter PIN'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Semantics(
                header: true,
                child: Text(
                  'Enter Security PIN',
                  style: theme.textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: tokens.spaceSmall),
              Text(
                'Please enter your 4-digit security code.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: tokens.spaceXLarge),

              // PIN Entry Progress Dot Indicators
              Semantics(
                label: 'PIN input progress: ${_enteredPin.length} of $_pinLength digits entered.',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pinLength, (index) {
                    final isFilled = index < _enteredPin.length;
                    return Container(
                      width: 24,
                      height: 24,
                      margin: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFilled ? theme.colorScheme.primary : Colors.transparent,
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: tokens.borderThicknessBold,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const Spacer(),

              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                // Large contrast Keypad Grid
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(child: buildKeypadButton('1', () => _onKeyPress(1))),
                        SizedBox(width: tokens.spaceSmall),
                        Expanded(child: buildKeypadButton('2', () => _onKeyPress(2))),
                        SizedBox(width: tokens.spaceSmall),
                        Expanded(child: buildKeypadButton('3', () => _onKeyPress(3))),
                      ],
                    ),
                    SizedBox(height: tokens.spaceSmall),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(child: buildKeypadButton('4', () => _onKeyPress(4))),
                        SizedBox(width: tokens.spaceSmall),
                        Expanded(child: buildKeypadButton('5', () => _onKeyPress(5))),
                        SizedBox(width: tokens.spaceSmall),
                        Expanded(child: buildKeypadButton('6', () => _onKeyPress(6))),
                      ],
                    ),
                    SizedBox(height: tokens.spaceSmall),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(child: buildKeypadButton('7', () => _onKeyPress(7))),
                        SizedBox(width: tokens.spaceSmall),
                        Expanded(child: buildKeypadButton('8', () => _onKeyPress(8))),
                        SizedBox(width: tokens.spaceSmall),
                        Expanded(child: buildKeypadButton('9', () => _onKeyPress(9))),
                      ],
                    ),
                    SizedBox(height: tokens.spaceSmall),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Cancel button
                        Expanded(
                          child: AccessibleButton(
                            style: AccessibleButtonStyle.text,
                            onPressed: () => Navigator.of(context).pop(),
                            semanticLabel: 'Cancel PIN entry and go back.',
                            child: const Icon(Icons.arrow_back, size: 28),
                          ),
                        ),
                        SizedBox(width: tokens.spaceSmall),
                        Expanded(child: buildKeypadButton('0', () => _onKeyPress(0))),
                        SizedBox(width: tokens.spaceSmall),
                        // Backspace button
                        Expanded(
                          child: AccessibleButton(
                            style: AccessibleButtonStyle.text,
                            onPressed: _enteredPin.isEmpty ? null : _onBackspace,
                            semanticLabel: 'Backspace key. Delete last digit.',
                            child: const Icon(Icons.backspace_outlined, size: 28),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
