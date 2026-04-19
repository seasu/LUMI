import 'package:google_sign_in/google_sign_in.dart';

import '../providers/firebase_providers.dart'
    show kGooglePhotosAppendOnlyScope, kGooglePhotosReadonlyScope;

/// Ensures an OAuth **access token** with the requested Google Photos scopes.
///
/// **Append-only** (`scopes` default): reuse token when possible; otherwise
/// [GoogleSignIn.requestScopes].
///
/// **Includes [kGooglePhotosReadonlyScope]** (list albums / wardrobe sync):
/// Always calls [GoogleSignIn.requestScopes] then [GoogleSignInAccount.clearAuthCache]
/// before reading the token. On Web, [GoogleSignIn.canAccessScopes] could report true
/// while the Bearer token still lacked `photoslibrary.readonly` for `GET /albums`
/// (403). If scopes were already granted, [requestScopes] returns without a dialog.
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

  final needsAlbumListScope = scopeList.contains(kGooglePhotosReadonlyScope);

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

  // ── Album list / sync: append + readonly ─────────────────────────────────────
  if (needsAlbumListScope) {
    final granted = await googleSignIn.requestScopes(scopeList);
    if (!granted) return null;

    await account.clearAuthCache();
    return readAfterAuth();
  }

  // ── Append-only only (Snap upload etc.) ──────────────────────────────────────
  var token = await readAfterAuth();
  if (token != null) return token;

  final granted = await googleSignIn.requestScopes(scopeList);
  if (!granted) return null;

  await account.clearAuthCache();
  token = await readAfterAuth();
  return token;
}
