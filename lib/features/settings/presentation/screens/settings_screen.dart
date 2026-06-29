import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/accessibility_tokens.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/accessible_button.dart';
import '../../../../core/widgets/accessible_card.dart';
import '../../../../core/widgets/accessible_dialog.dart';
import '../../../../core/widgets/accessible_text_field.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../controllers/settings_controller.dart';

/// Accessibility-First Settings Management Screen.
/// Key Features:
/// 1. Interactive settings for high contrast, themes, and dyslexic text.
/// 2. Offline security options (offline PIN registrations).
/// 3. Clear accounts management triggers.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showSetPinDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    String? errorText;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss dialog overlay',
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AccessibleDialog(
              title: 'Set Security PIN',
              semanticDescription: 'Enter a 4-digit code to enable offline PIN verification login.',
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AccessibleTextField(
                    controller: controller,
                    focusNode: focusNode,
                    label: 'New 4-Digit PIN',
                    hintText: 'Enter 4 numbers',
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    errorText: errorText,
                  ),
                ],
              ),
              actions: [
                AccessibleButton(
                  style: AccessibleButtonStyle.text,
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('CANCEL'),
                ),
                AccessibleButton(
                  style: AccessibleButtonStyle.filled,
                  onPressed: () {
                    final pinText = controller.text.trim();
                    if (pinText.length != 4 || int.tryParse(pinText) == null) {
                      setState(() {
                        errorText = 'PIN must be exactly 4 digits.';
                      });
                      return;
                    }
                    ref.read(authNotifierProvider.notifier).setOfflinePin(pinText);
                    Navigator.of(ctx).pop();
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Offline PIN updated successfully.'),
                      ),
                    );
                  },
                  child: const Text('SAVE PIN'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = AccessibilityTokens.of(context);
    final theme = Theme.of(context);

    final settings = ref.watch(settingsControllerProvider);
    final authState = ref.watch(authNotifierProvider);
    final String email = authState is Authenticated ? authState.session.email : 'Unauthenticated';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Accessibility Configuration Section
              Semantics(
                header: true,
                child: Text(
                  'Accessibility Options',
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: tokens.spaceSmall),
              AccessibleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'App Theme Mode',
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: tokens.spaceXSmall),
                    DropdownButtonFormField<ThemeModeOption>(
                      value: settings.themeMode,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeModeOption.light,
                          child: Text('Light Mode'),
                        ),
                        DropdownMenuItem(
                          value: ThemeModeOption.dark,
                          child: Text('Dark Mode'),
                        ),
                        DropdownMenuItem(
                          value: ThemeModeOption.highContrast,
                          child: Text('High Contrast Mode'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(settingsControllerProvider.notifier).setThemeMode(val);
                        }
                      },
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dyslexic-Friendly Font',
                                style: theme.textTheme.titleMedium!.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Use high readability dyslexic text scaling',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: settings.useDyslexicFont,
                          onChanged: (enabled) {
                            ref.read(settingsControllerProvider.notifier).toggleDyslexicFont(enabled);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: tokens.spaceLarge),

              // 2. Account Management Section
              Semantics(
                header: true,
                child: Text(
                  'Account Settings',
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: tokens.spaceSmall),
              AccessibleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Logged In As',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      email,
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Divider(height: 32),
                    AccessibleButton(
                      style: AccessibleButtonStyle.outlined,
                      onPressed: () => _showSetPinDialog(context, ref),
                      semanticLabel: 'Set or change offline verification security PIN code.',
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: Text('SET / CHANGE SECURITY PIN'),
                      ),
                    ),
                    SizedBox(height: tokens.spaceMedium),
                    AccessibleButton(
                      style: AccessibleButtonStyle.filled,
                      onPressed: () {
                        ref.read(authNotifierProvider.notifier).logout();
                      },
                      semanticLabel: 'Log out of current session.',
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 4.0),
                        child: Text('LOG OUT'),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: tokens.spaceLarge),

              // 3. System details Section
              Semantics(
                header: true,
                child: Text(
                  'About Application',
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: tokens.spaceSmall),
              AccessibleCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'App Version',
                      style: theme.textTheme.titleMedium!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '1.0.0+1',
                      style: theme.textTheme.bodyLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.disabledColor,
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
