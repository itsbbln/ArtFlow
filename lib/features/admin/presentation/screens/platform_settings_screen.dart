import 'package:flutter/material.dart';
import '../../data/repositories/admin_repository.dart';
import '../../domain/models/admin_models.dart';

/// Platform Settings Screen
class PlatformSettingsScreen extends StatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  State<PlatformSettingsScreen> createState() => _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends State<PlatformSettingsScreen> {
  final _adminRepository = AdminRepository();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PlatformSettings>(
      future: _adminRepository.getPlatformSettings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final settings = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Platform Fee Section
              _buildSectionCard(
                context,
                '💰 Platform Fee',
                Column(
                  children: [
                    ListTile(
                      title: const Text('Commission Fee %'),
                      trailing: Text(
                        '${settings.platformFeePercentage}%',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Slider(
                        value: settings.platformFeePercentage,
                        min: 0,
                        max: 20,
                        divisions: 40,
                        label: '${settings.platformFeePercentage.toStringAsFixed(1)}%',
                        onChanged: (value) async {
                          await _adminRepository.updatePlatformFee(value);
                          setState(() {});
                        },
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'This percentage is charged on each transaction to cover platform costs.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Categories Section
              _buildSectionCard(
                context,
                '🎨 Art Categories',
                Column(
                  children: [
                    ...settings.categories
                        .map((category) => ListTile(
                              leading: const Icon(Icons.category),
                              title: Text(category.name),
                              subtitle: Text('Style: ${category.style}'),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Category editing coming soon'),
                                    ),
                                  );
                                },
                              ),
                            ))
                        .toList(),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FilledButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Add new category coming soon'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Category'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Regions Section
              _buildSectionCard(
                context,
                '🌍 Regions',
                Column(
                  children: [
                    ...settings.regions
                        .map((region) => ListTile(
                              leading: const Icon(Icons.location_on),
                              title: Text(region.name),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Region editing coming soon'),
                                    ),
                                  );
                                },
                              ),
                            ))
                        .toList(),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: FilledButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Add new region coming soon'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Region'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Notification Settings
              _buildSectionCard(
                context,
                '🔔 Notifications',
                Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable System Notifications'),
                      value: settings.notificationsEnabled,
                      onChanged: (value) async {
                        await _adminRepository.toggleNotifications(value);
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // System Announcement
              _buildSectionCard(
                context,
                '📢 System Announcement',
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Current Announcement:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              settings.systemAnnouncement.isEmpty
                                  ? 'No announcement currently set'
                                  : settings.systemAnnouncement,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FilledButton(
                            onPressed: () => _showAnnouncementDialog(context),
                            child: const Text('Update Announcement'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionCard(BuildContext context, String title, Widget content) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          content,
        ],
      ),
    );
  }

  void _showAnnouncementDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update System Announcement'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter announcement message',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              await _adminRepository.updateSystemAnnouncement(controller.text);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Announcement updated')),
                );
                setState(() {});
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
