import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/accessibility_tokens.dart';
import '../theme/accessibility_profile.dart';

/// An Accessibility-First Text Input.
/// Key Benefits:
/// 1. Enforces persistent visual labels (does not float away or compress).
/// 2. Integrates an explicit semantic error announcer read automatically by screen readers.
/// 3. Employs wide contrast borders and distinct focus nodes.
class AccessibleTextField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final String? errorText;
  final TextInputType keyboardType;
  final bool obscureText;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onVoiceTypingPressed;

  const AccessibleTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    this.errorText,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.focusNode,
    this.onChanged,
    this.onVoiceTypingPressed,
  });

  @override
  ConsumerState<AccessibleTextField> createState() => _AccessibleTextFieldState();
}

class _AccessibleTextFieldState extends ConsumerState<AccessibleTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AccessibilityTokens.of(context);
    final profile = ref.watch(accessibilityProfileProvider);
    final theme = Theme.of(context);

    final isError = widget.errorText != null;

    Color getBorderColor() {
      if (isError) return theme.colorScheme.error;
      if (_isFocused) return theme.colorScheme.primary;
      return theme.colorScheme.primary.withOpacity(profile.useHighContrast ? 1.0 : 0.35);
    }

    final double borderThickness = _isFocused 
        ? tokens.focusBorderWidth 
        : (profile.useHighContrast ? tokens.borderThicknessBold : tokens.borderThicknessNormal);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Persistent label above input to prevent context confusion
        Semantics(
          label: 'Label: ${widget.label}',
          header: true,
          child: Text(
            widget.label,
            style: theme.textTheme.bodyMedium!.copyWith(
              fontWeight: FontWeight.w700,
              color: isError ? theme.colorScheme.error : theme.colorScheme.onSurface,
            ),
          ),
        ),
        SizedBox(height: tokens.spaceSmall),
        
        // Input core container
        Semantics(
          textField: true,
          label: widget.label,
          hint: widget.hintText,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(tokens.inputCornerRadius),
              border: Border.all(
                color: getBorderColor(),
                width: borderThickness,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    focusNode: _focusNode,
                    keyboardType: widget.keyboardType,
                    obscureText: widget.obscureText,
                    onChanged: widget.onChanged,
                    style: theme.textTheme.bodyLarge,
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      hintStyle: theme.textTheme.bodyMedium!.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: tokens.spaceMedium,
                        vertical: tokens.spaceMedium,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                // Integration for Voice Typing trigger
                if (widget.onVoiceTypingPressed != null)
                  Semantics(
                    button: true,
                    label: 'Start voice typing',
                    child: Padding(
                      padding: EdgeInsets.only(right: tokens.spaceSmall),
                      child: IconButton(
                        icon: const Icon(Icons.mic),
                        color: theme.colorScheme.primary,
                        tooltip: 'Voice typing',
                        onPressed: widget.onVoiceTypingPressed,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Semantic Error message container (LiveRegion lets screen readers announce errors immediately)
        if (isError) ...[
          SizedBox(height: tokens.spaceXSmall),
          Semantics(
            liveRegion: true,
            label: 'Error: ${widget.errorText}',
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.error,
                  size: 20,
                ),
                SizedBox(width: tokens.spaceXSmall),
                Expanded(
                  child: Text(
                    widget.errorText!,
                    style: theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
