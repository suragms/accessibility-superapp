import 'package:flutter/material.dart';
import '../theme/accessibility_tokens.dart';

/// An Accessibility-First Bottom Sheet container.
/// Key Benefits:
/// 1. Provides a highly visible close button (removes pure gesture-dismissal reliance).
/// 2. Integrates a prominent top grab-handle acting as clear visual state indication.
/// 3. Standardizes scroll containment to protect dynamic font scaling.
class AccessibleBottomSheet extends StatelessWidget {
  final String title;
  final Widget content;
  final String? semanticLabel;

  const AccessibleBottomSheet({
    super.key,
    required this.title,
    required this.content,
    this.semanticLabel,
  });

  /// Presents the accessible bottom sheet.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    String? semanticLabel,
  }) {
    final tokens = AccessibilityTokens.of(context);
    final theme = Theme.of(context);

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(tokens.cardCornerRadius * 1.5),
          topRight: Radius.circular(tokens.cardCornerRadius * 1.5),
        ),
      ),
      builder: (BuildContext context) {
        return AccessibleBottomSheet(
          title: title,
          content: content,
          semanticLabel: semanticLabel,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AccessibilityTokens.of(context);
    final theme = Theme.of(context);

    return Semantics(
      namesRoute: true,
      scopesRoute: true,
      label: title,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.spaceMedium),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Visual drag handle
              Center(
                child: Container(
                  width: 48,
                  height: 6,
                  margin: EdgeInsets.symmetric(vertical: tokens.spaceSmall),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              
              // Header title and Close Button row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: theme.textTheme.headlineMedium!.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Close sheet options',
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Close sheet',
                      iconSize: 26,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              Divider(height: tokens.spaceMedium),

              // Scrollable sheet content body to support layout scaling
              Flexible(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom + tokens.spaceLarge,
                  ),
                  child: Semantics(
                    label: semanticLabel,
                    child: DefaultTextStyle(
                      style: theme.textTheme.bodyLarge!,
                      child: content,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
