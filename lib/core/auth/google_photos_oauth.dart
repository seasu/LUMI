import 'package:google_sign_in/google_sign_in.dart';

import '../providers/firebase_providers.dart' show kGooglePhotosAppendOnlyScope;

/// Ensures an OAuth **access token** for [kGooglePhotosAppendOnlyScope] is available.
///
/// Call once after Google Sign-In when the user has chosen an account (e.g. at login).
/// On Web/Safari, [GoogleSignInAuthentication.accessToken] may stay null until
/// [GoogleSignIn.requestScopes] completes; [GoogleSignInAccount.authHeaders] may
/// carry the Bearer token instead.
///
/// Returns `null` if the user denies incremental scope or no token can be resolved.
Future<String?> ensureGooglePhotosAccessToken(
  GoogleSignIn googleSignIn,
  GoogleSignInAccount? account, {
  String scope = kGooglePhotosAppendOnlyScope,
}) async {
  if (account == null) return null;

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

  var token = await readAfterAuth();
  if (token != null) return token;

  final granted = await googleSignIn.requestScopes([scope]);
  if (!granted) return null;

  await account.clearAuthCache();
  token = await readAfterAuth();
  return token;
}
