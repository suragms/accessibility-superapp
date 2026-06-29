import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/accessibility_tokens.dart';
import '../../../../core/widgets/accessible_button.dart';
import '../../../../core/widgets/accessible_text_field.dart';
import '../controllers/auth_notifier.dart';

/// An Accessibility-First Login Screen.
/// Key Features:
/// 1. Employs persistent, non-floating text input fields with large focus outline borders.
/// 2. Integrates large interactive actions conforming to WCAG tap standards (min 48dp).
/// 3. Listens to reactive authentication state adjustments and handles redirection routing.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    bool isValid = true;
    if (email.isEmpty) {
      _emailError = 'Email address cannot be empty.';
      isValid = false;
    } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      _emailError = 'Please enter a valid email format.';
      isValid = false;
    }

    if (password.isEmpty) {
      _passwordError = 'Password cannot be empty.';
      isValid = false;
    } else if (password.length < 6) {
      _passwordError = 'Password must be at least 6 characters.';
      isValid = false;
    }

    if (isValid) {
      ref.read(authNotifierProvider.notifier).loginWithEmail(email, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AccessibilityTokens.of(context);
    final theme = Theme.of(context);
    
    // Listen to Auth State changes for visual routing
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is Authenticated) {
        context.goNamed(RouteNames.home);
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              label: 'Login error: ${next.errorMessage}',
              child: Text(next.errorMessage),
            ),
            backgroundColor: theme.colorScheme.error,
          ),
        );
      }
    });

    final state = ref.watch(authNotifierProvider);
    final isLoading = state is AuthLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(tokens.spaceMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    'Welcome back',
                    style: theme.textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: tokens.spaceSmall),
                Text(
                  'Log in to continue managing your independence.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: tokens.spaceXLarge),

                // Credentials Inputs
                AccessibleTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hintText: 'Enter your email (e.g. user@domain.com)',
                  errorText: _emailError,
                  keyboardType: TextInputType.emailAddress,
                  focusNode: _emailFocusNode,
                ),
                SizedBox(height: tokens.spaceMedium),
                AccessibleTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: 'Enter your password',
                  errorText: _passwordError,
                  obscureText: true,
                  focusNode: _passwordFocusNode,
                ),
                SizedBox(height: tokens.spaceLarge),

                // Primary Login Action
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  AccessibleButton(
                    onPressed: _validateAndSubmit,
                    semanticLabel: 'Login button. Double tap to submit credentials.',
                    child: const Text('LOG IN'),
                  ),
                SizedBox(height: tokens.spaceMedium),

                // Alternative Options (PIN & Guest Access)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: AccessibleButton(
                        style: AccessibleButtonStyle.text,
                        onPressed: () {
                          // Redirect to PIN validation screen
                          context.push('/login-pin');
                        },
                        semanticLabel: 'PIN code login. Double tap to enter PIN code.',
                        child: const Text('Use PIN Code'),
                      ),
                    ),
                    Expanded(
                      child: AccessibleButton(
                        style: AccessibleButtonStyle.text,
                        onPressed: () {
                          ref.read(authNotifierProvider.notifier).loginAsGuest();
                        },
                        semanticLabel: 'Guest login. Double tap to skip registration.',
                        child: const Text('Enter as Guest'),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: tokens.spaceLarge),

                // Create Account link
                AccessibleButton(
                  style: AccessibleButtonStyle.text,
                  onPressed: () {
                    context.push('/signup');
                  },
                  semanticLabel: 'Create a new account. Double tap to sign up.',
                  child: const Text("Don't have an account? Create one"),
                ),
                SizedBox(height: tokens.spaceLarge),

                // Social Logins Header
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: tokens.spaceSmall),
                      child: Text('OR CONNECT WITH', style: theme.textTheme.bodySmall),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                SizedBox(height: tokens.spaceMedium),

                // Google & Apple Login Options
                AccessibleButton(
                  style: AccessibleButtonStyle.outlined,
                  onPressed: () {
                    ref.read(authNotifierProvider.notifier).loginWithGoogle();
                  },
                  semanticLabel: 'Login with Google account.',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.g_mobiledata, size: 30),
                      SizedBox(width: tokens.spaceSmall),
                      const Text('GOOGLE'),
                    ],
                  ),
                ),
                SizedBox(height: tokens.spaceSmall),
                AccessibleButton(
                  style: AccessibleButtonStyle.outlined,
                  onPressed: () {
                    ref.read(authNotifierProvider.notifier).loginWithApple();
                  },
                  semanticLabel: 'Login with Apple account.',
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.apple, size: 24),
                      SizedBox(width: tokens.spaceSmall),
                      const Text('APPLE'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
