import 'dart:async';

import '../domain/auth_status.dart';

class AuthService {
  Future<AuthStatus> checkSession() async {
    return AuthStatus.unauthenticated;
  }
}
