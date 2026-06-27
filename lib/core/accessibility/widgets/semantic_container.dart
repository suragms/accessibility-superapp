import 'package:flutter/material.dart';

/// Accessibility semantic container supporting grouped overrides and exclusions.
/// Key Features:
/// 1. Merges child node hierarchies into unified spoken groups.
/// 2. Hides purely decorative visual structures (`excludeSemantics`).
/// 3. Declares custom live-region updates, custom actions, and header definitions.
class SemanticContainer extends StatelessWidget {
  final Widget child;
  final bool mergeSemantics;
  final bool excludeSemantics;
  final String? label;
  final String? hint;
  final String? value;
  final bool? isButton;
  final bool? isHeader;
  final bool? isLiveRegion;

  const SemanticContainer({
    super.key,
    required this.child,
    this.mergeSemantics = false,
    this.excludeSemantics = false,
    this.label,
    this.hint,
    this.value,
    this.isButton,
    this.isHeader,
    this.isLiveRegion,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    // Apply basic semantic label/hint/value attributes
    if (label != null || 
        hint != null || 
        value != null || 
        isButton != null || 
        isHeader != null || 
        isLiveRegion != null) {
      content = Semantics(
        label: label,
        hint: hint,
        value: value,
        button: isButton,
        header: isHeader,
        liveRegion: isLiveRegion,
        child: content,
      );
    }

    // Merge child properties together
    if (mergeSemantics) {
      content = MergeSemantics(child: content);
    }

    // Exclude decoration trees
    if (excludeSemantics) {
      content = ExcludeSemantics(child: content);
    }

    return content;
  }
}
