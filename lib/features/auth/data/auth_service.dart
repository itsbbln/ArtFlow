import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../domain/artist_application.dart';
import '../domain/auth_status.dart';

class AuthService {
  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _firestore => FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.standard();

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
      await credential.user!.updateDisplayName(name);
      await _ensureUserDocument(
        credential.user!,
        role: role,
        preferredName: name,
      );
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

  Future<UserCredential> signInWithGoogle({String? preferredName}) async {
    late final UserCredential credential;

    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..addScope('email')
        ..setCustomParameters({'prompt': 'select_account'});
      credential = await _auth.signInWithPopup(provider);
    } else {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignore stale Google session cleanup failures.
      }
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google sign in was cancelled.',
        );
      }

      final googleAuth = await googleUser.authentication;
      final authCredential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      credential = await _auth.signInWithCredential(authCredential);
    }

    if (credential.user != null) {
      await _ensureUserDocument(
        credential.user!,
        role: 'buyer',
        preferredName: preferredName,
      );
    }

    return credential;
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await _googleSignIn.signOut();
      } catch (_) {
        // Ignore Google sign-out failures and continue Firebase sign-out.
      }
    }
    await _auth.signOut();
  }

  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  Future<void> ensureAdminRole(User user) async {
    final email = user.email?.toLowerCase();
    if (email == 'adminpageturner@gmail.com' ||
        email == 'adminpageturener@gmail.com' ||
        email == 'admin@artflow.app') {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .update({'role': 'admin', 'isVerified': true})
          .catchError((e) async {
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
    await _firestore
        .collection('users')
        .doc(uid)
        .set(data, SetOptions(merge: true));
  }

  Stream<ArtistApplication?> watchArtistApplication(String uid) {
    return _firestore.collection('artistApplications').doc(uid).snapshots().map(
      (doc) {
        if (!doc.exists) {
          return null;
        }
        return ArtistApplication.fromFirestore(doc.id, doc.data());
      },
    );
  }

  Future<ArtistApplication?> fetchArtistApplication(String uid) async {
    final doc = await _firestore
        .collection('artistApplications')
        .doc(uid)
        .get();
    if (!doc.exists) {
      return null;
    }
    return ArtistApplication.fromFirestore(doc.id, doc.data());
  }

  Future<void> submitArtistApplication({
    required User user,
    required String bio,
    required String style,
    required String medium,
    required String experience,
    required List<String> sampleArtworks,
    required String identityVerificationUrl,
  }) async {
    final applicationRef = _firestore
        .collection('artistApplications')
        .doc(user.uid);
    final userRef = _firestore.collection('users').doc(user.uid);
    final userSnapshot = await userRef.get();
    final userData = userSnapshot.data() ?? <String, dynamic>{};
    final displayName =
        (userData['displayName'] as String?)?.trim().isNotEmpty == true
        ? (userData['displayName'] as String).trim()
        : (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : 'ArtFlow User';
    final email = (user.email ?? (userData['email'] as String?) ?? '').trim();

    final batch = _firestore.batch();
    batch.set(applicationRef, {
      'userId': user.uid,
      'displayName': displayName,
      'email': email,
      'bio': bio,
      'artStyle': style,
      'medium': medium,
      'experience': experience,
      'sampleArtworks': sampleArtworks,
      'identityVerification': identityVerificationUrl,
      'status': 'pending',
      'rejectionReason': '',
      'submittedAt': FieldValue.serverTimestamp(),
      'reviewedAt': null,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(userRef, {
      'bio': bio,
      'artStyle': style,
      'medium': medium,
      'verificationSubmitted': true,
      'artistApplicationStatus': 'pending',
      'artistApplicationId': user.uid,
      'isVerified': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
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

  Future<void> _ensureUserDocument(
    User user, {
    required String role,
    String? preferredName,
  }) async {
    final docRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await docRef.get();
    final existing = snapshot.data();

    final email = (user.email ?? '').trim();
    final resolvedName = (preferredName?.trim().isNotEmpty ?? false)
        ? preferredName!.trim()
        : ((existing?['displayName'] as String?)?.trim().isNotEmpty ?? false)
        ? (existing?['displayName'] as String).trim()
        : (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : email.isNotEmpty
        ? email.split('@').first
        : 'ArtFlow User';

    if ((preferredName?.trim().isNotEmpty ?? false) &&
        user.displayName != resolvedName) {
      await user.updateDisplayName(resolvedName);
    }

    final userEmail = email.toLowerCase();
    final isAdminEmail =
        userEmail == 'adminpageturner@gmail.com' ||
        userEmail == 'adminpageturener@gmail.com' ||
        userEmail == 'admin@artflow.app';
    final roleValue = isAdminEmail
        ? 'admin'
        : (existing?['role'] as String?) ?? role;

    final username =
        (existing?['username'] as String?)?.trim().isNotEmpty == true
        ? (existing!['username'] as String).trim()
        : '@${resolvedName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '')}';

    await docRef.set({
      'uid': user.uid,
      'displayName': resolvedName,
      'email': email,
      'photoUrl': (existing?['photoUrl'] as String?) ?? user.photoURL,
      'role': roleValue,
      'isVerified':
          isAdminEmail || ((existing?['isVerified'] as bool?) ?? false),
      'verificationSubmitted':
          (existing?['verificationSubmitted'] as bool?) ?? false,
      'scholarVerificationSubmitted':
          (existing?['scholarVerificationSubmitted'] as bool?) ?? false,
      'isScholarVerified': (existing?['isScholarVerified'] as bool?) ?? false,
      'artistApplicationStatus':
          (existing?['artistApplicationStatus'] as String?) ?? 'none',
      'portfolioPack': (existing?['portfolioPack'] as bool?) ?? false,
      'featuredBoost': (existing?['featuredBoost'] as bool?) ?? false,
      'acceptingCommissions':
          (existing?['acceptingCommissions'] as bool?) ?? true,
      'username': username,
      'createdAt': existing?['createdAt'] ?? FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
