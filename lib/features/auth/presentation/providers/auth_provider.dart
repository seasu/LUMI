import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

enum SignInMethod { none, google, apple }

final signInLoadingProvider =
    StateProvider<SignInMethod>((ref) => SignInMethod.none);

Future<void> signInWithGoogle(WidgetRef ref) async {
  ref.read(signInLoadingProvider.notifier).state = SignInMethod.google;
  try {
    await ref.read(authRepositoryProvider).signInWithGoogle();
  } finally {
    ref.read(signInLoadingProvider.notifier).state = SignInMethod.none;
  }
}

Future<void> signInWithApple(WidgetRef ref) async {
  ref.read(signInLoadingProvider.notifier).state = SignInMethod.apple;
  try {
    await ref.read(authRepositoryProvider).signInWithApple();
  } finally {
    ref.read(signInLoadingProvider.notifier).state = SignInMethod.none;
  }
}

/// Clears [signInLoadingProvider] so the login button never stays stuck after logout.
Future<void> signOut(WidgetRef ref) async {
  ref.read(signInLoadingProvider.notifier).state = SignInMethod.none;
  try {
    await ref.read(authRepositoryProvider).signOut();
  } finally {
    ref.read(signInLoadingProvider.notifier).state = SignInMethod.none;
  }
}
