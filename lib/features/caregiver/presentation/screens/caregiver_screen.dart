import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/accessibility_tokens.dart';
import '../../../../core/widgets/accessible_card.dart';
import '../controllers/caregiver_controller.dart';

/// An Accessibility-First Caregiver Management Dashboard.
/// Key Features:
/// 1. Comprehensive lists of active caregiver relationships.
/// 2. Granular switches for privacy control settings (GPS, Medications, Battery alerts).
/// 3. Chronological visual timeline of recent logged events.
class CaregiverScreen extends ConsumerStatefulWidget {
  const CaregiverScreen({super.key});

  @override
  ConsumerState<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends ConsumerState<CaregiverScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(caregiverControllerProvider.notifier).loadCaregivers();
      ref.read(caregiverControllerProvider.notifier).loadTimeline();
    });
  }

  void _showAddCaregiverDialog() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Invite Caregiver'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Caregiver Name'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  keyboardType: TextInputType.phone,
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email Address (optional)'),
                  keyboardType: TextInputType.emailAddress,
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
                  ref.read(caregiverControllerProvider.notifier).inviteCaregiver(
                        name: nameController.text.trim(),
                        phone: phoneController.text.trim(),
                        email: emailController.text.isEmpty ? null : emailController.text.trim(),
                      );
                  Navigator.of(ctx).pop();
                }
              },
              child: const Text('SEND INVITATION'),
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

    final state = ref.watch(caregiverControllerProvider);
    final isLoading = state.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver Connections'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Invite new caregiver',
            onPressed: _showAddCaregiverDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(tokens.spaceMedium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Connected Caregivers Section
                    Text(
                      'Linked Caregivers',
                      style: theme.textTheme.titleLarge,
                    ),
                    SizedBox(height: tokens.spaceSmall),
                    if (state.caregivers.isEmpty)
                      AccessibleCard(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(tokens.spaceMedium),
                            child: Text(
                              'No caregivers linked yet. Tap the "+" button above to invite a caregiver.',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.caregivers.length,
                        itemBuilder: (context, index) {
                          final cg = state.caregivers[index];
                          final isPending = cg.status == 'PENDING';

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: AccessibleCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${cg.name} (${cg.status})',
                                          style: theme.textTheme.titleMedium!.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.link_off),
                                        tooltip: 'Remove connection',
                                        onPressed: () {
                                          ref.read(caregiverControllerProvider.notifier).deleteCaregiver(cg.caregiverId);
                                        },
                                      ),
                                    ],
                                  ),
                                  Text('Phone: ${cg.phone}', style: theme.textTheme.bodyMedium),
                                  if (cg.email != null)
                                    Text('Email: ${cg.email}', style: theme.textTheme.bodyMedium),
                                  
                                  const Divider(),
                                  Text(
                                    'Privacy Consents',
                                    style: theme.textTheme.titleSmall!.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  
                                  // Granular Privacy Controls
                                  SwitchListTile(
                                    title: const Text('Share Live GPS Location'),
                                    value: cg.shareGps,
                                    onChanged: isPending
                                        ? null
                                        : (val) {
                                            ref.read(caregiverControllerProvider.notifier).updatePermissions(
                                                  caregiverId: cg.caregiverId,
                                                  shareGps: val,
                                                  shareMeds: cg.shareMeds,
                                                  shareBattery: cg.shareBattery,
                                                  shareSosHistory: cg.shareSosHistory,
                                                );
                                          },
                                  ),
                                  SwitchListTile(
                                    title: const Text('Share Medication Log Compliance'),
                                    value: cg.shareMeds,
                                    onChanged: isPending
                                        ? null
                                        : (val) {
                                            ref.read(caregiverControllerProvider.notifier).updatePermissions(
                                                  caregiverId: cg.caregiverId,
                                                  shareGps: cg.shareGps,
                                                  shareMeds: val,
                                                  shareBattery: cg.shareBattery,
                                                  shareSosHistory: cg.shareSosHistory,
                                                );
                                          },
                                  ),
                                  SwitchListTile(
                                    title: const Text('Share Battery Low Alerts'),
                                    value: cg.shareBattery,
                                    onChanged: isPending
                                        ? null
                                        : (val) {
                                            ref.read(caregiverControllerProvider.notifier).updatePermissions(
                                                  caregiverId: cg.caregiverId,
                                                  shareGps: cg.shareGps,
                                                  shareMeds: cg.shareMeds,
                                                  shareBattery: val,
                                                  shareSosHistory: cg.shareSosHistory,
                                                );
                                          },
                                  ),
                                  SwitchListTile(
                                    title: const Text('Share Emergency SOS History'),
                                    value: cg.shareSosHistory,
                                    onChanged: isPending
                                        ? null
                                        : (val) {
                                            ref.read(caregiverControllerProvider.notifier).updatePermissions(
                                                  caregiverId: cg.caregiverId,
                                                  shareGps: cg.shareGps,
                                                  shareMeds: cg.shareMeds,
                                                  shareBattery: cg.shareBattery,
                                                  shareSosHistory: val,
                                                );
                                          },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    SizedBox(height: tokens.spaceLarge),

                    // 2. Activity Timeline Section
                    Text(
                      'Recent Activity Timeline',
                      style: theme.textTheme.titleLarge,
                    ),
                    SizedBox(height: tokens.spaceSmall),
                    if (state.timelineEvents.isEmpty)
                      const Text('No recent activity recorded.')
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: state.timelineEvents.length,
                        itemBuilder: (context, index) {
                          final event = state.timelineEvents[index];

                          IconData icon;
                          Color color;
                          switch (event.type) {
                            case 'MEDICATION':
                              icon = Icons.medication;
                              color = Colors.green;
                              break;
                            case 'BATTERY':
                              icon = Icons.battery_alert;
                              color = Colors.orange;
                              break;
                            case 'SOS':
                              icon = Icons.warning;
                              color = Colors.red;
                              break;
                            default:
                              icon = Icons.info;
                              color = Colors.blue;
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.15),
                                child: Icon(icon, color: color),
                              ),
                              title: Text(event.title, style: theme.textTheme.titleMedium),
                              subtitle: Text(event.description),
                              trailing: Text(
                                '${event.timestamp.hour}:${event.timestamp.minute.toString().padLeft(2, '0')}',
                                style: theme.textTheme.bodySmall,
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
