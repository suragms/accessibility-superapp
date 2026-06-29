import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/auth_notifier.dart';

/// Provides the currently authenticated user's ID, or null if not authenticated.
///
/// This provider derives the userId from the [authNotifierProvider] state.
/// Screens that consume this provider should generally only be reachable
/// post-authentication (the router's redirect logic enforces this), so
/// [currentUserId] throws an assertion error in debug mode if the user
/// is not authenticated — surfaces bugs early. In release mode, it returns
/// null gracefully to avoid crashes.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authNotifierProvider);
  if (authState is Authenticated) {
    return authState.session.userId;
  }
  return null;
});

/// Convenience getter that asserts the user is authenticated.
///
/// Use this in screens/actions that are guaranteed to be reachable only
/// after authentication (enforced by router redirect logic). Throws an
/// [AssertionError] in debug mode if accessed without an active session.
/// Returns null in release mode as a graceful fallback.
String? currentUserId(WidgetRef ref) {
  final userId = ref.watch(currentUserIdProvider);
  assert(userId != null, 'currentUserId accessed without an authenticated session');
  return userId;
}
