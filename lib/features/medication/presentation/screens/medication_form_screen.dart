import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/accessibility/widgets/accessible_focus_group.dart';
import '../../../../core/accessibility/widgets/accessible_focus_ring.dart';
import '../../../../core/theme/accessibility_tokens.dart';
import '../../../../core/widgets/accessible_button.dart';
import '../../../../core/widgets/accessible_text_field.dart';
import '../../domain/models/medication.dart';
import '../controllers/medication_controller.dart';

/// An Accessibility-First form screen to add new medications.
/// Key Features:
/// 1. Fields with persistent labels (WCAG AAA contrast sizes).
/// 2. Integrates optional Device Calendar toggles.
/// 3. Standardizes voice typing microphones.
class MedicationFormScreen extends ConsumerStatefulWidget {
  const MedicationFormScreen({super.key});

  @override
  ConsumerState<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends ConsumerState<MedicationFormScreen> {
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _notesController = TextEditingController();

  final FocusNode _nameFocus = FocusNode();
  final FocusNode _dosageFocus = FocusNode();
  final FocusNode _scheduleFocus = FocusNode();
  final FocusNode _notesFocus = FocusNode();

  bool _integrateCalendar = false;
  String? _voiceReminderPath;

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _scheduleController.dispose();
    _notesController.dispose();
    _nameFocus.dispose();
    _dosageFocus.dispose();
    _scheduleFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  void _saveMedication() {
    final name = _nameController.text.trim();
    final dosage = _dosageController.text.trim();
    final schedule = _scheduleController.text.trim();
    final notes = _notesController.text.trim();

    if (name.isEmpty || dosage.isEmpty || schedule.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out medication name, dosage, and schedule.')),
      );
      return;
    }

    final model = MedicationModel(
      id: const Uuid().v4(),
      userId: 'default-user-uid',
      name: name,
      dosage: dosage,
      cronSchedule: schedule,
      doctorNotes: notes.isEmpty ? null : notes,
      voiceReminderPath: _voiceReminderPath,
      createdAt: DateTime.now(),
    );

    ref.read(medicationControllerProvider.notifier).addMedication(
          model,
          integrateCalendar: _integrateCalendar,
        );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AccessibilityTokens.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spaceMedium),
          child: AccessibleFocusGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Name Input
                AccessibleFocusRing(
                  focusNode: _nameFocus,
                  child: AccessibleTextField(
                    controller: _nameController,
                    focusNode: _nameFocus,
                    label: 'Medication Name',
                    hintText: 'e.g. Aspirin',
                  ),
                ),
                SizedBox(height: tokens.spaceMedium),

                // 2. Dosage Input
                AccessibleFocusRing(
                  focusNode: _dosageFocus,
                  child: AccessibleTextField(
                    controller: _dosageController,
                    focusNode: _dosageFocus,
                    label: 'Dosage details',
                    hintText: 'e.g. 1 Tablet (50mg)',
                  ),
                ),
                SizedBox(height: tokens.spaceMedium),

                // 3. Frequency Schedule Input
                AccessibleFocusRing(
                  focusNode: _scheduleFocus,
                  child: AccessibleTextField(
                    controller: _scheduleController,
                    focusNode: _scheduleFocus,
                    label: 'Schedule frequency',
                    hintText: 'e.g. Daily at 08:00 AM',
                  ),
                ),
                SizedBox(height: tokens.spaceMedium),

                // 4. Notes Input
                AccessibleFocusRing(
                  focusNode: _notesFocus,
                  child: AccessibleTextField(
                    controller: _notesController,
                    focusNode: _notesFocus,
                    label: 'Doctor instructions (optional)',
                    hintText: 'e.g. Take with food.',
                  ),
                ),
                SizedBox(height: tokens.spaceMedium),

                // 5. Calendar integration toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Integrate with Native Calendar',
                      style: theme.textTheme.bodyLarge,
                    ),
                    Switch(
                      value: _integrateCalendar,
                      onChanged: (val) {
                        setState(() {
                          _integrateCalendar = val;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: tokens.spaceMedium),

                // 6. Voice voice recording reminder attachment mock
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Attach Voice Reminder',
                      style: theme.textTheme.bodyLarge,
                    ),
                    AccessibleButton(
                      style: AccessibleButtonStyle.outlined,
                      onPressed: () {
                        setState(() {
                          _voiceReminderPath = 'mock_voice_recording_${const Uuid().v4().substring(0, 5)}.mp3';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Attached voice reminder recording successfully.')),
                        );
                      },
                      semanticLabel: 'Record audio notification reminder.',
                      child: Text(_voiceReminderPath == null ? 'RECORD' : 'ATTACHED'),
                    ),
                  ],
                ),
                SizedBox(height: tokens.spaceXLarge),

                // 7. Submission
                AccessibleButton(
                  style: AccessibleButtonStyle.filled,
                  onPressed: _saveMedication,
                  semanticLabel: 'Save medication schedule.',
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Text('SAVE MEDICATION'),
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
