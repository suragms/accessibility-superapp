import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/accessibility_tokens.dart';
import '../theme/accessibility_profile.dart';

enum AccessibleButtonStyle {
  filled,
  outlined,
  text,
}

/// An Accessibility-First Button implementing WCAG 2.2 AAA recommendations.
/// Key Benefits:
/// 1. Enforces min 48x48dp touch targets via [AccessibilityTokens].
/// 2. Integrates dynamic keyboard/switch outline highlights.
/// 3. Standardizes haptic responses and semantic announcement overrides.
class AccessibleButton extends ConsumerStatefulWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final AccessibleButtonStyle style;
  final String? semanticLabel;
  final String? semanticHint;
  final FocusNode? focusNode;
  final bool autofocus;

  const AccessibleButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style = AccessibleButtonStyle.filled,
    this.semanticLabel,
    this.semanticHint,
    this.focusNode,
    this.autofocus = false,
  });

  @override
  ConsumerState<AccessibleButton> createState() => _AccessibleButtonState();
}

class _AccessibleButtonState extends ConsumerState<AccessibleButton> {
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

  void _onTap(AccessibilityProfile profile) {
    if (widget.onPressed == null) return;
    
    // Light haptics confirmation if active in profile settings
    if (profile.hapticsEnabled) {
      HapticFeedback.lightImpact();
    }

    widget.onPressed!();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AccessibilityTokens.of(context);
    final profile = ref.watch(accessibilityProfileProvider);
    final theme = Theme.of(context);

    // Dynamic colors based on active style and focus states
    Color getBackgroundColor() {
      if (widget.onPressed == null) return theme.disabledColor.withOpacity(0.12);
      switch (widget.style) {
        case AccessibleButtonStyle.filled:
          return _isFocused 
              ? theme.colorScheme.primary.withOpacity(0.85)
              : theme.colorScheme.primary;
        case AccessibleButtonStyle.outlined:
        case AccessibleButtonStyle.text:
          return Colors.transparent;
      }
    }

    Color getForegroundColor() {
      if (widget.onPressed == null) return theme.disabledColor;
      switch (widget.style) {
        case AccessibleButtonStyle.filled:
          return theme.colorScheme.onPrimary;
        case AccessibleButtonStyle.outlined:
        case AccessibleButtonStyle.text:
          return theme.colorScheme.primary;
      }
    }

    BorderSide? getBorder() {
      if (widget.style == AccessibleButtonStyle.outlined) {
        final color = widget.onPressed == null ? theme.disabledColor : theme.colorScheme.primary;
        return BorderSide(color: color, width: tokens.borderThicknessNormal);
      }
      return null;
    }

    return Semantics(
      button: true,
      enabled: widget.onPressed != null,
      label: widget.semanticLabel,
      hint: widget.semanticHint,
      child: Focus(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        child: Container(
          // Ensure visual touch target bounds meets minimum 48dp WCAG specification
          constraints: BoxConstraints(
            minWidth: tokens.minTapTargetSize,
            minHeight: tokens.minTapTargetSize,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.buttonCornerRadius),
            // High visibility focus outline overlay (separate outline to help visual clarity)
            border: _isFocused
                ? Border.all(
                    color: theme.colorScheme.primary,
                    width: tokens.focusBorderWidth,
                  )
                : Border.all(color: Colors.transparent, width: tokens.focusBorderWidth),
          ),
          padding: EdgeInsets.all(tokens.focusOutlineOffset),
           child: Material(
            color: getBackgroundColor(),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.buttonCornerRadius),
              side: getBorder() ?? BorderSide.none,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: tokens.minTapTargetSize,
                minHeight: tokens.minTapTargetSize,
              ),
              child: InkWell(
                onTap: widget.onPressed != null ? () => _onTap(profile) : null,
                borderRadius: BorderRadius.circular(tokens.buttonCornerRadius),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: tokens.spaceMedium,
                    vertical: tokens.spaceSmall,
                  ),
                  child: Center(
                    widthFactor: 1.0,
                    heightFactor: 1.0,
                    child: DefaultTextStyle(
                      style: theme.textTheme.labelLarge!.copyWith(
                        color: getForegroundColor(),
                      ),
                      // Prevent text compression / truncation to satisfy WCAG AAA standards
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: widget.child,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
