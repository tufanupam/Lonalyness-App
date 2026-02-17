/// AI Muse — Auth Repository
/// Handles Firebase Authentication and Google Sign-In.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/entities/user_entity.dart';

/// Repository for authentication operations.
class AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current Firebase user.
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password.
  Future<UserEntity> signInWithEmail(String email, String password) async {
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
    final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
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
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  /// Get user entity by UID.
  Future<UserEntity?> getUserById(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) return UserEntity.fromMap(doc.data()!);
    return null;
  }
}
