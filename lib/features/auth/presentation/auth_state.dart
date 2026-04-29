import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/auth_service.dart';
import '../domain/artist_application.dart';
import '../domain/auth_status.dart';
import '../../social/follow_service.dart';

enum UserRole { buyer, artist, admin }

class AuthState extends ChangeNotifier {
  AuthState({
    AuthService? service,
    FollowService? followService,
  })  : _service = service ?? AuthService(),
        _followService = followService ?? FollowService();

  final AuthService _service;
  final FollowService _followService;

  AuthStatus _status = AuthStatus.checking;
  AuthStatus get status => _status;
  UserRole _role = UserRole.buyer;
  String _displayName = 'Guest User';
  String _username = '@guest';
  String _photoUrl = '';
  String _bio = '';
  String _style = '';
  /// Short lines shown under bio (schools, exhibits, orgs — user-defined).
  List<String> _pinnedDetails = [];
  int _followersCount = 0;
  int _followingCount = 0;
  bool _verifiedArtist = false;
  bool _portfolioPack = false;
  bool _featuredBoost = false;
  bool _acceptingCommissions = true;
  bool _welcomeCompleted = false;
  bool _isVerified = false;
  bool _verificationSubmitted = false;
  bool _isScholarVerified = false;
  bool _scholarVerificationSubmitted = false;
  String? _lastAuthError;
  StreamSubscription? _userSubscription;
  StreamSubscription<ArtistApplication?>? _artistApplicationSubscription;
  ArtistApplication? _artistApplication;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  UserRole get role => _role;
  String get displayName => _displayName;
  String get username => _username;
  String get photoUrl => _photoUrl;
  String get bio => _bio;
  String get style => _style;
  List<String> get pinnedDetails => List.unmodifiable(_pinnedDetails);
  int get followersCount =>
      _followersCount < 0 ? 0 : _followersCount;
  int get followingCount =>
      _followingCount < 0 ? 0 : _followingCount;
  bool get isVerified => _isVerified;
  bool get verificationSubmitted => _verificationSubmitted;
  bool get isScholarVerified => _isScholarVerified;
  bool get scholarVerificationSubmitted => _scholarVerificationSubmitted;
  String? get lastAuthError => _lastAuthError;
  bool get isVerifiedArtist => _verifiedArtist;
  bool get hasPortfolioPack => _portfolioPack;
  bool get hasFeaturedBoost => _featuredBoost;
  bool get acceptingCommissions => _acceptingCommissions;
  bool get welcomeCompleted => _welcomeCompleted;
  bool get isAdmin => _role == UserRole.admin;
  bool get isArtist => _role == UserRole.artist || _role == UserRole.admin;
  bool get isBuyer => _role == UserRole.buyer;
  ArtistApplication? get currentArtistApplication => _artistApplication;
  ArtistApplicationStatus get artistApplicationStatus =>
      _artistApplication?.status ?? ArtistApplicationStatus.none;
  bool get hasArtistApplication => _artistApplication != null;
  bool get hasPendingArtistApplication =>
      artistApplicationStatus == ArtistApplicationStatus.pending;
  bool get artistApplicationRejected =>
      artistApplicationStatus == ArtistApplicationStatus.rejected;
  bool get artistApplicationApproved =>
      artistApplicationStatus == ArtistApplicationStatus.approved;
  String get artistApplicationRejectionReason =>
      _artistApplication?.rejectionReason ?? '';
  bool get firebaseAvailable => Firebase.apps.isNotEmpty;
  bool get hasFirebaseSession {
    if (!firebaseAvailable) {
      return false;
    }
    return FirebaseAuth.instance.currentUser != null;
  }

  String? get currentUserId {
    if (!firebaseAvailable) {
      return null;
    }
    return FirebaseAuth.instance.currentUser?.uid;
  }

  String? get currentUserEmail {
    if (!firebaseAvailable) {
      return null;
    }
    return FirebaseAuth.instance.currentUser?.email;
  }

  Future<void> initialize() async {
    _status = AuthStatus.checking;
    _lastAuthError = null;
    notifyListeners();

    _status = await _service.checkSession();

    if (_status == AuthStatus.authenticated) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Ensure admin details are reflected in the database
        await _service.ensureAdminRole(user);
        _startUserSubscription(user.uid);
        _startArtistApplicationSubscription(user.uid);
      }
    }

    // Load welcome completion status
    final prefs = await SharedPreferences.getInstance();
    _welcomeCompleted = prefs.getBool('welcome_completed') ?? false;
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    try {
      _status = AuthStatus.checking;
      _lastAuthError = null;
      notifyListeners();

      final credential = await _service.loginWithEmail(
        email: email,
        password: password,
      );
      if (credential.user != null) {
        // Ensure admin details are reflected in the database
        await _service.ensureAdminRole(credential.user!);
        _startUserSubscription(credential.user!.uid);
        _startArtistApplicationSubscription(credential.user!.uid);
        _status = AuthStatus.authenticated;
        _lastAuthError = null;
      }
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _lastAuthError = _friendlyAuthError(e);
      rethrow;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _lastAuthError = 'Unable to continue with email and password right now.';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      _status = AuthStatus.checking;
      _lastAuthError = null;
      notifyListeners();

      final credential = await _service.signInWithGoogle();
      if (credential.user != null) {
        await _service.ensureAdminRole(credential.user!);
        _startUserSubscription(credential.user!.uid);
        _startArtistApplicationSubscription(credential.user!.uid);
        _status = AuthStatus.authenticated;
        _lastAuthError = null;
      }
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _lastAuthError = _friendlyAuthError(e);
      rethrow;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _lastAuthError = 'Unable to continue with Google right now.';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String role,
    required String email,
    required String password,
  }) async {
    try {
      _status = AuthStatus.checking;
      _lastAuthError = null;
      notifyListeners();

      final credential = await _service.registerWithEmail(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      if (credential.user != null) {
        _startUserSubscription(credential.user!.uid);
        _startArtistApplicationSubscription(credential.user!.uid);
        _status = AuthStatus.authenticated;
        _lastAuthError = null;
      }
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _lastAuthError = _friendlyAuthError(e);
      rethrow;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _lastAuthError = 'Unable to continue with email and password right now.';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> registerWithGoogle({String? preferredName}) async {
    try {
      _status = AuthStatus.checking;
      _lastAuthError = null;
      notifyListeners();

      final credential = await _service.signInWithGoogle(
        preferredName: preferredName,
      );
      if (credential.user != null) {
        await _service.ensureAdminRole(credential.user!);
        _startUserSubscription(credential.user!.uid);
        _startArtistApplicationSubscription(credential.user!.uid);
        _status = AuthStatus.authenticated;
        _lastAuthError = null;
      }
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.unauthenticated;
      _lastAuthError = _friendlyAuthError(e);
      rethrow;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _lastAuthError = 'Unable to continue with Google right now.';
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  Future<void> submitArtistApplication({
    required String bio,
    required String style,
    required String medium,
    String experience = '',
    required List<String> sampleArtworks,
    String identityVerificationUrl = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('You need to sign in before applying as an artist.');
    }

    await _service.submitArtistApplication(
      user: user,
      bio: bio,
      style: style,
      medium: medium,
      experience: experience,
      sampleArtworks: sampleArtworks,
      identityVerificationUrl: identityVerificationUrl,
    );

    _verificationSubmitted = true;
    notifyListeners();
  }

  Future<void> submitScholarVerification({required String schoolIdUrl}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _service.updateUserProfile(user.uid, {
        'schoolIdUrl': schoolIdUrl,
        'scholarVerificationSubmitted': true,
        'isScholarVerified': false,
      });

      _scholarVerificationSubmitted = true;
      _isScholarVerified = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error submitting scholar verification: $e');
    }
  }

  Future<void> followArtist(String artistUserId) async {
    final me = currentUserId;
    if (me == null || artistUserId.isEmpty || me == artistUserId) {
      return;
    }
    await _followService.follow(followerId: me, artistId: artistUserId);
  }

  Future<void> unfollowArtist(String artistUserId) async {
    final me = currentUserId;
    if (me == null || artistUserId.isEmpty || me == artistUserId) {
      return;
    }
    await _followService.unfollow(followerId: me, artistId: artistUserId);
  }

  Stream<bool> watchFollowingArtist(String artistUserId) {
    final me = currentUserId;
    if (me == null) {
      return Stream.value(false);
    }
    return _followService.watchIsFollowing(followerId: me, artistId: artistUserId);
  }

  Future<void> setUnauthenticated() async {
    await _userSubscription?.cancel();
    _userSubscription = null;
    await _artistApplicationSubscription?.cancel();
    _artistApplicationSubscription = null;
    await _service.signOut();
    _status = AuthStatus.unauthenticated;
    _isVerified = false;
    _verificationSubmitted = false;
    _isScholarVerified = false;
    _scholarVerificationSubmitted = false;
    _artistApplication = null;
    notifyListeners();
  }

  void clearLastAuthError() {
    if (_lastAuthError == null) {
      return;
    }
    _lastAuthError = null;
    notifyListeners();
  }

  void _startUserSubscription(String uid) {
    _userSubscription?.cancel();
    _userSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            _displayName = data['displayName'] ?? 'User';
            _username = data['username'] ?? '@user';
            _photoUrl = data['photoUrl'] ?? '';
            _isVerified = data['isVerified'] ?? false;
            _verifiedArtist = _isVerified; // Keep in sync
            _verificationSubmitted = data['verificationSubmitted'] ?? false;
            _isScholarVerified = data['isScholarVerified'] ?? false;
            _scholarVerificationSubmitted =
                data['scholarVerificationSubmitted'] ?? false;
            _bio = data['bio'] ?? '';
            _style = data['artStyle'] ?? '';
            _pinnedDetails = _parsePinnedDetails(data);
            _followersCount = (data['followersCount'] as num?)?.toInt() ?? 0;
            _followingCount =
                (data['followingCount'] as num?)?.toInt() ?? 0;
            _portfolioPack = data['portfolioPack'] ?? false;
            _featuredBoost = data['featuredBoost'] ?? false;
            _acceptingCommissions =
                data['acceptingCommissions'] as bool? ?? true;

            final roleStr = data['role'] ?? 'buyer';
            _role = roleStr == 'admin'
                ? UserRole.admin
                : (roleStr == 'artist' ? UserRole.artist : UserRole.buyer);

            notifyListeners();
          }
        });
  }

  void _startArtistApplicationSubscription(String uid) {
    _artistApplicationSubscription?.cancel();
    _artistApplicationSubscription = _service
        .watchArtistApplication(uid)
        .listen((application) {
          _artistApplication = application;
          if (application != null) {
            if (application.isPending) {
              _verificationSubmitted = true;
            } else if (application.isRejected || application.isApproved) {
              _verificationSubmitted = false;
            }
          }
          notifyListeners();
        });
  }

  void setAuthenticated({required UserRole role}) {
    _role = role;
    _status = AuthStatus.authenticated;
    _displayName = 'Guest ${role == UserRole.artist ? 'Artist' : 'Buyer'}';
    _username = '@guest';
    notifyListeners();
  }

  void completeArtistOnboarding({required String style, required String bio}) {
    _role = _role == UserRole.admin ? UserRole.admin : UserRole.artist;
    _style = style.trim();
    _bio = bio.trim().isEmpty ? _bio : bio.trim();
    notifyListeners();
  }

  void completeBuyerOnboarding({required List<String> preferences}) {
    if (_role == UserRole.buyer) {
      _bio = preferences.isEmpty
          ? 'Collector and buyer.'
          : 'Interested in ${preferences.take(3).join(', ')}.';
    }
    notifyListeners();
  }

  void updateProfile({
    required String name,
    required String username,
    required String bio,
  }) {
    _displayName = name.trim().isEmpty ? _displayName : name.trim();
    _username = username.trim().isEmpty ? _username : username.trim();
    _bio = bio.trim().isEmpty ? _bio : bio.trim();
    notifyListeners();
  }

  Future<void> saveProfile({
    required String name,
    required String username,
    required String bio,
    String? photoUrl,
    bool? portfolioPack,
    bool? featuredBoost,
    bool? acceptingCommissions,
    List<String>? pinnedDetails,
  }) async {
    final uid = currentUserId;
    if (uid == null) {
      updateProfile(name: name, username: username, bio: bio);
      if (photoUrl != null) {
        _photoUrl = photoUrl;
      }
      if (portfolioPack != null) {
        _portfolioPack = portfolioPack;
      }
      if (featuredBoost != null) {
        _featuredBoost = featuredBoost;
      }
      if (acceptingCommissions != null) {
        _acceptingCommissions = acceptingCommissions;
      }
      if (pinnedDetails != null) {
        _pinnedDetails = List<String>.from(pinnedDetails);
      }
      notifyListeners();
      return;
    }

    final trimmedName = name.trim().isEmpty ? _displayName : name.trim();
    final trimmedUsername = username.trim().isEmpty
        ? _username
        : username.trim();
    final trimmedBio = bio.trim();
    final resolvedPhoto = photoUrl ?? _photoUrl;
    final resolvedPortfolioPack = portfolioPack ?? _portfolioPack;
    final resolvedFeaturedBoost = featuredBoost ?? _featuredBoost;
    final resolvedAcceptingCommissions =
        acceptingCommissions ?? _acceptingCommissions;
    final resolvedPins = pinnedDetails ?? _pinnedDetails;

    await _service.updateUserProfile(uid, {
      'displayName': trimmedName,
      'username': trimmedUsername,
      'bio': trimmedBio,
      'photoUrl': resolvedPhoto,
      'portfolioPack': resolvedPortfolioPack,
      'featuredBoost': resolvedFeaturedBoost,
      'acceptingCommissions': resolvedAcceptingCommissions,
      'pinnedDetails': resolvedPins
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList(),
      'exhibitHighlights': FieldValue.delete(),
      'memberOrganizations': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      if (firebaseUser.displayName != trimmedName) {
        await firebaseUser.updateDisplayName(trimmedName);
      }
      if (resolvedPhoto != firebaseUser.photoURL) {
        await firebaseUser.updatePhotoURL(
          resolvedPhoto.isEmpty ? null : resolvedPhoto,
        );
      }
    }

    _displayName = trimmedName;
    _username = trimmedUsername;
    _bio = trimmedBio;
    _photoUrl = resolvedPhoto;
    _portfolioPack = resolvedPortfolioPack;
    _featuredBoost = resolvedFeaturedBoost;
    _acceptingCommissions = resolvedAcceptingCommissions;
    _pinnedDetails = List<String>.from(resolvedPins);
    notifyListeners();
  }

  void setVerifiedArtist(bool value) {
    _verifiedArtist = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _artistApplicationSubscription?.cancel();
    _userSubscription?.cancel();
    super.dispose();
  }

  // Admin methods
  Stream<QuerySnapshot> getPendingApplications() {
    return _service.getPendingApplications();
  }

  Stream<QuerySnapshot> getPendingScholarApplications() {
    return _service.getPendingScholarApplications();
  }

  Future<void> approveUser(String uid, {bool isScholar = false}) async {
    await _service.approveUser(uid, isScholar: isScholar);
  }

  Future<void> rejectUser(String uid, {bool isScholar = false}) async {
    await _service.rejectUser(uid, isScholar: isScholar);
  }

  void enablePortfolioPack() {
    _portfolioPack = true;
    notifyListeners();
  }

  void enableFeaturedBoost() {
    _featuredBoost = true;
    notifyListeners();
  }

  Future<void> completeWelcome() async {
    _welcomeCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_completed', true);
    notifyListeners();
  }

  String _friendlyAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong password.';
      case 'user-not-found':
        return 'No account found for that email.';
      case 'invalid-email':
        return 'That email address is invalid.';
      case 'email-already-in-use':
        return 'That email is already registered.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method.';
      case 'popup-closed-by-user':
      case 'google-sign-in-cancelled':
        return 'Google sign in was cancelled.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }
}

List<String> _parseStringListField(dynamic raw) {
  if (raw == null) {
    return [];
  }
  if (raw is List) {
    return raw
        .map((dynamic e) => e.toString().trim())
        .where((String s) => s.isNotEmpty)
        .toList();
  }
  return [];
}

List<String> _parsePinnedDetails(Map<String, dynamic> data) {
  final pinned = _parseStringListField(data['pinnedDetails']);
  if (pinned.isNotEmpty) {
    return pinned;
  }
  return [
    ..._parseStringListField(data['exhibitHighlights']),
    ..._parseStringListField(data['memberOrganizations']),
  ];
}
