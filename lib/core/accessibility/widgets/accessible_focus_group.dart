import 'package:flutter/material.dart';

/// Focus Traversal Group that enforces logical keyboard/switch navigation paths.
/// Wraps forms, pages, or card sections so tab/directional focuses execute predictably.
class AccessibleFocusGroup extends StatelessWidget {
  final Widget child;
  final FocusTraversalPolicy? policy;

  const AccessibleFocusGroup({
    super.key,
    required this.child,
    this.policy,
  });

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      // Standardizes traversal using ordered policy by default
      policy: policy ?? OrderedTraversalPolicy(),
      child: child,
    );
  }
}

/// Helper component defining numeric order values within an [AccessibleFocusGroup].
class AccessibleFocusOrder extends StatelessWidget {
  final Widget child;
  final double orderNumber;

  const AccessibleFocusOrder({
    super.key,
    required this.orderNumber,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FocusTraversalOrder(
      order: NumericFocusOrder(orderNumber),
      child: child,
    );
  }
}
