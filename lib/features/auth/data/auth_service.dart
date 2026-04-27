import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/auth_status.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  Future<AuthStatus> checkSession() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        return AuthStatus.authenticated;
      }
    } catch (e) {
      debugPrint('AuthService.checkSession error: $e');
    }
    return AuthStatus.unauthenticated;
  }

  Future<UserCredential> registerWithEmail({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    if (credential.user != null) {
      final userEmail = email.toLowerCase();
      final isAdminEmail = userEmail == 'adminpageturner@gmail.com' || userEmail == 'adminpageturener@gmail.com' || userEmail == 'admin@artflow.app';
      final userRole = isAdminEmail ? 'admin' : role;
      await _firestore.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'displayName': name,
        'email': email,
        'role': userRole,
        'isVerified': isAdminEmail,
        'verificationSubmitted': false,
        'username': '@${name.toLowerCase().trim().replaceAll(' ', '')}',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return credential;
  }

  Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  Future<void> ensureAdminRole(User user) async {
    final email = user.email?.toLowerCase();
    if (email == 'adminpageturner@gmail.com' || email == 'adminpageturener@gmail.com' || email == 'admin@artflow.app') {
      await _firestore.collection('users').doc(user.uid).update({
        'role': 'admin',
        'isVerified': true,
      }).catchError((e) async {
        // If update fails (e.g. document doesn't exist), try to set it
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': user.email,
          'role': 'admin',
          'isVerified': true,
          'displayName': user.displayName ?? 'Admin',
          'username': '@admin',
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      });
    }
  }

  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).update(data);
  }

  Stream<QuerySnapshot> getPendingApplications() {
    return _firestore
        .collection('users')
        .where('verificationSubmitted', isEqualTo: true)
        .where('isVerified', isEqualTo: false)
        .snapshots();
  }

  Stream<QuerySnapshot> getPendingScholarApplications() {
    return _firestore
        .collection('users')
        .where('scholarVerificationSubmitted', isEqualTo: true)
        .where('isScholarVerified', isEqualTo: false)
        .snapshots();
  }

  Future<void> approveUser(String uid, {bool isScholar = false}) async {
    if (isScholar) {
      await _firestore.collection('users').doc(uid).update({
        'isScholarVerified': true,
      });
    } else {
      await _firestore.collection('users').doc(uid).update({
        'isVerified': true,
      });
    }
  }

  Future<void> rejectUser(String uid, {bool isScholar = false}) async {
    if (isScholar) {
      await _firestore.collection('users').doc(uid).update({
        'scholarVerificationSubmitted': false,
        'isScholarVerified': false,
      });
    } else {
      await _firestore.collection('users').doc(uid).update({
        'verificationSubmitted': false,
        'isVerified': false,
      });
    }
  }
}
