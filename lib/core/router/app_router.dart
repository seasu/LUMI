import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/check/presentation/check_page.dart';
import '../../features/search/presentation/search_page.dart';
import '../../features/snap/presentation/snap_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  // Initialize with current auth state so the router doesn't get stuck on
  // AsyncLoading if Firebase already restored a session before this provider built.
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

      // Still loading — don't redirect yet
      if (authValue is AsyncLoading) return null;

      final isLoggedIn = authValue.valueOrNull != null;
      final isLoginPage = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn && isLoginPage) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const SearchPage(),
      ),
      GoRoute(
        path: '/snap',
        builder: (context, state) => const SnapPage(),
      ),
      GoRoute(
        path: '/check',
        builder: (context, state) => const CheckPage(),
      ),
    ],
  );
});
