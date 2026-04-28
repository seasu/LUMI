import 'package:google_sign_in/google_sign_in.dart';

import '../debug/debug_log.dart';
import '../providers/firebase_providers.dart'
    show kGooglePhotosAppendOnlyScope;

void _log(String msg) => DebugLogService.instance.log('[token] $msg');

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
  bool clearCacheFirst = false,
}) async {
  if (account == null) {
    _log('ensureAccessToken → account=null, skip');
    return null;
  }

  final scopeList = scopes ??
      const [kGooglePhotosAppendOnlyScope];

  _log('ensureAccessToken → interactive=$interactive'
      ' scopes=${scopeList.length} clearCache=$clearCacheFirst');

  Future<bool> hasRequiredScopes(String accessToken) async {
    try {
      return await googleSignIn.canAccessScopes(
        scopeList,
        accessToken: accessToken,
      );
    } catch (_) {
      // Fall back to the existing token on platforms that cannot introspect
      // granted scopes yet.
      return true;
    }
  }

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

  if (clearCacheFirst) {
    try {
      await account.clearAuthCache();
      _log('ensureAccessToken: cache cleared');
    } catch (_) {
      // Best-effort only: some platforms may not have a cache to clear.
    }
  }

  // 1) Silent path — used by passive/background flows.
  var token = await readAfterAuth();
  if (!interactive) {
    if (token != null && await hasRequiredScopes(token)) {
      _log('ensureAccessToken ← ok (silent)');
      return token;
    }
    _log('ensureAccessToken ← null (silent, no valid token)');
    return null;
  }

  // 2) Interactive path — explicit user action may refresh scope grants and
  // should return a freshly-minted token rather than trusting the current one.
  _log('ensureAccessToken: requesting scopes interactively…');
  final granted = await googleSignIn.requestScopes(scopeList);
  if (!granted) {
    _log('ensureAccessToken ← null (user denied scopes)');
    return null;
  }

  try {
    await account.clearAuthCache();
  } catch (_) {
    // Best-effort only: still attempt to read a fresh token afterwards.
  }
  token = await readAfterAuth();
  if (token == null) {
    _log('ensureAccessToken ← null (no token after grant)');
    return null;
  }
  if (await hasRequiredScopes(token)) {
    _log('ensureAccessToken ← ok (interactive)');
    return token;
  }
  _log('ensureAccessToken ← null (token lacks required scopes)');
  return null;
}
