import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../data/repositories/admin_repository.dart';
import '../../domain/models/admin_models.dart';

/// Artist Verification Management Screen
class ArtistVerificationScreen extends StatefulWidget {
  const ArtistVerificationScreen({super.key});

  @override
  State<ArtistVerificationScreen> createState() =>
      _ArtistVerificationScreenState();
}

class _ArtistVerificationScreenState extends State<ArtistVerificationScreen> {
  final _adminRepository = AdminRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ArtistVerificationApplication>>(
      stream: _adminRepository.getPendingApplications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final applications = snapshot.data ?? [];

        if (applications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: Colors.green[300],
                ),
                const SizedBox(height: 12),
                const Text('No pending artist applications'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final app = applications[index];
            return _buildApplicationCard(context, app);
          },
        );
      },
    );
  }

  Widget _buildApplicationCard(
    BuildContext context,
    ArtistVerificationApplication app,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(app.displayName),
        subtitle: Text(app.email),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          // Applicant details
          _buildDetailSection(context, 'Applicant Information', [
            ('Email', app.email),
            ('Art Style', app.artStyle),
            ('Medium', app.medium),
            ('Submitted', app.submittedDate.toString().split('.')[0]),
          ]),
          if (app.experience.isNotEmpty) ...[
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Experience',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(app.experience),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          // Bio
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Bio', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(app.bio),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Portfolio samples
          if (app.sampleArtworks.isNotEmpty) ...[
            const Text(
              'Portfolio Samples',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: app.sampleArtworks.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 120,
                      height: 120,
                      child: _ApplicationImage(
                        source: app.sampleArtworks[index],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Identity verification
          if (app.identityVerificationUrl.isNotEmpty) ...[
            const Text(
              'Identity Verification',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 200,
                child: _ApplicationImage(source: app.identityVerificationUrl),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () =>
                    _showRejectDialog(context, app.applicationId, app.userId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Reject'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () =>
                    _approveApplication(app.applicationId, app.userId),
                child: const Text('Approve'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSection(
    BuildContext context,
    String title,
    List<(String label, String value)> items,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.$1),
                Text(
                  item.$2,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _approveApplication(String applicationId, String userId) async {
    try {
      await _adminRepository.approveArtistApplication(applicationId, userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Artist approved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showRejectDialog(
    BuildContext context,
    String applicationId,
    String userId,
  ) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Application'),
        content: TextField(
          controller: reasonController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter rejection reason (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              _rejectApplication(applicationId, userId, reasonController.text);
              Navigator.pop(context);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectApplication(
    String applicationId,
    String userId,
    String reason,
  ) async {
    try {
      await _adminRepository.rejectArtistApplication(
        applicationId,
        userId,
        reason,
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Application rejected')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}

class _ApplicationImage extends StatelessWidget {
  const _ApplicationImage({required this.source});

  final String source;

  @override
  Widget build(BuildContext context) {
    if (source.startsWith('data:image/')) {
      final bytes = Uint8List.fromList(UriData.parse(source).contentAsBytes());
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(),
      );
    }

    return Image.network(
      source,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imageFallback(),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.image_not_supported),
    );
  }
}
