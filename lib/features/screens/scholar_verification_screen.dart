import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../auth/presentation/auth_state.dart';

class ScholarVerificationScreen extends StatefulWidget {
  const ScholarVerificationScreen({super.key});

  @override
  State<ScholarVerificationScreen> createState() => _ScholarVerificationScreenState();
}

class _ScholarVerificationScreenState extends State<ScholarVerificationScreen> {
  bool _agreedToTerms = false;
  bool _isUploading = false;
  String? _uploadedIdUrl;

  void _handleUpload() async {
    setState(() => _isUploading = true);
    // Mock upload delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isUploading = false;
        _uploadedIdUrl = 'https://example.com/mock-school-id.jpg';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School ID uploaded successfully!')),
      );
    }
  }

  void _submitApplication() async {
    if (_uploadedIdUrl == null || !_agreedToTerms) return;

    final auth = context.read<AuthState>();
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      await auth.submitScholarVerification(schoolIdUrl: _uploadedIdUrl!);
      
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Scholar application submitted for review!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/profile');
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading
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
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.black54,
                      ),
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
                      onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
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
          _buildBenefitItem(Icons.percent, 'Exclusive Discounts', 'Up to 20% off on selected artworks.'),
          const Divider(height: 24),
          _buildBenefitItem(Icons.star_outline, 'Scholar Badge', 'Showcase your student status on your profile.'),
          const Divider(height: 24),
          _buildBenefitItem(Icons.event_available, 'Early Access', 'Get first dibs on new collection launches.'),
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
              Text(subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
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
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 48),
                      const SizedBox(height: 12),
                      const Text('School ID Ready', style: TextStyle(fontWeight: FontWeight.bold)),
                      TextButton(onPressed: _handleUpload, child: const Text('Change Photo')),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.cloud_upload_outlined, color: Colors.black26, size: 48),
                      SizedBox(height: 12),
                      Text('Tap to upload School ID', style: TextStyle(color: Colors.black54)),
                      Text('(JPG, PNG up to 5MB)', style: TextStyle(color: Colors.black26, fontSize: 12)),
                    ],
                  ),
      ),
    );
  }
}
