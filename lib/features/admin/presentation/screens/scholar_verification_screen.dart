import 'package:flutter/material.dart';
import '../../data/repositories/admin_repository.dart';
import '../../domain/models/admin_models.dart';

/// Scholar Verification Admin Screen
class ScholarVerificationScreen extends StatefulWidget {
  const ScholarVerificationScreen({super.key});

  @override
  State<ScholarVerificationScreen> createState() => _ScholarVerificationScreenState();
}

class _ScholarVerificationScreenState extends State<ScholarVerificationScreen> {
  final _adminRepository = AdminRepository();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScholarVerificationApplication>>(
      stream: _adminRepository.getPendingScholarApplications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final applications = snapshot.data ?? [];

        if (applications.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.school_outlined,
                  size: 48,
                  color: Colors.blue[300],
                ),
                const SizedBox(height: 12),
                const Text('No pending scholar verification applications'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: applications.length,
          itemBuilder: (context, index) {
            final application = applications[index];
            return _buildScholarCard(context, application);
          },
        );
      },
    );
  }

  Widget _buildScholarCard(BuildContext context, ScholarVerificationApplication app) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(app.displayName),
        subtitle: Text(app.email),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          _buildDetailSection(context, 'Application Details', [
            ('Email', app.email),
            ('Submitted', app.submittedDate.toString().split('.')[0]),
            ('Status', _getApplicationStatus(app.status)),
          ]),
          const SizedBox(height: 16),
          if (app.schoolIdUrl.isNotEmpty) ...[
            const Text(
              'Uploaded Student ID',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                app.schoolIdUrl,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: Colors.grey[200],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () => _showRejectDialog(context, app.userId),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text('Reject'),
              ),
              const SizedBox(width: 12),
              FilledButton(
                onPressed: () => _approveApplication(app.userId),
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
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(item.$1),
                Expanded(
                  child: Text(
                    item.$2,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> _approveApplication(String userId) async {
    try {
      await _adminRepository.approveScholarApplication(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scholar application approved.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showRejectDialog(BuildContext context, String userId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Scholar Application'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Optional rejection reason',
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
              _rejectApplication(userId, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Future<void> _rejectApplication(String userId, String reason) async {
    try {
      await _adminRepository.rejectScholarApplication(userId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scholar application rejected.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _getApplicationStatus(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.approved:
        return 'Approved';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }
}
