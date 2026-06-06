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
import 'package:image_picker/image_picker.dart';
import '../../features/ootd/presentation/ootd_add_page.dart';
import '../../features/purchase/presentation/widgets/paywall_sheet.dart'
    show PaywallSheet;
import '../../features/search/presentation/search_page.dart';
import '../../features/snap/presentation/snap_page.dart';
import '../../shared/constants/lumi_colors.dart';
import 'navigator_keys.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.watch(firebaseAuthProvider);
  final authNotifier = ValueNotifier<AsyncValue<User?>>(ref.read(authStateProvider));

  ref.listen<AsyncValue<User?>>(authStateProvider, (_, next) {
    authNotifier.value = next;
  });

  ref.onDispose(authNotifier.dispose);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
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
        builder: (context, state) {
          final src = state.uri.queryParameters['source'];
          ImageSource? autoSource;
          if (src == 'camera') autoSource = ImageSource.camera;
          if (src == 'gallery') autoSource = ImageSource.gallery;
          return SnapPage(autoSource: autoSource);
        },
      ),
      GoRoute(
        path: '/check',
        builder: (context, state) {
          final src = state.uri.queryParameters['source'];
          ImageSource? autoSource;
          if (src == 'camera') autoSource = ImageSource.camera;
          if (src == 'gallery') autoSource = ImageSource.gallery;
          return CheckPage(autoSource: autoSource);
        },
      ),
      GoRoute(
        path: '/ootd/add',
        builder: (context, state) {
          final src = state.uri.queryParameters['source'];
          final source =
              src == 'gallery' ? ImageSource.gallery : ImageSource.camera;
          return OotdAddPage(source: source);
        },
      ),
      // Paywall uses a transparent declarative route so GoRouter owns its
      // lifecycle. Using showModalBottomSheet imperatively caused GoRouter's
      // refreshListenable rebuilds to reconcile the navigator pages list and
      // silently remove the modal route → black screen on iOS.
      GoRoute(
        path: '/paywall',
        pageBuilder: (context, state) => CustomTransitionPage<void>(
          key: state.pageKey,
          opaque: false,
          barrierDismissible: true,
          barrierColor: LumiColors.overlayBarrier,
          child: const Material(
            type: MaterialType.transparency,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: PaywallSheet(),
            ),
          ),
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 250),
          transitionsBuilder: (context, animation, _, child) =>
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 1),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
                child: child,
              ),
        ),
      ),
    ],
  );
});
