import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/accessibility/widgets/accessible_focus_group.dart';
import '../../../../core/accessibility/widgets/semantic_container.dart';
import '../../../../core/providers/current_user_provider.dart';
import '../../../../core/router/route_names.dart';
import '../../../../core/theme/accessibility_tokens.dart';
import '../../../../core/widgets/accessible_button.dart';
import '../../../../core/widgets/accessible_card.dart';
import '../controllers/medication_controller.dart';

/// An Accessibility-First Medication List Dashboard.
/// Key Features:
/// 1. Unified cards grouping dosage schedule & doctor notes.
/// 2. Double-tap log triggers (Take, Snooze, Skip) matching WCAG tap criteria (min 48dp).
/// 3. Dynamic offline warning indicators.
class MedicationListScreen extends ConsumerStatefulWidget {
  const MedicationListScreen({super.key});

  @override
  ConsumerState<MedicationListScreen> createState() => _MedicationListScreenState();
}

class _MedicationListScreenState extends ConsumerState<MedicationListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final userId = currentUserId(ref);
      if (userId != null) {
        ref.read(medicationControllerProvider.notifier).fetchActiveMedications(userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AccessibilityTokens.of(context);
    final theme = Theme.of(context);
    
    final state = ref.watch(medicationControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add new medication schedule',
            onPressed: () {
              context.goNamed(RouteNames.medicationAdd);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Dynamic Offline sync warning banner
            if (state.offlineSyncNeeded)
              Semantics(
                liveRegion: true,
                child: Container(
                  color: theme.colorScheme.errorContainer,
                  padding: EdgeInsets.all(tokens.spaceSmall),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sync_problem, color: theme.colorScheme.onErrorContainer),
                      SizedBox(width: tokens.spaceSmall),
                      Text(
                        'Offline Mode. Doses logged locally, will sync when online.',
                        style: theme.textTheme.bodySmall!.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // 2. Main Medication List Area
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.medications.isEmpty
                      ? Center(
                          child: Padding(
                            padding: EdgeInsets.all(tokens.spaceLarge),
                            child: Text(
                              'No medications registered. Click the "+" button at the top to add your schedule.',
                              style: theme.textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: EdgeInsets.all(tokens.spaceMedium),
                          itemCount: state.medications.length,
                          itemBuilder: (context, index) {
                            final med = state.medications[index];

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: SemanticContainer(
                                mergeSemantics: true,
                                label: 'Medication name ${med.name}. Dosage is ${med.dosage}. Scheduled: ${med.cronSchedule}. Doctor notes: ${med.doctorNotes ?? "none"}.',
                                child: AccessibleCard(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              med.name,
                                              style: theme.textTheme.titleLarge!.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline),
                                            tooltip: 'Delete schedule',
                                            onPressed: () {
                                              final userId = currentUserId(ref);
                                              if (userId != null) {
                                                ref.read(medicationControllerProvider.notifier).deleteMedication(med.id, userId);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: tokens.spaceSmall),
                                      Text(
                                        'Dosage: ${med.dosage}',
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                      Text(
                                        'Schedule: ${med.cronSchedule}',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                      if (med.doctorNotes != null && med.doctorNotes!.isNotEmpty) ...[
                                        SizedBox(height: tokens.spaceSmall),
                                        Container(
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.surfaceVariant,
                                            borderRadius: BorderRadius.circular(tokens.buttonCornerRadius),
                                          ),
                                          padding: EdgeInsets.all(tokens.spaceSmall),
                                          child: Text(
                                            'Notes: ${med.doctorNotes}',
                                            style: theme.textTheme.bodyMedium,
                                          ),
                                        ),
                                      ],
                                      SizedBox(height: tokens.spaceMedium),

                                      // Actions Panel (WCAG AAA Tap Targets)
                                      AccessibleFocusGroup(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: AccessibleButton(
                                                onPressed: () {
                                                  ref.read(medicationControllerProvider.notifier).logCompliance(
                                                        medicationId: med.id,
                                                        scheduledTime: DateTime.now(),
                                                        status: 'TAKEN',
                                                      );
                                                },
                                                semanticLabel: 'Mark ${med.name} as taken.',
                                                child: const Text('TAKE'),
                                              ),
                                            ),
                                            SizedBox(width: tokens.spaceSmall),
                                            Expanded(
                                              child: AccessibleButton(
                                                style: AccessibleButtonStyle.outlined,
                                                onPressed: () {
                                                  ref.read(medicationControllerProvider.notifier).logCompliance(
                                                        medicationId: med.id,
                                                        scheduledTime: DateTime.now(),
                                                        status: 'SNOOZED',
                                                      );
                                                },
                                                semanticLabel: 'Snooze alert for ${med.name}.',
                                                child: const Text('SNOOZE'),
                                              ),
                                            ),
                                            SizedBox(width: tokens.spaceSmall),
                                            Expanded(
                                              child: AccessibleButton(
                                                style: AccessibleButtonStyle.text,
                                                onPressed: () {
                                                  ref.read(medicationControllerProvider.notifier).logCompliance(
                                                        medicationId: med.id,
                                                        scheduledTime: DateTime.now(),
                                                        status: 'MISSED',
                                                      );
                                                },
                                                semanticLabel: 'Skip this dose.',
                                                child: const Text('SKIP'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
