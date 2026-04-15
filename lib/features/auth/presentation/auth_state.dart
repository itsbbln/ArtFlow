import 'package:flutter/foundation.dart';

import '../data/auth_service.dart';
import '../domain/auth_status.dart';

class AuthState extends ChangeNotifier {
  AuthState({AuthService? service}) : _service = service ?? AuthService();

  final AuthService _service;

  AuthStatus _status = AuthStatus.checking;
  AuthStatus get status => _status;

  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<void> initialize() async {
    _status = AuthStatus.checking;
    notifyListeners();
    _status = await _service.checkSession();
    notifyListeners();
  }

  void setUnauthenticated() {
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void setAuthenticated() {
    _status = AuthStatus.authenticated;
    notifyListeners();
  }
}
