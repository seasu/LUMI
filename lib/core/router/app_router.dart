import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/firebase_providers.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/loading_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/check/presentation/check_page.dart';
import '../../features/main/presentation/main_shell.dart';
import '../../features/main/presentation/outfit_page.dart';
import '../../features/main/presentation/profile_page.dart';
import '../../features/onboarding/presentation/onboarding_page.dart';
import '../../features/ootd/presentation/ootd_add_page.dart';
import '../../features/search/presentation/search_page.dart';
import '../../features/snap/presentation/snap_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final authNotifier = ValueNotifier<AsyncValue<User?>>(ref.read(authStateProvider));

  ref.listen<AsyncValue<User?>>(authStateProvider, (_, next) {
    authNotifier.value = next;
  });

  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authValue = authNotifier.value;
      if (authValue is AsyncLoading) return null;

      // Web popup / consent flows can briefly surface a stale `null` event while
      // Firebase is still restoring the active user. Fall back to
      // `FirebaseAuth.currentUser` to avoid flashing back to `/login`.
      final resolvedUser = authValue.valueOrNull ?? auth.currentUser;
      final isLoggedIn = resolvedUser != null;
      final loc = state.matchedLocation;

      // Not logged in → send to login (except already there)
      if (!isLoggedIn) {
        if (loc == '/login') return null;
        return '/login';
      }

      // Logged in but on login page → go to loading (handles onboarding check)
      if (loc == '/login') return '/loading';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoginPage(),
        ),
      ),
      GoRoute(
        path: '/loading',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: LoadingPage(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => const NoTransitionPage(
          child: OnboardingPage(),
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SearchPage(),
            ),
          ),
          GoRoute(
            path: '/home/outfits',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: OutfitPage(),
            ),
          ),
          GoRoute(
            path: '/home/profile',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProfilePage(),
            ),
          ),
        ],
      ),
      GoRoute(
        path: '/snap',
        builder: (context, state) => const SnapPage(),
      ),
      GoRoute(
        path: '/check',
        builder: (context, state) => const CheckPage(),
      ),
      GoRoute(
        path: '/ootd/add',
        builder: (context, state) => const OotdAddPage(),
      ),
    ],
  );
});
