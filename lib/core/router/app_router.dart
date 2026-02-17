/// AI Muse — Application Router
/// GoRouter configuration with auth-guarded routes.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/onboarding/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/signup_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/home/persona_profile_screen.dart';
import '../../presentation/screens/chat/chat_screen.dart';
import '../../presentation/screens/voice_call/voice_call_screen.dart';
import '../../presentation/screens/video_call/video_call_screen.dart';
import '../../presentation/screens/profile/profile_screen.dart';
import '../../presentation/screens/subscription/subscription_screen.dart';
import '../../presentation/providers/auth_provider.dart';

/// Route path constants for type safety.
class AppRoutes {
  AppRoutes._();
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/';
  static const String personaProfile = '/persona/:personaId';
  static const String chat = '/chat/:personaId';
  static const String voiceCall = '/voice-call/:personaId';
  static const String videoCall = '/video-call/:personaId';
  static const String profile = '/profile';
  static const String subscription = '/subscription';
}

/// Notifier that listens to auth changes and triggers GoRouter refresh.
class AuthChangeNotifier extends ChangeNotifier {
  AuthChangeNotifier(Ref ref) {
    // Listen to currentUserProvider (handles both Firebase and Guest auth)
    ref.listen(currentUserProvider, (_, __) {
      notifyListeners();
    });
    ref.listen(authStateProvider, (_, __) {
      notifyListeners();
    });
  }
}

/// Provider for the auth change notifier.
final authChangeNotifierProvider = Provider<AuthChangeNotifier>((ref) {
  return AuthChangeNotifier(ref);
});

/// GoRouter provider with auth redirect logic.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authNotifier = ref.watch(authChangeNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: authNotifier,

    // Redirect unauthenticated users to login
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final currentUser = ref.read(currentUserProvider);

      // Check both Firebase auth AND local guest/demo user
      final isFirebaseLoggedIn = authState.valueOrNull != null;
      final isGuestLoggedIn = currentUser.valueOrNull != null;
      final isLoggedIn = isFirebaseLoggedIn || isGuestLoggedIn;

      final currentPath = state.matchedLocation;
      final isPublicRoute = currentPath == AppRoutes.splash ||
          currentPath == AppRoutes.onboarding ||
          currentPath == AppRoutes.login ||
          currentPath == AppRoutes.signup;

      // If logged in and on login/signup, redirect to home
      if (isLoggedIn && (currentPath == AppRoutes.login || currentPath == AppRoutes.signup)) {
        return AppRoutes.home;
      }

      // If not logged in and trying to access protected route, go to login
      if (!isLoggedIn && !isPublicRoute) {
        return AppRoutes.login;
      }

      return null;
    },

    routes: [
      // ── Public Routes ────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Auth Routes ──────────────────────────────────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // ── Main Routes ──────────────────────────────────────────
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.personaProfile,
        name: 'personaProfile',
        pageBuilder: (context, state) {
          final personaId = state.pathParameters['personaId']!;
          return CustomTransitionPage(
            child: PersonaProfileScreen(personaId: personaId),
            transitionsBuilder: (context, animation, _, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        pageBuilder: (context, state) {
          final personaId = state.pathParameters['personaId']!;
          return CustomTransitionPage(
            child: ChatScreen(personaId: personaId),
            transitionsBuilder: (context, animation, _, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              );
            },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.voiceCall,
        name: 'voiceCall',
        pageBuilder: (context, state) {
          final personaId = state.pathParameters['personaId']!;
          return MaterialPage(
            child: VoiceCallScreen(personaId: personaId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.videoCall,
        name: 'videoCall',
        pageBuilder: (context, state) {
          final personaId = state.pathParameters['personaId']!;
          return MaterialPage(
            child: VideoCallScreen(personaId: personaId),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.subscription,
        name: 'subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
    ],

    // Error page
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Center(
        child: Text(
          'Page not found',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
      ),
    ),
  );
});
