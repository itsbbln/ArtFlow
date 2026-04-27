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
  bool _verifiedArtist = false;
  bool _portfolioPack = false;
  bool _featuredBoost = false;
  bool _welcomeCompleted = false;

  bool get isAuthenticated => _status == AuthStatus.authenticated;
  UserRole get role => _role;
  String get displayName => _displayName;
  String get username => _username;
  String get bio => _bio;
  String get style => _style;
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
        
        final doc = await _service.getUserData(user.uid);
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          _displayName = data['displayName'] ?? 'User';
          _username = data['username'] ?? '@user';
          final roleStr = data['role'] ?? 'buyer';
          _role = roleStr == 'admin' ? UserRole.admin : (roleStr == 'artist' ? UserRole.artist : UserRole.buyer);
        }
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
        
        final doc = await _service.getUserData(credential.user!.uid);
        if (doc.exists) {
          final data = doc.data() as Map<String, dynamic>;
          _displayName = data['displayName'] ?? 'User';
          _username = data['username'] ?? '@user';
          final roleStr = data['role'] ?? 'buyer';
          _role = roleStr == 'admin' ? UserRole.admin : (roleStr == 'artist' ? UserRole.artist : UserRole.buyer);
          _status = AuthStatus.authenticated;
        }
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
        _displayName = name.trim();
        _username = '@${name.toLowerCase().trim().replaceAll(' ', '')}';
        _role = role == 'artist' ? UserRole.artist : UserRole.buyer;
        if (email.toLowerCase() == 'admin@artflow.app' || email.toLowerCase() == 'adminpageturner@gmail.com') {
          _role = UserRole.admin;
        }
        _status = AuthStatus.authenticated;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
    } finally {
      notifyListeners();
    }
  }

  Future<void> setUnauthenticated() async {
    await _service.signOut();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
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

  void setVerifiedArtist(bool value) {
    _verifiedArtist = value;
    notifyListeners();
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
