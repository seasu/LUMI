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

Future<void> signOut(WidgetRef ref) async {
  await ref.read(authRepositoryProvider).signOut();
}
