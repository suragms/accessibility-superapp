import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/pin_verify_screen.dart';
import '../../features/auth/presentation/controllers/auth_notifier.dart';
import '../../features/ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../features/speech/presentation/screens/speech_screen.dart';
import '../../features/medication/presentation/screens/medication_list_screen.dart';
import '../../features/medication/presentation/screens/medication_form_screen.dart';
import '../../features/sos/presentation/screens/sos_screen.dart';
import '../../features/caregiver/presentation/screens/caregiver_screen.dart';
import '../../features/voice_navigation/presentation/screens/voice_navigation_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/settings/presentation/controllers/settings_controller.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import 'route_names.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Riverpod provider for GoRouter configuration.
/// Allows dynamic updates (e.g. authentication status change redirects).
final appRouterProvider = Provider<GoRouter>((ref) {
  final settings = ref.read(settingsControllerProvider);
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: settings.hasSeenOnboarding ? '/login' : '/onboarding',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/login-pin',
        name: 'login-pin',
        builder: (context, state) => const PinVerifyScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: RouteNames.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      // SOS Screen is modal-like, direct overlay reachable from anywhere
      GoRoute(
        path: '/sos',
        name: RouteNames.sos,
        builder: (context, state) => const SosScreen(),
      ),
      // Voice Navigation Screen is implemented as a global overlay (similar to /sos) because:
      // 1. It provides a focused, immersive experience for voice interaction, minimizing visual clutter.
      // 2. It avoids complicating the NavigationBar's selectedIndex state.
      // 3. Tapping the FAB from any shell screen will push this overlay, and executing a navigation command will route to the target shell screen or pop back.
      GoRoute(
        path: '/voice-navigation',
        name: RouteNames.voiceNavigation,
        builder: (context, state) => const VoiceNavigationScreen(),
      ),
      // ShellRoute provides persistent bottom/side navigation tabs suitable for accessible navigation.
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return NavigationShellContainer(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            name: RouteNames.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/ai-assistant',
            name: RouteNames.aiAssistant,
            builder: (context, state) => const AiAssistantScreen(),
          ),
          GoRoute(
            path: '/speech-to-text',
            name: RouteNames.speechToText,
            builder: (context, state) => const SpeechScreen(),
          ),
          GoRoute(
            path: '/medications',
            name: RouteNames.medicationList,
            builder: (context, state) => const MedicationListScreen(),
            routes: [
              GoRoute(
                path: 'add',
                name: RouteNames.medicationAdd,
                builder: (context, state) => const MedicationFormScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/caregiver',
            name: RouteNames.caregiver,
            builder: (context, state) => const CaregiverScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: RouteNames.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    // Global redirect handler for onboarding and auth logic
    redirect: (context, state) {
      final settingsVal = ref.read(settingsControllerProvider);
      if (!settingsVal.hasSeenOnboarding) {
        if (state.matchedLocation != '/onboarding') {
          return '/onboarding';
        }
        return null;
      }

      if (state.matchedLocation == '/onboarding') {
        return '/login';
      }

      final authState = ref.read(authNotifierProvider);
      final isLoggingIn = state.matchedLocation == '/login' ||
          state.matchedLocation == '/login-pin' ||
          state.matchedLocation == '/signup';

      // While restoring session, allow current route to render without redirect
      if (authState is AuthLoading || authState is AuthInitial) {
        return null;
      }

      if (authState is Unauthenticated || authState is AuthError) {
        if (!isLoggingIn) return '/login';
      }
      if (authState is Authenticated && isLoggingIn) {
        return '/home';
      }
      return null;
    },
  );
});

/// Shell container wrapping primary routes with an accessible navigation layout.
/// Adheres to Material 3 navigation bar design guidelines.
class NavigationShellContainer extends StatelessWidget {
  final Widget child;
  const NavigationShellContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final GoRouterState routerState = GoRouterState.of(context);
    final String location = routerState.matchedLocation;

    int calculateSelectedIndex() {
      if (location.startsWith('/home')) return 0;
      if (location.startsWith('/ai-assistant')) return 1;
      if (location.startsWith('/speech-to-text')) return 2;
      if (location.startsWith('/medications')) return 3;
      if (location.startsWith('/caregiver')) return 4;
      if (location.startsWith('/settings')) return 5;
      return 0;
    }

    void onItemTapped(int index) {
      switch (index) {
        case 0:
          context.goNamed(RouteNames.home);
          break;
        case 1:
          context.goNamed(RouteNames.aiAssistant);
          break;
        case 2:
          context.goNamed(RouteNames.speechToText);
          break;
        case 3:
          context.goNamed(RouteNames.medicationList);
          break;
        case 4:
          context.goNamed(RouteNames.caregiver);
          break;
        case 5:
          context.goNamed(RouteNames.settings);
          break;
      }
    }

    return Scaffold(
      body: child,
      // Large layout handles sidebar/navigation rail, mobile uses bottom navigation.
      bottomNavigationBar: NavigationBar(
        selectedIndex: calculateSelectedIndex(),
        onDestinationSelected: onItemTapped,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
            tooltip: 'Navigate to Home Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.assistant_outlined),
            selectedIcon: Icon(Icons.assistant),
            label: 'Assistant',
            tooltip: 'Navigate to AI Assistant',
          ),
          NavigationDestination(
            icon: Icon(Icons.hearing_outlined),
            selectedIcon: Icon(Icons.hearing),
            label: 'Captions',
            tooltip: 'Navigate to Live Captions',
          ),
          NavigationDestination(
            icon: Icon(Icons.medication_outlined),
            selectedIcon: Icon(Icons.medication),
            label: 'Meds',
            tooltip: 'Navigate to Medications list',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Caregiver',
            tooltip: 'Navigate to Caregivers page',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
            tooltip: 'Navigate to Settings',
          ),
        ],
      ),
      floatingActionButton: Semantics(
        label: 'Activate voice navigation.',
        button: true,
        child: FloatingActionButton(
          onPressed: () {
            context.pushNamed(RouteNames.voiceNavigation);
          },
          tooltip: 'Activate voice navigation',
          child: const Icon(Icons.mic, size: 30),
        ),
      ),
    );
  }
}
