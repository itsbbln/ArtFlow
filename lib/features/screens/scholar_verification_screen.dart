import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../auth/presentation/auth_state.dart';
import '../shared/data/supabase_image_service.dart';

class ScholarVerificationScreen extends StatefulWidget {
  const ScholarVerificationScreen({super.key});

  @override
  State<ScholarVerificationScreen> createState() =>
      _ScholarVerificationScreenState();
}

class _ScholarVerificationScreenState extends State<ScholarVerificationScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  static const _imageService = SupabaseImageService();

  bool _agreedToTerms = false;
  bool _isUploading = false;
  String? _uploadedIdUrl;
  Uint8List? _uploadedIdBytes;

  Future<void> _handleUpload() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null || !mounted) {
      return;
    }
    final bytes = await picked.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() => _isUploading = true);
    final auth = context.read<AuthState>();

    try {
      final userId = auth.currentUserId;
      if (userId == null || userId.isEmpty) {
        throw StateError(
          'You need to sign in before uploading your school ID.',
        );
      }
      if (!_imageService.isConfigured) {
        throw StateError(
          'Supabase image upload is not configured yet. Fill the Supabase values in .env first.',
        );
      }
      final extension = picked.path.contains('.')
          ? picked.path.split('.').last.toLowerCase()
          : 'jpg';
      final uploadedUrl = await _imageService.uploadScholarVerificationImage(
        userId: userId,
        bytes: bytes,
        fileExtension: extension,
      );
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadedIdUrl = uploadedUrl;
          _uploadedIdBytes = bytes;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('School ID uploaded successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e is StateError ? e.message : 'Upload failed.'),
          ),
        );
      }
    }
  }

  Future<void> _submitApplication() async {
    if (_uploadedIdUrl == null || !_agreedToTerms) {
      return;
    }

    final auth = context.read<AuthState>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await auth.submitScholarVerification(schoolIdUrl: _uploadedIdUrl!);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scholar application submitted for review!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/profile');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              const Color(0xFFFAEBDC).withOpacity(0.6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.school_outlined,
                  size: 48,
                  color: Color(0xFFB71B1B),
                ),
                const SizedBox(height: 16),
                Text(
                  'Apply for Scholar Tier',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Get exclusive benefits and discounts as a verified student artist or collector.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 32),

                _buildInfoCard(),

                const SizedBox(height: 32),

                Text(
                  'Upload School ID',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildUploadSection(),

                const SizedBox(height: 32),

                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (v) =>
                          setState(() => _agreedToTerms = v ?? false),
                    ),
                    const Expanded(
                      child: Text(
                        'I certify that the uploaded ID is valid and belongs to me.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: (_uploadedIdUrl != null && _agreedToTerms)
                        ? _submitApplication
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB71B1B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit Application',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildBenefitItem(
            Icons.percent,
            'Exclusive Discounts',
            'Up to 20% off on selected artworks.',
          ),
          const Divider(height: 24),
          _buildBenefitItem(
            Icons.star_outline,
            'Scholar Badge',
            'Showcase your student status on your profile.',
          ),
          const Divider(height: 24),
          _buildBenefitItem(
            Icons.event_available,
            'Early Access',
            'Get first dibs on new collection launches.',
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFB71B1B), size: 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUploadSection() {
    return GestureDetector(
      onTap: _isUploading ? null : _handleUpload,
      child: Container(
        width: double.infinity,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _uploadedIdUrl != null ? Colors.green : Colors.black12,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: _isUploading
            ? const Center(child: CircularProgressIndicator())
            : _uploadedIdUrl != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  if (_uploadedIdBytes != null)
                    Image.memory(_uploadedIdBytes!, fit: BoxFit.cover)
                  else
                    Image.network(
                      _uploadedIdUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          size: 42,
                        ),
                      ),
                    ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: FilledButton.tonal(
                      onPressed: _handleUpload,
                      child: const Text('Replace'),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.cloud_upload_outlined,
                    color: Colors.black26,
                    size: 48,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Tap to upload School ID',
                    style: TextStyle(color: Colors.black54),
                  ),
                  Text(
                    '(JPG, PNG up to 5MB)',
                    style: TextStyle(color: Colors.black26, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }
}
