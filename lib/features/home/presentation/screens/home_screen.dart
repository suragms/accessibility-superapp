import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/providers/current_user_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/accessibility_tokens.dart';
import '../../../../core/widgets/accessible_card.dart';
import '../../../auth/presentation/controllers/auth_notifier.dart';
import '../../../medication/presentation/controllers/medication_controller.dart';

/// Accessibility-First Home Dashboard Screen.
/// Key Features:
/// 1. Dynamic greetings using authenticated profile credentials.
/// 2. Grid-based shortcuts for all core platform capabilities.
/// 3. Inlined summaries of upcoming medication schedules.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Retrieve latest medication records on dashboard entrance
    Future.microtask(() {
      final userId = ref.read(currentUserIdProvider);
      if (userId != null) {
        ref.read(medicationControllerProvider.notifier).fetchActiveMedications(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AccessibilityTokens.of(context);
    final theme = Theme.of(context);

    final authState = ref.watch(authNotifierProvider);
    final String email = authState is Authenticated ? authState.session.email : 'User';
    final String displayName = email.split('@').first;

    final medState = ref.watch(medicationControllerProvider);
    final activeMeds = medState.medications;

    // Helper widget for Feature Shortcut Cards
    Widget buildFeatureCard({
      required String title,
      required String description,
      required IconData icon,
      required Color color,
      required VoidCallback onTap,
    }) {
      return AccessibleCard(
        onTap: onTap,
        semanticLabel: 'Navigate to $title. $description',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: tokens.spaceSmall),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: tokens.spaceXXSmall),
                Text(
                  description,
                  style: theme.textTheme.bodySmall!.copyWith(
                    color: theme.textTheme.bodySmall!.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Dashboard Greeting Row
              Semantics(
                header: true,
                child: Text(
                  'Welcome back,',
                  style: theme.textTheme.titleMedium!.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                displayName,
                style: theme.textTheme.displayMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: tokens.spaceLarge),

              // 2. Core Feature Shortcuts Grid
              Semantics(
                header: true,
                child: Text(
                  'Quick Access Features',
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: tokens.spaceSmall),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: tokens.spaceSmall,
                mainAxisSpacing: tokens.spaceSmall,
                childAspectRatio: 1.15,
                children: [
                  buildFeatureCard(
                    title: 'AI Assistant',
                    description: 'Ask voice questions',
                    icon: Icons.assistant_outlined,
                    color: Colors.blue[700]!,
                    onTap: () => context.goNamed(RouteNames.aiAssistant),
                  ),
                  buildFeatureCard(
                    title: 'Live Captions',
                    description: 'Transcribe live speech',
                    icon: Icons.hearing_outlined,
                    color: Colors.teal[700]!,
                    onTap: () => context.goNamed(RouteNames.speechToText),
                  ),
                  buildFeatureCard(
                    title: 'Medications',
                    description: 'Reminders & alerts',
                    icon: Icons.medication_outlined,
                    color: Colors.purple[700]!,
                    onTap: () => context.goNamed(RouteNames.medicationList),
                  ),
                  buildFeatureCard(
                    title: 'Caregivers',
                    description: 'Contact caregivers',
                    icon: Icons.people_outline,
                    color: Colors.orange[700]!,
                    onTap: () => context.goNamed(RouteNames.caregiver),
                  ),
                ],
              ),
              SizedBox(height: tokens.spaceSmall),
              
              // SOS stands out as full width alert button
              AccessibleCard(
                onTap: () => context.pushNamed(RouteNames.sos),
                semanticLabel: 'Emergency SOS broadcasts.',
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.colorScheme.error.withOpacity(0.12),
                      radius: 28,
                      child: Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error, size: 32),
                    ),
                    SizedBox(width: tokens.spaceMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'EMERGENCY SOS',
                            style: theme.textTheme.titleMedium!.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.error,
                            ),
                          ),
                          Text(
                            'Trigger panic notifications & call primary caregiver',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: theme.disabledColor),
                  ],
                ),
              ),
              
              SizedBox(height: tokens.spaceLarge),

              // 3. Upcoming Medication Reminders List
              Semantics(
                header: true,
                child: Text(
                  'Upcoming Reminders',
                  style: theme.textTheme.titleLarge!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: tokens.spaceSmall),
              
              if (medState.isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (activeMeds.isEmpty)
                AccessibleCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: tokens.spaceMedium),
                    child: Center(
                      child: Text(
                        'No active medication reminders.',
                        style: theme.textTheme.bodyLarge!.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: activeMeds.length,
                  itemBuilder: (context, index) {
                    final med = activeMeds[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: tokens.spaceSmall),
                      child: AccessibleCard(
                        semanticLabel: 'Medication reminder: ${med.name}. Dosage: ${med.dosage}. Schedule: ${med.cronSchedule}',
                        child: Row(
                          children: [
                            Icon(Icons.alarm, color: theme.colorScheme.primary, size: 28),
                            SizedBox(width: tokens.spaceMedium),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    med.name,
                                    style: theme.textTheme.titleMedium!.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Dosage: ${med.dosage}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: tokens.spaceSmall,
                                vertical: tokens.spaceXXSmall,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(tokens.buttonCornerRadius),
                              ),
                              child: Text(
                                med.cronSchedule,
                                style: theme.textTheme.bodySmall!.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
