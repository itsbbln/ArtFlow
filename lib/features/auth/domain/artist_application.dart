import 'package:cloud_firestore/cloud_firestore.dart';

enum ArtistApplicationStatus { none, pending, approved, rejected }

ArtistApplicationStatus artistApplicationStatusFromString(String? value) {
  switch (value?.toLowerCase()) {
    case 'pending':
      return ArtistApplicationStatus.pending;
    case 'approved':
      return ArtistApplicationStatus.approved;
    case 'rejected':
      return ArtistApplicationStatus.rejected;
    default:
      return ArtistApplicationStatus.none;
  }
}

class ArtistApplication {
  const ArtistApplication({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.email,
    required this.bio,
    required this.artStyle,
    required this.medium,
    required this.experience,
    required this.sampleArtworks,
    required this.identityVerificationUrl,
    required this.status,
    required this.rejectionReason,
    required this.submittedAt,
    required this.reviewedAt,
  });

  final String id;
  final String userId;
  final String displayName;
  final String email;
  final String bio;
  final String artStyle;
  final String medium;
  final String experience;
  final List<String> sampleArtworks;
  final String identityVerificationUrl;
  final ArtistApplicationStatus status;
  final String rejectionReason;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;

  bool get isPending => status == ArtistApplicationStatus.pending;
  bool get isApproved => status == ArtistApplicationStatus.approved;
  bool get isRejected => status == ArtistApplicationStatus.rejected;

  factory ArtistApplication.fromFirestore(
    String id,
    Map<String, dynamic>? data,
  ) {
    final source = data ?? <String, dynamic>{};
    return ArtistApplication(
      id: id,
      userId: (source['userId'] as String?) ?? '',
      displayName: (source['displayName'] as String?) ?? '',
      email: (source['email'] as String?) ?? '',
      bio: (source['bio'] as String?) ?? '',
      artStyle: (source['artStyle'] as String?) ?? '',
      medium: (source['medium'] as String?) ?? '',
      experience: (source['experience'] as String?) ?? '',
      sampleArtworks: List<String>.from(
        source['sampleArtworks'] as List? ?? const [],
      ),
      identityVerificationUrl:
          (source['identityVerification'] as String?) ?? '',
      status: artistApplicationStatusFromString(source['status'] as String?),
      rejectionReason: (source['rejectionReason'] as String?) ?? '',
      submittedAt: _parseDate(source['submittedAt']),
      reviewedAt: _parseDate(source['reviewedAt']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    return null;
  }
}
