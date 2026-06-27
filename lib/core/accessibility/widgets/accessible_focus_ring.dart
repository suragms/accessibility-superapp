import 'package:flutter/material.dart';
import '../../theme/accessibility_tokens.dart';

/// An Accessibility-First widget overlay drawing highly visible focus rings
/// around interactive components when navigated via keyboard/switch systems.
class AccessibleFocusRing extends StatefulWidget {
  final Widget child;
  final FocusNode focusNode;
  final double? borderRadius;

  const AccessibleFocusRing({
    super.key,
    required this.child,
    required this.focusNode,
    this.borderRadius,
  });

  @override
  State<AccessibleFocusRing> createState() => _AccessibleFocusRingState();
}

class _AccessibleFocusRingState extends State<AccessibleFocusRing> {
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
    _isFocused = widget.focusNode.hasFocus;
  }

  @override
  void didUpdateWidget(covariant AccessibleFocusRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode.removeListener(_onFocusChange);
      widget.focusNode.addListener(_onFocusChange);
      _isFocused = widget.focusNode.hasFocus;
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = widget.focusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AccessibilityTokens.of(context);
    final theme = Theme.of(context);

    final double effectiveRadius = widget.borderRadius ?? tokens.buttonCornerRadius;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(effectiveRadius),
        // Draw outline border ring offset from child boundaries
        border: Border.all(
          color: _isFocused ? theme.colorScheme.primary : Colors.transparent,
          width: tokens.focusBorderWidth,
        ),
      ),
      padding: EdgeInsets.all(tokens.focusOutlineOffset),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(effectiveRadius),
        child: widget.child,
      ),
    );
  }
}
