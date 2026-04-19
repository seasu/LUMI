import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/auth_repository.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final signInLoadingProvider = StateProvider<bool>((ref) => false);

Future<void> signInWithGoogle(WidgetRef ref) async {
  ref.read(signInLoadingProvider.notifier).state = true;
  try {
    await ref.read(authRepositoryProvider).signInWithGoogle();
  } finally {
    ref.read(signInLoadingProvider.notifier).state = false;
  }
}

/// Clears [signInLoadingProvider] so the login button never stays stuck after logout
/// (e.g. user left during sign-in, or Web Google sign-out is slow).
Future<void> signOut(WidgetRef ref) async {
  ref.read(signInLoadingProvider.notifier).state = false;
  try {
    await ref.read(authRepositoryProvider).signOut();
  } finally {
    ref.read(signInLoadingProvider.notifier).state = false;
  }
}
