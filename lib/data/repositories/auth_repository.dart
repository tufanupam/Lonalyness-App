/// AI Muse — Auth Repository
/// Handles Firebase Authentication and Google Sign-In with Offline/Demo support.
library;

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/user_entity.dart';
import '../../main.dart';

/// Repository for authentication operations.
class AuthRepository {
  // Safe getters to avoid initialization errors
  FirebaseAuth get _auth {
    if (!isFirebaseAvailable) throw Exception('Firebase not initialized');
    return FirebaseAuth.instance;
  }

  FirebaseFirestore get _firestore {
    if (!isFirebaseAvailable) throw Exception('Firebase not initialized');
    return FirebaseFirestore.instance;
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Demo User for Guest Mode
  static final UserEntity demoUser = UserEntity(
    uid: 'guest-demo-user',
    email: 'guest@aimuse.app',
    displayName: 'Guest User',
    photoUrl: null,
    createdAt: DateTime.now(), 
  );

  /// Sign in as Guest (Demo Mode).
  Future<UserEntity> signInAsGuest() async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    return demoUser.copyWith(createdAt: DateTime.now());
  }

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges {
    if (!isFirebaseAvailable) {
      // Emit a single `null` so the StreamProvider transitions to `data(null)`
      // instead of staying in `loading` state forever (which blocks the router).
      return Stream.value(null);
    }
    try {
      return _auth.authStateChanges();
    } catch (_) {
      return Stream.value(null);
    }
  }

  /// Current Firebase user.
  User? get currentUser {
    if (!isFirebaseAvailable) return null;
    try {
      return _auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  /// Sign in with email and password.
  Future<UserEntity> signInWithEmail(String email, String password) async {
    if (!isFirebaseAvailable) return signInAsGuest(); // Fallback
    
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _getUserEntity(credential.user!);
  }

  /// Register with email and password.
  Future<UserEntity> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    if (!isFirebaseAvailable) {
       // Mock sign up
       await Future.delayed(const Duration(seconds: 1));
       return demoUser.copyWith(
         email: email, 
         displayName: displayName,
         createdAt: DateTime.now()
       );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Update display name
    await credential.user!.updateDisplayName(displayName);

    // Create user document in Firestore
    final user = UserEntity(
      uid: credential.user!.uid,
      email: email,
      displayName: displayName,
      createdAt: DateTime.now(),
    );

    await _firestore.collection('users').doc(user.uid).set(user.toMap());
    return user;
  }

  /// Sign in with Google.
  Future<UserEntity> signInWithGoogle() async {
    if (!isFirebaseAvailable) return signInAsGuest();

    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final userCredential = await _auth.signInWithCredential(credential);
    final firebaseUser = userCredential.user!;

    // Check if user document exists
    final doc =
        await _firestore.collection('users').doc(firebaseUser.uid).get();
    if (!doc.exists) {
      final user = UserEntity(
        uid: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        displayName: firebaseUser.displayName ?? 'User',
        photoUrl: firebaseUser.photoURL,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(user.uid).set(user.toMap());
    }

    return _getUserEntity(firebaseUser);
  }

  /// Sign out from all providers.
  Future<void> signOut() async {
    if (!isFirebaseAvailable) return;
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
    ]);
  }

  /// Get UserEntity from Firestore, or create from Firebase user.
  Future<UserEntity> _getUserEntity(User firebaseUser) async {
    final doc =
        await _firestore.collection('users').doc(firebaseUser.uid).get();

    if (doc.exists) {
      return UserEntity.fromMap(doc.data()!);
    }

    // Fallback: create entity from Firebase user
    return UserEntity(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName ?? 'User',
      photoUrl: firebaseUser.photoURL,
      createdAt: DateTime.now(),
    );
  }

  /// Update user profile in Firestore.
  Future<void> updateUser(UserEntity user) async {
    if (!isFirebaseAvailable) return;
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  /// Get user entity by UID.
  Future<UserEntity?> getUserById(String uid) async {
    if (!isFirebaseAvailable) return uid == demoUser.uid ? demoUser : null;
    
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return UserEntity.fromMap(doc.data()!);
    return null;
  }
}
