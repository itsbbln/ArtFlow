import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_shadows.dart';
import '../../core/theme/editorial_colors.dart';
import '../auth/presentation/auth_state.dart';
import '../shared/data/supabase_image_service.dart';

class BecomeArtistScreen extends StatefulWidget {
  const BecomeArtistScreen({super.key});

  @override
  State<BecomeArtistScreen> createState() => _BecomeArtistScreenState();
}

class _BecomeArtistScreenState extends State<BecomeArtistScreen> {
  final _styleController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  String? _selectedMedium;
  _PendingUploadImage? _identityVerificationImage;
  final List<_PendingUploadImage> _sampleArtworks = <_PendingUploadImage>[];
  bool _agreeToTerms = false;
  bool _isSubmitting = false;
  int _currentStep = 0;
  bool _seededFromExistingApplication = false;

  static const _imageService = SupabaseImageService();

  static const _mediums = [
    'Painting',
    'Digital Art',
    'Photography',
    'Sculpture',
    'Illustration',
    'Mixed Media',
    'Printmaking',
    'Other',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_seededFromExistingApplication) {
      return;
    }
    final application = context.read<AuthState>().currentArtistApplication;
    if (application != null) {
      _selectedMedium = application.medium.isEmpty ? null : application.medium;
      _styleController.text = application.artStyle;
      _bioController.text = application.bio;
      _experienceController.text = application.experience;
      _sampleArtworks
        ..clear()
        ..addAll(application.sampleArtworks.map(_PendingUploadImage.remote));
      _identityVerificationImage = application.identityVerificationUrl.isEmpty
          ? null
          : _PendingUploadImage.remote(application.identityVerificationUrl);
    }
    _seededFromExistingApplication = true;
  }

  @override
  void dispose() {
    _styleController.dispose();
    _bioController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  bool _isStepValid(int step) {
    switch (step) {
      case 0:
        return _selectedMedium != null;
      case 1:
        return _styleController.text.trim().isNotEmpty &&
            _bioController.text.trim().isNotEmpty &&
            _sampleArtworks.isNotEmpty;
      case 2:
        return _experienceController.text.trim().isNotEmpty &&
            _identityVerificationImage != null &&
            _agreeToTerms;
      default:
        return false;
    }
  }

  Future<void> _pickPortfolioImage() async {
    if (_sampleArtworks.length >= 4) {
      _showMessage('You can upload up to 4 portfolio samples.');
      return;
    }
    final image = await _pickUploadImage();
    if (image == null || !mounted) {
      return;
    }
    setState(() => _sampleArtworks.add(image));
  }

  Future<void> _pickIdentityImage() async {
    final image = await _pickUploadImage();
    if (image == null || !mounted) {
      return;
    }
    setState(() => _identityVerificationImage = image);
  }

  Future<_PendingUploadImage?> _pickUploadImage() async {
    final source = await _showImageSourceSheet();
    if (source == null) {
      return null;
    }
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked == null) {
      return null;
    }
    final bytes = await picked.readAsBytes();
    final extension = picked.path.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };
    return _PendingUploadImage.local(
      previewSource: UriData.fromBytes(bytes, mimeType: mimeType).toString(),
      bytes: bytes,
      extension: extension,
    );
  }

  Future<ImageSource?> _showImageSourceSheet() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitApplication() async {
    if (!_isStepValid(0) || !_isStepValid(1) || !_isStepValid(2)) {
      _showMessage('Please complete all required steps first.');
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userId = context.read<AuthState>().currentUserId;
      if (userId == null || userId.isEmpty) {
        throw StateError(
          'You need to sign in before uploading application images.',
        );
      }
      if (!_imageService.isConfigured) {
        throw StateError(
          'Supabase image upload is not configured yet. Fill the Supabase values in .env first.',
        );
      }
      final uploadedSamples = <String>[];
      for (var i = 0; i < _sampleArtworks.length; i++) {
        uploadedSamples.add(
          await _sampleArtworks[i].resolveUrl(
            uploader: (bytes, extension) =>
                _imageService.uploadArtistApplicationImage(
                  userId: userId,
                  assetId: 'sample-$i',
                  bytes: bytes,
                  fileExtension: extension,
                ),
          ),
        );
      }
      final uploadedIdentity = await _identityVerificationImage!.resolveUrl(
        uploader: (bytes, extension) =>
            _imageService.uploadArtistApplicationImage(
              userId: userId,
              assetId: 'identity',
              bytes: bytes,
              fileExtension: extension,
            ),
      );
      await context.read<AuthState>().submitArtistApplication(
        bio: _bioController.text.trim(),
        style: _styleController.text.trim(),
        medium: _selectedMedium!,
        experience: _experienceController.text.trim(),
        sampleArtworks: uploadedSamples,
        identityVerificationUrl: uploadedIdentity,
      );
      if (!mounted) {
        return;
      }
      _showMessage(
        'Application submitted. Our team will review it and update your status soon.',
      );
      context.go('/verification');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage('Unable to submit your application right now.');
      debugPrint('Artist application submission failed: $error');
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final application = auth.currentArtistApplication;

    if (auth.hasPendingArtistApplication) {
      return _StatusScaffold(
        icon: Icons.pending_actions_outlined,
        iconColor: Colors.orange,
        title: 'Application Pending',
        description:
            'Your artist verification is under review. We will notify you once the admin team finishes checking your portfolio and identity document.',
        buttonLabel: 'View Status',
        onPressed: () => context.go('/verification'),
      );
    }

    if (auth.isVerifiedArtist) {
      return _StatusScaffold(
        icon: Icons.verified_user_outlined,
        iconColor: Colors.green,
        title: 'Already Verified',
        description:
            'Your artist account is already approved. You can upload artworks and accept commissions now.',
        buttonLabel: 'Go to Profile',
        onPressed: () => context.go('/profile'),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _isSubmitting ? null : () => context.pop(),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              EditorialColors.pageCream,
              BukidnonGradients.pageAmbient.colors.last.withValues(alpha: 0.98),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: EditorialColors.border),
                  boxShadow: AppShadows.raised,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  EditorialColors.tribalRed.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.brush_rounded,
                                color: EditorialColors.tribalRed,
                                size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Creator application',
                                  style: GoogleFonts.playfairDisplay(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 21,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Step ${_currentStep + 1} of 3 · takes about five minutes.',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: EditorialColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: (_currentStep + 1) / 3,
                          minHeight: 8,
                          backgroundColor:
                              EditorialColors.parchmentDeep.withValues(alpha: 0.72),
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(
                            EditorialColors.tribalRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              if (application?.isRejected == true) ...[
                const SizedBox(height: 20),
                _InfoBox(
                  icon: Icons.feedback_outlined,
                  title: 'Previous application feedback',
                  description: application!.rejectionReason.trim().isEmpty
                      ? 'Your last submission needs a stronger portfolio or clearer verification details. Update the application below and resubmit it.'
                      : application.rejectionReason.trim(),
                  tone: _InfoTone.warning,
                ),
              ],
              const SizedBox(height: 32),
              _StepIndicator(currentStep: _currentStep),
              const SizedBox(height: 32),
              if (_currentStep == 0) ...[
                Text(
                  'What is your primary art medium? *',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _mediums.map((medium) {
                    final selected = _selectedMedium == medium;
                    return FilterChip(
                      selected: selected,
                      label: Text(medium),
                      backgroundColor: Colors.white,
                      selectedColor: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.2),
                      side: BorderSide(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : const Color(0xFFE4D8CB),
                        width: selected ? 1.5 : 1,
                      ),
                      onSelected: (value) {
                        setState(() => _selectedMedium = value ? medium : null);
                      },
                    );
                  }).toList(),
                ),
              ],
              if (_currentStep == 1) ...[
                _LabeledTextField(
                  controller: _styleController,
                  label: 'Tell us about your artistic style *',
                  hintText: 'e.g., Contemporary portraiture, digital collage',
                  minLines: 1,
                  maxLines: 2,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 20),
                _LabeledTextField(
                  controller: _bioController,
                  label: 'About your art and creative journey *',
                  hintText:
                      'Share your inspiration, process, background, and what makes your work unique.',
                  minLines: 4,
                  maxLines: 6,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_bioController.text.length}/500 characters',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 20),
                Text(
                  'Portfolio samples *',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload at least one sample. Up to four images are supported.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  height: 110,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _UploadTile(
                        label: 'Add Sample',
                        icon: Icons.add_photo_alternate_outlined,
                        onTap: _pickPortfolioImage,
                      ),
                      ..._sampleArtworks.asMap().entries.map((entry) {
                        return _PreviewTile(
                          source: entry.value.previewSource,
                          onRemove: () {
                            setState(() => _sampleArtworks.removeAt(entry.key));
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
              if (_currentStep == 2) ...[
                _LabeledTextField(
                  controller: _experienceController,
                  label: 'Your creative background *',
                  hintText:
                      'Share years of experience, exhibitions, commissions, awards, or notable projects.',
                  minLines: 3,
                  maxLines: 5,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 24),
                Text(
                  'Identity verification *',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Upload a valid ID or verification image so the admin team can confirm your identity.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: _pickIdentityImage,
                  child: Container(
                    width: double.infinity,
                    height: 180,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _identityVerificationImage == null
                            ? const Color(0xFFE4D8CB)
                            : Colors.green,
                        width: 1.5,
                      ),
                    ),
                    child: _identityVerificationImage == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.badge_outlined,
                                size: 42,
                                color: Colors.black38,
                              ),
                              SizedBox(height: 10),
                              Text('Tap to upload your verification image'),
                              SizedBox(height: 4),
                              Text(
                                'JPG or PNG',
                                style: TextStyle(
                                  color: Colors.black45,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          )
                        : Stack(
                            fit: StackFit.expand,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: _InlineApplicationImage(
                                  source:
                                      _identityVerificationImage!.previewSource,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                right: 12,
                                top: 12,
                                child: FilledButton.tonalIcon(
                                  onPressed: _pickIdentityImage,
                                  icon: const Icon(Icons.refresh_outlined),
                                  label: const Text('Replace'),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 24),
                _InfoBox(
                  icon: Icons.info_outlined,
                  title: 'Review process',
                  description:
                      'Admins review your portfolio, biography, and identity document before enabling creator features on your account.',
                  tone: _InfoTone.info,
                ),
                const SizedBox(height: 20),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _agreeToTerms,
                  onChanged: (value) {
                    setState(() => _agreeToTerms = value ?? false);
                  },
                  title: RichText(
                    text: TextSpan(
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Artist Terms of Service',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const TextSpan(
                          text:
                              ' and confirm that the information I submitted is accurate.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 40),
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () {
                                setState(() => _currentStep--);
                              },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSubmitting
                          ? null
                          : _currentStep < 2
                          ? _isStepValid(_currentStep)
                                ? () {
                                    setState(() => _currentStep++);
                                  }
                                : null
                          : _submitApplication,
                      style: FilledButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _currentStep < 2
                                  ? 'Next'
                                  : application?.isRejected == true
                                  ? 'Resubmit Application'
                                  : 'Submit Application',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingUploadImage {
  const _PendingUploadImage._({
    required this.previewSource,
    required this.extension,
    this.bytes,
    this.remoteUrl,
  });

  factory _PendingUploadImage.local({
    required String previewSource,
    required Uint8List bytes,
    required String extension,
  }) {
    return _PendingUploadImage._(
      previewSource: previewSource,
      bytes: bytes,
      extension: extension,
    );
  }

  factory _PendingUploadImage.remote(String url) {
    return _PendingUploadImage._(
      previewSource: url,
      extension: 'jpg',
      remoteUrl: url,
    );
  }

  final String previewSource;
  final Uint8List? bytes;
  final String extension;
  final String? remoteUrl;

  Future<String> resolveUrl({
    required Future<String> Function(Uint8List bytes, String extension)
    uploader,
  }) async {
    if (remoteUrl != null && bytes == null) {
      return remoteUrl!;
    }
    if (bytes == null) {
      throw StateError('Image bytes are missing for upload.');
    }
    return uploader(bytes!, extension);
  }
}

class _StatusScaffold extends StatelessWidget {
  const _StatusScaffold({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: iconColor),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.5),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onPressed,
                  child: Text(buttonLabel),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.minLines,
    required this.maxLines,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final int minLines;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Colors.black26),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE4D8CB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE4D8CB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE4D8CB)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black54),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  const _PreviewTile({required this.source, required this.onRemove});

  final String source;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 100,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          clipBehavior: Clip.antiAlias,
          child: _InlineApplicationImage(source: source, fit: BoxFit.cover),
        ),
        Positioned(
          top: 6,
          right: 18,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineApplicationImage extends StatelessWidget {
  const _InlineApplicationImage({
    required this.source,
    this.fit = BoxFit.cover,
  });

  final String source;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (source.startsWith('data:image/')) {
      final bytes = Uint8List.fromList(UriData.parse(source).contentAsBytes());
      return Image.memory(bytes, fit: fit);
    }
    return Image.network(
      source,
      fit: fit,
      errorBuilder: (_, __, ___) {
        return Container(
          color: Colors.grey.shade200,
          alignment: Alignment.center,
          child: const Icon(Icons.broken_image_outlined),
        );
      },
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.currentStep});

  final int currentStep;

  static const _labels = ['Medium', 'Portfolio', 'Verify'];

  @override
  Widget build(BuildContext context) {
    final primary = EditorialColors.tribalRed;

    Widget circle(int index) {
      final isCompleted = index < currentStep;
      final isFuture = index > currentStep;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: !isFuture
                  ? LinearGradient(
                      colors: [primary, primary.withValues(alpha: 0.88)],
                    )
                  : null,
              color: isFuture ? Colors.white : null,
              border: Border.all(
                color: !isFuture ? primary : EditorialColors.border,
                width: 2,
              ),
              shape: BoxShape.circle,
              boxShadow: index == currentStep ? AppShadows.softGlow : null,
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isFuture ? EditorialColors.muted : Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 72,
            child: Text(
              _labels[index],
              textAlign: TextAlign.center,
              maxLines: 2,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: EditorialColors.muted.withValues(alpha: index <= currentStep ? 0.92 : 0.65),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
            ),
          ),
        ],
      );
    }

    Widget lineBetween(int segmentIndex) {
      final done = currentStep > segmentIndex;
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 28),
          child: Center(
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                color: done ? primary : EditorialColors.border,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          circle(0),
          lineBetween(0),
          circle(1),
          lineBetween(1),
          circle(2),
        ],
      ),
    );
  }
}

enum _InfoTone { info, warning }

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.icon,
    required this.title,
    required this.description,
    required this.tone,
  });

  final IconData icon;
  final String title;
  final String description;
  final _InfoTone tone;

  @override
  Widget build(BuildContext context) {
    final accent = tone == _InfoTone.warning
        ? const Color(0xFFB76A00)
        : Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.black54, height: 1.5),
          ),
        ],
      ),
    );
  }
}
