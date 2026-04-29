import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_shadows.dart';
import '../../core/theme/editorial_colors.dart';
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
      if (!mounted) {
        return;
      }
      setState(() {
        _isUploading = false;
        _uploadedIdUrl = uploadedUrl;
        _uploadedIdBytes = bytes;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('School ID uploaded successfully!')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isUploading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e is StateError ? e.message : 'Upload failed.'),
        ),
      );
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

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scholar application submitted for review!'),
          backgroundColor: Colors.green,
        ),
      );
      context.go('/profile');
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _isUploading = false);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EditorialColors.pageCream,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: EditorialColors.ink,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: ClipPath(
              clipper: _ScholarHeroClip(),
              child: SizedBox(
                height: 200,
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        EditorialColors.tribalMaroon,
                        EditorialColors.tribalRed.withValues(alpha: 0.96),
                        EditorialColors.tribalGold.withValues(alpha: 0.92),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(24, 56, 24, 50),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha: 0.2),
                            borderRadius:
                                BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.42),
                            ),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Scholar tier',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.8,
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Verify your student ID',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  height: 1.12,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Student artists and collectors unlock curated perks.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      height: 1.5,
                      color: EditorialColors.muted.withValues(alpha: 0.95),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const _BenefitCarousel(),
                  const SizedBox(height: 26),
                  Text(
                    'Upload school ID',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: EditorialColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'JPG / PNG • clear corners • matches your registered name.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: EditorialColors.muted.withValues(alpha: 0.9),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _buildUploadSection(),
                  const SizedBox(height: 22),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: AppRadii.circularXl(),
                      border: Border.all(color: EditorialColors.border),
                      boxShadow: AppShadows.card,
                    ),
                    child: CheckboxListTile(
                      value: _agreedToTerms,
                      onChanged: (v) =>
                          setState(() => _agreedToTerms = v ?? false),
                      title: Text(
                        'This ID belongs to me and is valid.',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          height: 1.38,
                          color: EditorialColors.charcoal,
                          fontSize: 14,
                        ),
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppRadii.circularXl(),
                      ),
                      checkColor: Colors.white,
                      fillColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? EditorialColors.tribalRed
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      onPressed: (_uploadedIdUrl != null && _agreedToTerms)
                          ? _submitApplication
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: EditorialColors.tribalRed,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Submit scholar application',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadSection() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.circularLg(),
        onTap: _isUploading ? null : _handleUpload,
        child: Ink(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AppRadii.circularLg(),
            border: Border.all(
              color: _uploadedIdUrl != null
                  ? const Color(0xFF2E9D62)
                  : EditorialColors.border,
              width: 2,
            ),
            boxShadow: AppShadows.card,
          ),
          child: _isUploading
              ? const Center(child: CircularProgressIndicator())
              : _uploadedIdUrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_uploadedIdBytes != null)
                          ClipRRect(
                            borderRadius: AppRadii.circularMd(),
                            child:
                                Image.memory(_uploadedIdBytes!, fit: BoxFit.cover),
                          )
                        else
                          ClipRRect(
                            borderRadius: AppRadii.circularMd(),
                            child: Image.network(
                              _uploadedIdUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color:
                                    EditorialColors.parchmentDeep,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 42,
                                ),
                              ),
                            ),
                          ),
                        Positioned(
                          right: 14,
                          top: 14,
                          child: FilledButton.tonal(
                            onPressed: _handleUpload,
                            child: const Text('Replace'),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_camera_front_rounded,
                          color: EditorialColors.tribalRed.withValues(alpha: 0.82),
                          size: 44,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tap to upload · school ID visible',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '(JPG, PNG)',
                          style: GoogleFonts.inter(
                            color: EditorialColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
        ),
      ),
    );
  }
}

class _BenefitCarousel extends StatelessWidget {
  const _BenefitCarousel();

  @override
  Widget build(BuildContext context) {
    const rows = [
      (
        Icons.local_offer_rounded,
        'Stacked discounts',
        'Up to 20% on curated drops.',
      ),
      (
        Icons.workspace_premium_outlined,
        'Scholar laurel',
        'Visible badge beside your username.',
      ),
      (
        Icons.rocket_launch_rounded,
        'First access',
        'Collection launches unlocked earlier.',
      ),
    ];

    return Column(
      children: rows.map((tuple) {
        final (ic, t, s) = tuple;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: EditorialColors.border.withValues(alpha: 0.9)),
              boxShadow: AppShadows.card,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: EditorialColors.tribalRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(ic, color: EditorialColors.tribalRed),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            height: 1.4,
                            color: EditorialColors.muted,
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
      }).toList(),
    );
  }
}

class _ScholarHeroClip extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 42);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height + 28,
      size.width,
      size.height - 42,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
