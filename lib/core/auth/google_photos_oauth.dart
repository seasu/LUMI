import 'package:google_sign_in/google_sign_in.dart';

import '../providers/firebase_providers.dart'
    show kGooglePhotosAppendOnlyScope, kGooglePhotosReadonlyScope;

/// Ensures an OAuth **access token** with the requested Google Photos scopes.
///
/// Default (`interactive = false`) is **silent**: read existing token only.
/// This avoids unexpected permission popups during background refreshes.
///
/// When user explicitly triggers an action (e.g. Login / manual Sync), set
/// `interactive: true` to allow [GoogleSignIn.requestScopes].
///
/// Returns `null` if the user denies incremental scope or no token can be resolved.
Future<String?> ensureGooglePhotosAccessToken(
  GoogleSignIn googleSignIn,
  GoogleSignInAccount? account, {
  List<String>? scopes,
  bool interactive = false,
}) async {
  if (account == null) return null;

  final scopeList = scopes ??
      const [kGooglePhotosAppendOnlyScope];

  Future<String?> extract(GoogleSignInAuthentication auth) async {
    final direct = auth.accessToken;
    if (direct != null && direct.isNotEmpty) return direct;
    try {
      final headers = await account.authHeaders;
      final bearer = headers['Authorization'] ?? headers['authorization'];
      if (bearer != null && bearer.startsWith('Bearer ')) {
        return bearer.substring(7).trim();
      }
    } catch (_) {}
    return null;
  }

  Future<String?> readAfterAuth() async {
    final auth = await account.authentication;
    return extract(auth);
  }

  // 1) Silent path first — do not prompt during passive/background flows.
  var token = await readAfterAuth();
  if (token != null) return token;
  if (!interactive) return null;

  // 2) Interactive path — only for explicit user actions.
  final granted = await googleSignIn.requestScopes(scopeList);
  if (!granted) return null;

  await account.clearAuthCache();
  token = await readAfterAuth();
  return token;
}
