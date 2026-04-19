import 'package:google_sign_in/google_sign_in.dart';

import '../providers/firebase_providers.dart'
    show kGooglePhotosAppendOnlyScope;

/// Ensures an OAuth **access token** with the requested Google Photos scopes.
///
/// Default is [kGooglePhotosAppendOnlyScope] only. Pass [scopes] to request
/// multiple scopes (e.g. append + readonly for album sync).
///
/// Returns `null` if the user denies incremental scope or no token can be resolved.
Future<String?> ensureGooglePhotosAccessToken(
  GoogleSignIn googleSignIn,
  GoogleSignInAccount? account, {
  List<String>? scopes,
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

  var token = await readAfterAuth();
  if (token != null) return token;

  final granted = await googleSignIn.requestScopes(scopeList);
  if (!granted) return null;

  await account.clearAuthCache();
  token = await readAfterAuth();
  return token;
}
