import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/accessibility_tokens.dart';
import '../../../../core/widgets/accessible_button.dart';
import '../../../settings/presentation/controllers/settings_controller.dart';

/// Structural entity for Onboarding slide data.
class _OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

/// Accessibility-First Swipeable Onboarding Screen.
/// Key Features:
/// 1. Screen-reader accessible PageView sliders.
/// 2. Easy skip/dismiss triggers persisting onboarding states.
/// 3. Clear contrast dots indicator for position tracking.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingSlide> _slides = const [
    _OnboardingSlide(
      title: 'Voice & AI Assistant',
      description: 'Interact with the application using simple voice navigation commands. Say "Assistant" followed by your command to navigate anywhere instantly.',
      icon: Icons.assistant_outlined,
      color: Colors.blue,
    ),
    _OnboardingSlide(
      title: 'Medication Reminders',
      description: 'Never miss a dose. Track your active medications, schedule repeating alarms, and record daily taken status even while offline.',
      icon: Icons.medication_outlined,
      color: Colors.purple,
    ),
    _OnboardingSlide(
      title: 'Emergency SOS & Caregivers',
      description: 'Trigger panic SOS alerts to dispatch emergency messages to pre-registered caregivers, accompanied by real-time GPS location reports.',
      icon: Icons.warning_amber_rounded,
      color: Colors.red,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onFinish() {
    ref.read(settingsControllerProvider.notifier).completeOnboarding();
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AccessibilityTokens.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Skip Control Row
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: tokens.spaceMedium,
                vertical: tokens.spaceSmall,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_currentPage < _slides.length - 1)
                    AccessibleButton(
                      style: AccessibleButtonStyle.text,
                      onPressed: _onFinish,
                      semanticLabel: 'Skip onboarding introduction.',
                      child: const Text('SKIP'),
                    ),
                ],
              ),
            ),
            
            // Slider Body
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: tokens.spaceLarge),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 64,
                          backgroundColor: slide.color.withOpacity(0.12),
                          child: Icon(
                            slide.icon,
                            size: 64,
                            color: slide.color,
                          ),
                        ),
                        SizedBox(height: tokens.spaceXXLarge),
                        Semantics(
                          header: true,
                          child: Text(
                            slide.title,
                            style: theme.textTheme.displaySmall!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: tokens.spaceMedium),
                        Text(
                          slide.description,
                          style: theme.textTheme.bodyLarge!.copyWith(
                            color: theme.textTheme.bodyLarge!.color?.withOpacity(0.8),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Navigation Indicators & Controls Bottom Row
            Padding(
              padding: EdgeInsets.all(tokens.spaceLarge),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Dot Indicators
                  Semantics(
                    label: 'Page ${_currentPage + 1} of ${_slides.length}',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (index) {
                        final isActive = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: isActive ? 24 : 12,
                          height: 12,
                          margin: EdgeInsets.symmetric(horizontal: tokens.spaceXXSmall),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: isActive ? theme.colorScheme.primary : theme.disabledColor,
                          ),
                        );
                      }),
                    ),
                  ),
                  SizedBox(height: tokens.spaceLarge),

                  // Button Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        AccessibleButton(
                          style: AccessibleButtonStyle.outlined,
                          onPressed: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          semanticLabel: 'Go to previous slide.',
                          child: const Text('BACK'),
                        )
                      else
                        const SizedBox.shrink(),
                      
                      AccessibleButton(
                        style: AccessibleButtonStyle.filled,
                        onPressed: () {
                          if (_currentPage < _slides.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _onFinish();
                          }
                        },
                        semanticLabel: _currentPage == _slides.length - 1
                            ? 'Get started and go to login.'
                            : 'Go to next slide.',
                        child: Text(
                          _currentPage == _slides.length - 1 ? 'GET STARTED' : 'NEXT',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
