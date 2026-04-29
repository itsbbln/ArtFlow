import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/auth_service.dart';
import '../domain/auth_status.dart';

enum UserRole { buyer, artist, admin }

class AuthState extends ChangeNotifier {
  AuthState({AuthService? service}) : _service = service ?? AuthService();

  final AuthService _service;

  AuthStatus _status = AuthStatus.checking;
  AuthStatus get status => _status;
  UserRole _role = UserRole.buyer;
  String _displayName = 'Guest User';
  String _username = '@guest';
  String _bio = '';
  String _style = '';
  String _medium = '';
  bool _verifiedArtist = false;
  bool _portfolioPack = false;
  bool _featuredBoost = false;
  bool _welcomeCompleted = false;
  bool _isVerified = false;
  bool _verificationSubmitted = false;
  bool _isScholarVerified = false;
  bool _scholarVerificationSubmitted = false;
  StreamSubscription? _userSubscription;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  UserRole get role => _role;
  String get displayName => _displayName;
  String get username => _username;
  String get bio => _bio;
  String get style => _style;
  String get medium => _medium;
  bool get isVerified => _isVerified;
  bool get verificationSubmitted => _verificationSubmitted;
  bool get isScholarVerified => _isScholarVerified;
  bool get scholarVerificationSubmitted => _scholarVerificationSubmitted;
  bool get isVerifiedArtist => _verifiedArtist;
  bool get hasPortfolioPack => _portfolioPack;
  bool get hasFeaturedBoost => _featuredBoost;
  bool get welcomeCompleted => _welcomeCompleted;
  bool get isAdmin => _role == UserRole.admin;
  bool get isArtist => _role == UserRole.artist || _role == UserRole.admin;
  bool get isBuyer => _role == UserRole.buyer;

  Future<void> initialize() async {
    _status = AuthStatus.checking;
    notifyListeners();
    
    _status = await _service.checkSession();
    
    if (_status == AuthStatus.authenticated) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Ensure admin details are reflected in the database
        await _service.ensureAdminRole(user);
        _startUserSubscription(user.uid);
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
      notifyListeners();
      
      final credential = await _service.loginWithEmail(email: email, password: password);
      if (credential.user != null) {
        // Ensure admin details are reflected in the database
        await _service.ensureAdminRole(credential.user!);
        _startUserSubscription(credential.user!.uid);
        _status = AuthStatus.authenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
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
      notifyListeners();

      final credential = await _service.registerWithEmail(
        email: email,
        password: password,
        name: name,
        role: role,
      );

      if (credential.user != null) {
        _startUserSubscription(credential.user!.uid);
        _status = AuthStatus.authenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  Future<void> submitArtistApplication({
    required String bio,
    required String style,
    required String medium,
    required String penName,
    required String portfolioUrl,
    String? additionalDetails,
    List<String> sampleArtworks = const [],
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _service.updateUserProfile(user.uid, {
        'bio': bio,
        'artStyle': style,
        'medium': medium,
        'penName': penName,
        'portfolioUrl': portfolioUrl,
        'additionalDetails': additionalDetails,
        'sampleArtworks': sampleArtworks,
        'verificationSubmitted': true,
        'role': 'artist', // Update role to artist (pending verification)
      });

      _verificationSubmitted = true;
      _role = UserRole.artist;
      notifyListeners();
    } catch (e) {
      debugPrint('Error submitting artist application: $e');
    }
  }

  Future<void> submitScholarVerification({
    required String schoolIdUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _service.updateUserProfile(user.uid, {
        'schoolIdUrl': schoolIdUrl,
        'scholarVerificationSubmitted': true,
        'isScholarVerified': false,
        'scholarSubmittedAt': FieldValue.serverTimestamp(),
      });

      _scholarVerificationSubmitted = true;
      _isScholarVerified = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error submitting scholar verification: $e');
    }
  }

  Future<void> setUnauthenticated() async {
    await _userSubscription?.cancel();
    _userSubscription = null;
    await _service.signOut();
    _status = AuthStatus.unauthenticated;
    _isVerified = false;
    _verificationSubmitted = false;
    _isScholarVerified = false;
    _scholarVerificationSubmitted = false;
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
        _isVerified = data['isVerified'] ?? false;
        _verifiedArtist = _isVerified; // Keep in sync
        _verificationSubmitted = data['verificationSubmitted'] ?? false;
        _isScholarVerified = data['isScholarVerified'] ?? false;
        _scholarVerificationSubmitted = data['scholarVerificationSubmitted'] ?? false;
        _bio = data['bio'] ?? '';
        _style = data['artStyle'] ?? '';
        _medium = data['medium'] ?? '';
        
        final roleStr = data['role'] ?? 'buyer';
        _role = roleStr == 'admin' ? UserRole.admin : (roleStr == 'artist' ? UserRole.artist : UserRole.buyer);
        
        notifyListeners();
      }
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

  Future<void> updateProfile({
    required String name,
    required String username,
    required String bio,
    String? artStyle,
    String? medium,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final updates = {
      'displayName': name.trim(),
      'username': username.trim(),
      'bio': bio.trim(),
    };

    if (artStyle != null) updates['artStyle'] = artStyle;
    if (medium != null) updates['medium'] = medium;

    try {
      await _service.updateUserProfile(user.uid, updates);
      
      _displayName = name.trim().isEmpty ? _displayName : name.trim();
      _username = username.trim().isEmpty ? _username : username.trim();
      _bio = bio.trim().isEmpty ? _bio : bio.trim();
      if (artStyle != null) _style = artStyle;
      if (medium != null) _medium = medium;
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }

  void setVerifiedArtist(bool value) {
    _verifiedArtist = value;
    notifyListeners();
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
}
