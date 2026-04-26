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
    // Load welcome completion status
    final prefs = await SharedPreferences.getInstance();
    _welcomeCompleted = prefs.getBool('welcome_completed') ?? false;
    notifyListeners();
  }

  void setUnauthenticated() {
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void setAuthenticated({UserRole role = UserRole.buyer}) {
    _status = AuthStatus.authenticated;
    _role = role;
    notifyListeners();
  }

  void register({
    required String name,
    required String role,
    required String email,
  }) {
    _status = AuthStatus.authenticated;
    _displayName = name.trim();
    _username = '@${name.toLowerCase().trim().replaceAll(' ', '')}';
    _bio = role == 'artist'
        ? 'Emerging artist open for commissions.'
        : 'Art enthusiast exploring local creators.';
    _role = role == 'artist' ? UserRole.artist : UserRole.buyer;
    if (email.toLowerCase() == 'admin@artflow.app') {
      _role = UserRole.admin;
    }
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
