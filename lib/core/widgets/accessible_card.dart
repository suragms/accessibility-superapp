import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/accessibility_tokens.dart';
import '../theme/accessibility_profile.dart';

/// An Accessibility-First Card Container.
/// Key Benefits:
/// 1. Merges children semantics by default, allowing screen-readers to read card content cohesively.
/// 2. Integrates high-contrast borders based on contrast configuration profiles.
/// 3. Incorporates visual focus outlines if designated as interactive.
class AccessibleCard extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool mergeSemantics;
  final FocusNode? focusNode;

  const AccessibleCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.mergeSemantics = true,
    this.focusNode,
  });

  @override
  ConsumerState<AccessibleCard> createState() => _AccessibleCardState();
}

class _AccessibleCardState extends ConsumerState<AccessibleCard> {
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

    // High contrast theme enforces bright white/yellow card outlines
    final borderThickness = profile.useHighContrast
        ? tokens.borderThicknessBold
        : tokens.borderThicknessNormal;

    final baseBorder = Border.all(
      color: theme.colorScheme.primary.withOpacity(profile.useHighContrast ? 1.0 : 0.2),
      width: borderThickness,
    );

    final focusBorder = Border.all(
      color: theme.colorScheme.primary,
      width: tokens.focusBorderWidth,
    );

    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(tokens.cardCornerRadius),
        border: _isFocused ? focusBorder : baseBorder,
        boxShadow: profile.useHighContrast 
            ? null 
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          focusNode: _focusNode,
          borderRadius: BorderRadius.circular(tokens.cardCornerRadius),
          child: Padding(
            padding: EdgeInsets.all(tokens.spaceMedium),
            child: widget.child,
          ),
        ),
      ),
    );

    // Merge semantics enables reading the card contents as a single unified announcement block.
    if (widget.mergeSemantics) {
      cardContent = MergeSemantics(
        child: Semantics(
          label: widget.semanticLabel,
          child: cardContent,
        ),
      );
    } else if (widget.semanticLabel != null) {
      cardContent = Semantics(
        label: widget.semanticLabel,
        child: cardContent,
      );
    }

    return cardContent;
  }
}
