import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/snap/data/cloud_functions_service.dart'
    show cloudFunctionsServiceProvider;
import '../../data/auth_repository.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

enum SignInMethod { none, google, apple }

final signInLoadingProvider =
    StateProvider<SignInMethod>((ref) => SignInMethod.none);

Future<void> signInWithGoogle(WidgetRef ref) async {
  final loading = ref.read(signInLoadingProvider.notifier);
  final auth = ref.read(authRepositoryProvider);
  loading.state = SignInMethod.google;
  try {
    await auth.signInWithGoogle();
  } finally {
    loading.state = SignInMethod.none;
  }
}

Future<void> signInWithApple(WidgetRef ref) async {
  final loading = ref.read(signInLoadingProvider.notifier);
  final auth = ref.read(authRepositoryProvider);
  loading.state = SignInMethod.apple;
  try {
    await auth.signInWithApple();
  } finally {
    loading.state = SignInMethod.none;
  }
}

/// Permanently deletes the account: calls the `deleteAccount` CF then signs out locally.
/// Clears the loading state before any await to avoid "ref disposed" errors on iOS.
Future<void> deleteAccount(WidgetRef ref) async {
  final loading = ref.read(signInLoadingProvider.notifier);
  final auth = ref.read(authRepositoryProvider);
  final functions = ref.read(cloudFunctionsServiceProvider);
  loading.state = SignInMethod.none;
  await functions.deleteAccount();
  await auth.signOut();
}

/// Clears [signInLoadingProvider] so the login button never stays stuck after logout.
Future<void> signOut(WidgetRef ref) async {
  // Read providers before the first await: Firebase signOut fires auth-state changes
  // synchronously on iOS, causing GoRouter to pop the calling widget before the
  // finally block runs — any ref.read() after the await would throw "ref disposed".
  final loading = ref.read(signInLoadingProvider.notifier);
  final auth = ref.read(authRepositoryProvider);
  loading.state = SignInMethod.none;
  try {
    await auth.signOut();
  } finally {
    loading.state = SignInMethod.none;
  }
}
