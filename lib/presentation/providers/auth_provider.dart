/// AI Muse — Auth Provider
/// Riverpod providers for authentication state management.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/auth_repository.dart';
import '../../domain/entities/user_entity.dart';

/// Provides the AuthRepository instance.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Watches Firebase Auth state changes.
final authStateProvider = StreamProvider<User?>((ref) {
  final repo = ref.read(authRepositoryProvider);
  return repo.authStateChanges;
});

/// Manages the current user entity with extended profile data.
final currentUserProvider =
    StateNotifierProvider<CurrentUserNotifier, AsyncValue<UserEntity?>>((ref) {
  return CurrentUserNotifier(ref);
});

/// StateNotifier for current user management.
class CurrentUserNotifier extends StateNotifier<AsyncValue<UserEntity?>> {
  final Ref _ref;

  CurrentUserNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    _ref.listen(authStateProvider, (_, next) {
      next.when(
        data: (user) async {
          if (user == null) {
            state = const AsyncValue.data(null);
          } else {
            try {
              final repo = _ref.read(authRepositoryProvider);
              final userEntity = await repo.getUserById(user.uid);
              state = AsyncValue.data(userEntity);
            } catch (e, st) {
              state = AsyncValue.error(e, st);
            }
          }
        },
        loading: () => state = const AsyncValue.loading(),
        error: (e, st) => state = AsyncValue.error(e, st),
      );
    });
  }

  /// Sign in with email.
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(authRepositoryProvider);
      final user = await repo.signInWithEmail(email, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Sign up with email.
  Future<void> signUpWithEmail(
      String email, String password, String name) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(authRepositoryProvider);
      final user = await repo.signUpWithEmail(email, password, name);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Sign in with Google.
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(authRepositoryProvider);
      final user = await repo.signInWithGoogle();
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Sign out.
  Future<void> signOut() async {
    final repo = _ref.read(authRepositoryProvider);
    await repo.signOut();
    state = const AsyncValue.data(null);
  }
}
