import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/route_names.dart';
import '../../../../core/theme/accessibility_tokens.dart';
import '../../../../core/widgets/accessible_button.dart';
import '../../../../core/widgets/accessible_text_field.dart';
import '../controllers/auth_notifier.dart';

/// An Accessibility-First Create Account Screen.
/// Key Features:
/// 1. Persistent, non-floating text input fields with large focus outline borders.
/// 2. Large interactive actions conforming to WCAG tap standards (min 48dp).
/// 3. Listens to reactive authentication state and handles redirection routing.
class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

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

    if (confirmPassword.isEmpty) {
      _confirmPasswordError = 'Please confirm your password.';
      isValid = false;
    } else if (password != confirmPassword) {
      _confirmPasswordError = 'Passwords do not match.';
      isValid = false;
    }

    if (isValid) {
      ref.read(authNotifierProvider.notifier).signup(email, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AccessibilityTokens.of(context);
    final theme = Theme.of(context);

    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next is Authenticated) {
        context.goNamed(RouteNames.home);
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Semantics(
              liveRegion: true,
              label: 'Signup error: ${next.errorMessage}',
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
        title: const Text('Create Account'),
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
                    'Create your account',
                    style: theme.textTheme.displayMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: tokens.spaceSmall),
                Text(
                  'Sign up to start managing your independence.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: tokens.spaceXLarge),

                // Email Input
                AccessibleTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hintText: 'Enter your email (e.g. user@domain.com)',
                  errorText: _emailError,
                  keyboardType: TextInputType.emailAddress,
                  focusNode: _emailFocusNode,
                ),
                SizedBox(height: tokens.spaceMedium),

                // Password Input
                AccessibleTextField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: 'Create a password (min 6 characters)',
                  errorText: _passwordError,
                  obscureText: true,
                  focusNode: _passwordFocusNode,
                ),
                SizedBox(height: tokens.spaceMedium),

                // Confirm Password Input
                AccessibleTextField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hintText: 'Re-enter your password',
                  errorText: _confirmPasswordError,
                  obscureText: true,
                  focusNode: _confirmPasswordFocusNode,
                ),
                SizedBox(height: tokens.spaceLarge),

                // Primary Signup Action
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  AccessibleButton(
                    onPressed: _validateAndSubmit,
                    semanticLabel:
                        'Create Account button. Double tap to register.',
                    child: const Text('CREATE ACCOUNT'),
                  ),
                SizedBox(height: tokens.spaceMedium),

                // Already have an account link
                AccessibleButton(
                  style: AccessibleButtonStyle.text,
                  onPressed: () {
                    context.go('/login');
                  },
                  semanticLabel:
                      'Already have an account? Go to login screen.',
                  child: const Text('Already have an account? Log in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
