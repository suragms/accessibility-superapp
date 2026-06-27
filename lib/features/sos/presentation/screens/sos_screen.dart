import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/accessibility/widgets/accessible_focus_group.dart';
import '../../../../core/accessibility/widgets/accessible_focus_ring.dart';
import '../../../../core/accessibility/widgets/semantic_container.dart';
import '../../../../core/theme/accessibility_tokens.dart';
import '../../../../core/widgets/accessible_card.dart';
import '../controllers/sos_controller.dart';

/// An Accessibility-First Emergency SOS Dashboard.
/// Key Features:
/// 1. Flashing large red alert buttons with haptic focus anchors.
/// 2. Medical card display panel for quick references by paramedics.
/// 3. Offline backup warnings and battery percentage readouts.
class SosScreen extends ConsumerStatefulWidget {
  const SosScreen({super.key});

  @override
  ConsumerState<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends ConsumerState<SosScreen> {
  final FocusNode _sosBtnFocus = FocusNode();
  final FocusNode _contactsFocus = FocusNode();

  @override
  void dispose() {
    _sosBtnFocus.dispose();
    _contactsFocus.dispose();
    super.dispose();
  }

  void _showAddContactDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();
    bool isPrimary = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Emergency Contact'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: relationController,
                  decoration: const InputDecoration(labelText: 'Relationship (e.g. Spouse)'),
                ),
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return CheckboxListTile(
                      title: const Text('Set as Primary Contact'),
                      value: isPrimary,
                      onChanged: (val) {
                        setDialogState(() {
                          isPrimary = val ?? false;
                        });
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                  ref.read(sosControllerProvider.notifier).addContact(
                        name: nameController.text.trim(),
                        phone: phoneController.text.trim(),
                        relationship: relationController.text.trim(),
                        isPrimary: isPrimary,
                      );
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  void _showEditMedicalCardDialog() {
    final bloodController = TextEditingController(text: ref.read(sosControllerProvider).medicalCard?.bloodType ?? 'O+');
    final allergyController = TextEditingController(text: ref.read(sosControllerProvider).medicalCard?.allergies);
    final medController = TextEditingController(text: ref.read(sosControllerProvider).medicalCard?.medications);
    final notesController = TextEditingController(text: ref.read(sosControllerProvider).medicalCard?.emergencyNotes);

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Medical Card'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: bloodController,
                  decoration: const InputDecoration(labelText: 'Blood Type (e.g. O+)'),
                ),
                TextField(
                  controller: allergyController,
                  decoration: const InputDecoration(labelText: 'Allergies'),
                ),
                TextField(
                  controller: medController,
                  decoration: const InputDecoration(labelText: 'Current Medications'),
                ),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'Emergency Notes / Instructions'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('CANCEL'),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(sosControllerProvider.notifier).saveMedicalCard(
                      bloodType: bloodController.text.trim(),
                      allergies: allergyController.text.trim(),
                      medications: medController.text.trim(),
                      notes: notesController.text.trim(),
                    );
                Navigator.of(ctx).pop();
              },
              child: const Text('SAVE'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AccessibilityTokens.of(context);
    final theme = Theme.of(context);
    
    final state = ref.watch(sosControllerProvider);
    final isTriggered = state.isSosTriggered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency SOS Center'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(tokens.spaceMedium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Red Alert Button
              AccessibleFocusRing(
                focusNode: _sosBtnFocus,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: isTriggered ? theme.colorScheme.error : Colors.red[900],
                    borderRadius: BorderRadius.circular(tokens.cardCornerRadius),
                    boxShadow: isTriggered
                        ? [
                            BoxShadow(
                              color: theme.colorScheme.error.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            )
                          ]
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (isTriggered) {
                          ref.read(sosControllerProvider.notifier).cancelEmergencySos();
                        } else {
                          ref.read(sosControllerProvider.notifier).triggerEmergencySos();
                        }
                      },
                      focusNode: _sosBtnFocus,
                      borderRadius: BorderRadius.circular(tokens.cardCornerRadius),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.white),
                            SizedBox(height: tokens.spaceSmall),
                            Text(
                              isTriggered ? 'CANCEL EMERGENCY SOS' : 'TRIGGER EMERGENCY SOS',
                              style: theme.textTheme.titleLarge!.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: tokens.spaceMedium),

              if (state.statusMessage != null)
                SemanticContainer(
                  isLiveRegion: true,
                  child: Container(
                    color: theme.colorScheme.errorContainer,
                    padding: EdgeInsets.all(tokens.spaceSmall),
                    child: Text(
                      state.statusMessage!,
                      style: theme.textTheme.bodyLarge!.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              SizedBox(height: tokens.spaceMedium),

              // 2. Hardware Status Indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Battery: ${state.batteryLevel.toStringAsFixed(0)}%', style: theme.textTheme.bodyLarge),
                  Text('GPS: ${state.lastKnownLocation ?? "Acquiring..."}', style: theme.textTheme.bodyMedium),
                ],
              ),
              const Divider(),
              SizedBox(height: tokens.spaceSmall),

              // 3. Medical Card Panel
              AccessibleCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Medical Card', style: theme.textTheme.titleLarge),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit medical notes',
                          onPressed: _showEditMedicalCardDialog,
                        ),
                      ],
                    ),
                    SizedBox(height: tokens.spaceSmall),
                    Text('Blood Type: ${state.medicalCard?.bloodType ?? "Unspecified"}', style: theme.textTheme.bodyLarge),
                    Text('Allergies: ${state.medicalCard?.allergies ?? "None reported"}', style: theme.textTheme.bodyMedium),
                    Text('Medications: ${state.medicalCard?.medications ?? "None reported"}', style: theme.textTheme.bodyMedium),
                    if (state.medicalCard?.emergencyNotes != null) ...[
                      SizedBox(height: tokens.spaceSmall),
                      Text('Instructions: ${state.medicalCard!.emergencyNotes!}', style: theme.textTheme.bodyMedium),
                    ],
                  ],
                ),
              ),
              SizedBox(height: tokens.spaceMedium),

              // 4. Emergency Contacts Registry
              AccessibleFocusGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Emergency Contacts', style: theme.textTheme.titleLarge),
                        IconButton(
                          icon: const Icon(Icons.person_add_alt),
                          tooltip: 'Register contact',
                          onPressed: _showAddContactDialog,
                        ),
                      ],
                    ),
                    SizedBox(height: tokens.spaceSmall),
                    if (state.contacts.isEmpty)
                      const Text('No emergency contacts registered.')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.contacts.length,
                        itemBuilder: (context, index) {
                          final contact = state.contacts[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              title: Text('${contact.name} (${contact.relationship})'),
                              subtitle: Text(contact.phone),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (contact.isPrimary)
                                    const Icon(Icons.star, color: Colors.amber)
                                  else
                                    const SizedBox.shrink(),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      ref.read(sosControllerProvider.notifier).deleteContact(contact.id);
                                    },
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
            ],
          ),
        ),
      ),
    );
  }
}
