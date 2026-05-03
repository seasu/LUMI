import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lumi/core/auth/google_photos_oauth.dart';
import 'package:lumi/core/providers/firebase_providers.dart';

class _FakeGoogleSignIn extends Fake implements GoogleSignIn {
  _FakeGoogleSignIn({
    required this.granted,
    this.canAccess = true,
    this.silentAccount,
    this.throwOnCanAccessScopes = false,
  });
  final bool granted;
  bool canAccess;
  GoogleSignInAccount? silentAccount;
  final bool throwOnCanAccessScopes;
  int requestScopesCalls = 0;
  int canAccessScopesCalls = 0;
  List<String>? lastScopes;

  @override
  Future<bool> canAccessScopes(
    List<String> scopes, {
    String? accessToken,
  }) async {
    canAccessScopesCalls++;
    lastScopes = scopes;
    if (throwOnCanAccessScopes) throw Exception('platform not supported');
    return canAccess;
  }

  @override
  Future<bool> requestScopes(List<String> scopes) async {
    requestScopesCalls++;
    lastScopes = scopes;
    if (granted) {
      canAccess = true;
    }
    return granted;
  }

  @override
  Future<GoogleSignInAccount?> signInSilently({
    bool suppressErrors = true,
    bool reAuthenticate = false,
  }) async =>
      silentAccount;
}

// ignore: must_be_immutable
class _FakeGoogleSignInAccount extends Fake implements GoogleSignInAccount {
  _FakeGoogleSignInAccount(
    this.onClearAuthCache, {
    List<String>? tokens,
    this.hasToken = true,
  }) : _tokens = tokens;

  static const String defaultToken = 'token-123';
  final void Function() onClearAuthCache;
  final List<String>? _tokens;
  final bool hasToken;
  int _tokenIndex = 0;

  String? get _currentToken {
    if (!hasToken) return null;
    final values = _tokens;
    if (values == null || values.isEmpty) return defaultToken;
    if (_tokenIndex >= values.length) return values.last;
    return values[_tokenIndex];
  }

  @override
  Future<GoogleSignInAuthentication> get authentication async =>
      _FakeGoogleSignInAuthentication(_currentToken);

  @override
  Future<Map<String, String>> get authHeaders async {
    final t = _currentToken;
    if (t == null) return {};
    return {'Authorization': 'Bearer $t'};
  }

  @override
  Future<void> clearAuthCache() async {
    final values = _tokens;
    if (values != null && _tokenIndex < values.length - 1) {
      _tokenIndex++;
    }
    onClearAuthCache();
  }
}

class _FakeGoogleSignInAuthentication extends Fake
    implements GoogleSignInAuthentication {
  _FakeGoogleSignInAuthentication(this._token);
  final String? _token;

  @override
  String? get accessToken => _token;
}

void main() {
  const testScopes = [kGooglePhotosAppendOnlyScope, kGooglePhotosReadonlyScope];

  // Silent path: return existing token without any scope check.
  test('silent mode returns token without checking scopes', () async {
    final googleSignIn = _FakeGoogleSignIn(granted: true, canAccess: false);
    var clearCalls = 0;
    final account = _FakeGoogleSignInAccount(() => clearCalls++);

    final token = await ensureGooglePhotosAccessToken(
      googleSignIn,
      account,
      scopes: testScopes,
      interactive: false,
    );

    expect(token, 'token-123');
    expect(googleSignIn.canAccessScopesCalls, 0);
    expect(googleSignIn.requestScopesCalls, 0);
    expect(clearCalls, 0);
  });

  // Silent path: returns null when no token can be extracted.
  test('silent mode returns null when no token is available', () async {
    final googleSignIn = _FakeGoogleSignIn(granted: true, canAccess: true);
    final account = _FakeGoogleSignInAccount(() {}, hasToken: false);

    final token = await ensureGooglePhotosAccessToken(
      googleSignIn,
      account,
      scopes: testScopes,
      interactive: false,
    );

    expect(token, isNull);
    expect(googleSignIn.canAccessScopesCalls, 0);
    expect(googleSignIn.requestScopesCalls, 0);
  });

  // Interactive path: skip requestScopes when canAccessScopes confirms all
  // required scopes are already present (iOS signIn() already obtained
  // consent; a second requestScopes call would show a redundant dialog).
  test('interactive mode returns existing token without calling requestScopes '
      'when canAccessScopes confirms all scopes', () async {
    final googleSignIn = _FakeGoogleSignIn(granted: true, canAccess: true);
    var clearCalls = 0;
    final account = _FakeGoogleSignInAccount(() => clearCalls++);

    final token = await ensureGooglePhotosAccessToken(
      googleSignIn,
      account,
      scopes: testScopes,
      interactive: true,
    );

    expect(token, 'token-123');
    expect(googleSignIn.canAccessScopesCalls, 1); // checked on pre-available token
    expect(googleSignIn.requestScopesCalls, 0);
    expect(clearCalls, 0);
  });

  // Interactive path: call requestScopes when token exists but canAccessScopes
  // reports missing scopes (e.g. only appendonly was previously granted, not
  // readonly — happens on existing accounts after a scope upgrade).
  test('interactive mode calls requestScopes when token has insufficient scopes',
      () async {
    var clearCalls = 0;
    final googleSignIn = _FakeGoogleSignIn(granted: true, canAccess: false);
    final account = _FakeGoogleSignInAccount(() => clearCalls++);

    final token = await ensureGooglePhotosAccessToken(
      googleSignIn,
      account,
      scopes: testScopes,
      interactive: true,
    );

    // canAccess starts false → requestScopes called (sets canAccess=true) →
    // signInSilently returns null → resolvedAccount=account → clearAuthCache →
    // extractToken → hasRequiredScopes (canAccess now true) → ok.
    expect(token, 'token-123');
    expect(googleSignIn.canAccessScopesCalls, 2); // pre-check + post-requestScopes check
    expect(googleSignIn.requestScopesCalls, 1);
    expect(clearCalls, 1);
  });

  // Interactive path: when canAccessScopes throws (e.g. on iOS right after
  // signIn()), trust the pre-available token instead of calling requestScopes.
  // This prevents the spurious second consent dialog observed on iOS.
  test('interactive mode trusts pre-available token when canAccessScopes throws',
      () async {
    final googleSignIn = _FakeGoogleSignIn(
      granted: true,
      throwOnCanAccessScopes: true,
    );
    var clearCalls = 0;
    final account = _FakeGoogleSignInAccount(() => clearCalls++);

    final token = await ensureGooglePhotosAccessToken(
      googleSignIn,
      account,
      scopes: testScopes,
      interactive: true,
    );

    expect(token, 'token-123');
    expect(googleSignIn.canAccessScopesCalls, 1); // called but threw
    expect(googleSignIn.requestScopesCalls, 0);   // NOT called — trust the token
    expect(clearCalls, 0);
  });

  // Interactive path: calls requestScopes when no initial token exists, then
  // refreshes via signInSilently() and verifies scopes.
  test(
      'interactive mode calls requestScopes and refreshes account '
      'when no token exists', () async {
    var clearCalls = 0;
    final freshAccount = _FakeGoogleSignInAccount(() => clearCalls++);
    final googleSignIn = _FakeGoogleSignIn(
      granted: true,
      canAccess: true,
      silentAccount: freshAccount,
    );
    final emptyAccount = _FakeGoogleSignInAccount(() {}, hasToken: false);

    final token = await ensureGooglePhotosAccessToken(
      googleSignIn,
      emptyAccount,
      scopes: testScopes,
      interactive: true,
    );

    expect(token, 'token-123'); // from freshAccount via signInSilently
    expect(googleSignIn.requestScopesCalls, 1);
    expect(googleSignIn.canAccessScopesCalls, 1);
    expect(clearCalls, 1); // clearAuthCache on the refreshed account
  });

  // clearCacheFirst clears the cache before extraction so a newer token is
  // returned even in silent mode.
  test('silent mode can refresh token after clearing auth cache', () async {
    final googleSignIn = _FakeGoogleSignIn(granted: true, canAccess: true);
    var clearCalls = 0;
    final account = _FakeGoogleSignInAccount(
      () => clearCalls++,
      tokens: const ['expired-token', 'fresh-token'],
    );

    final token = await ensureGooglePhotosAccessToken(
      googleSignIn,
      account,
      scopes: testScopes,
      interactive: false,
      clearCacheFirst: true,
    );

    expect(token, 'fresh-token');
    expect(clearCalls, 1);
    expect(googleSignIn.requestScopesCalls, 0);
  });

  // forceRequestScopes: skip the "trust pre-available token" check and jump
  // straight to requestScopes — used after a caller receives a 403 and knows
  // the token is missing a scope (even when canAccessScopes would throw).
  test('forceRequestScopes skips canAccessScopes and calls requestScopes '
      'even when a token already exists', () async {
    var clearCalls = 0;
    // canAccess=true: if we checked canAccessScopes it would report all scopes
    // present — forceRequestScopes must override this and still call requestScopes.
    final googleSignIn = _FakeGoogleSignIn(granted: true, canAccess: true);
    final account = _FakeGoogleSignInAccount(() => clearCalls++);

    final token = await ensureGooglePhotosAccessToken(
      googleSignIn,
      account,
      scopes: testScopes,
      interactive: true,
      forceRequestScopes: true,
    );

    expect(token, 'token-123');
    // Pre-check skipped (forceRequestScopes bypasses it).
    // Post-grant hasRequiredScopes calls canAccessScopes once to verify.
    expect(googleSignIn.canAccessScopesCalls, 1);
    expect(googleSignIn.requestScopesCalls, 1);
    expect(clearCalls, 1); // clearAuthCache after grant
  });

  // iOS WKWebView workaround: requestScopes returns false even when the user
  // successfully approved the consent sheet (a known timing issue in the
  // google_sign_in iOS plugin). We must NOT return null in this case —
  // instead we extract a fresh token and let the API call be the real check.
  test('returns token even when requestScopes returns false '
      '(iOS WKWebView completion unreliability workaround)', () async {
    var clearCalls = 0;
    // granted=false simulates iOS where the completion fires before the SDK
    // updates the token, causing requestScopes to report false despite the
    // user having approved the scopes.
    final googleSignIn = _FakeGoogleSignIn(granted: false, canAccess: true);
    final account = _FakeGoogleSignInAccount(() => clearCalls++);

    final token = await ensureGooglePhotosAccessToken(
      googleSignIn,
      account,
      scopes: testScopes,
      interactive: true,
      forceRequestScopes: true,
    );

    // Token must be returned despite granted=false, because the underlying
    // scope may have been granted and the API call will confirm.
    expect(token, 'token-123');
    expect(googleSignIn.requestScopesCalls, 1);
    // hasRequiredScopes calls canAccessScopes once after extraction.
    expect(googleSignIn.canAccessScopesCalls, 1);
    expect(clearCalls, 1);
  });
}
