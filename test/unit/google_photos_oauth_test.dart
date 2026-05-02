import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lumi/core/auth/google_photos_oauth.dart';
import 'package:lumi/core/providers/firebase_providers.dart';

class _FakeGoogleSignIn extends Fake implements GoogleSignIn {
  _FakeGoogleSignIn({
    required this.granted,
    this.canAccess = true,
    this.silentAccount,
  });
  final bool granted;
  bool canAccess;
  GoogleSignInAccount? silentAccount;
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

  // Interactive path: skip requestScopes when a token already exists (iOS
  // signIn() already obtained consent; a second requestScopes call would show
  // a redundant authorization dialog).
  test('interactive mode returns existing token without calling requestScopes',
      () async {
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
    expect(googleSignIn.requestScopesCalls, 0);
    expect(googleSignIn.canAccessScopesCalls, 0);
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
}
