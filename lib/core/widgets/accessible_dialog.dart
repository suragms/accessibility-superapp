import 'package:flutter/material.dart';
import '../theme/accessibility_tokens.dart';

/// An Accessibility-First Modal Dialog.
/// Key Benefits:
/// 1. Exposes header semantics that read automatically on open.
/// 2. Implements standard focus-traps limiting navigation options.
/// 3. Incorporates a large, unambiguous close button to exit modal context.
class AccessibleDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final List<Widget> actions;
  final String? semanticDescription;

  const AccessibleDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.semanticDescription,
  });

  /// Displays the accessible dialog.
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget content,
    required List<Widget> actions,
    String? semanticDescription,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss dialog overlay',
      builder: (BuildContext context) {
        return AccessibleDialog(
          title: title,
          content: content,
          actions: actions,
          semanticDescription: semanticDescription,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AccessibilityTokens.of(context);
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(tokens.cardCornerRadius),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: tokens.borderThicknessNormal,
        ),
      ),
      child: Semantics(
        namesRoute: true,
        scopesRoute: true, // Focus trap containment
        label: title,
        child: Padding(
          padding: EdgeInsets.all(tokens.spaceLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Row with Title & Close Action
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: theme.textTheme.displaySmall,
                      ),
                    ),
                  ),
                  SizedBox(width: tokens.spaceSmall),
                  Semantics(
                    button: true,
                    label: 'Close dialog',
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Close dialog',
                      iconSize: 28,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
              SizedBox(height: tokens.spaceMedium),

              // Content block
              Semantics(
                label: semanticDescription,
                child: DefaultTextStyle(
                  style: theme.textTheme.bodyMedium!,
                  child: content,
                ),
              ),
              SizedBox(height: tokens.spaceLarge),

              // Actions layout (wraps dynamically to column if texts grow under high text scale)
              Wrap(
                spacing: tokens.spaceSmall,
                runSpacing: tokens.spaceSmall,
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: actions,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
