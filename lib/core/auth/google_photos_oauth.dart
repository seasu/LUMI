import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

import '../providers/firebase_providers.dart'
    show kGooglePhotosAppendOnlyScope, kGooglePhotosReadonlyScope;

/// Ensures an OAuth **access token** with the requested Google Photos scopes.
///
/// **Append-only only** (`scopes` default): reuse existing token when possible;
/// prompt with [GoogleSignIn.requestScopes] only when needed.
///
/// **Includes [kGooglePhotosReadonlyScope]** (album sync): tries to reuse tokens
/// first — on Web uses [GoogleSignIn.canAccessScopes] to skip redundant consent
/// dialogs after the user has already approved once.
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
    // Web: if already authorized, reuse token — avoids a consent popup every time.
    if (kIsWeb) {
      try {
        final already =
            await googleSignIn.canAccessScopes(account, scopeList);
        if (already) {
          final t = await readAfterAuth();
          if (t != null) return t;
          await account.clearAuthCache();
          final t2 = await readAfterAuth();
          if (t2 != null) return t2;
        }
      } catch (_) {
        // Older clients / stubs: fall through
      }
    } else {
      // Mobile: scopes are usually granted at sign-in — try reuse before prompting.
      var t = await readAfterAuth();
      if (t != null) return t;
      await account.clearAuthCache();
      t = await readAfterAuth();
      if (t != null) return t;
    }

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
