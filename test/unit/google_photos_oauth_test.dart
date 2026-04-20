import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lumi/core/auth/google_photos_oauth.dart';
import 'package:lumi/core/providers/firebase_providers.dart';

class _FakeGoogleSignIn extends Fake implements GoogleSignIn {
  _FakeGoogleSignIn({
    required this.granted,
    this.canAccess = true,
  });
  final bool granted;
  bool canAccess;
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
}

class _FakeGoogleSignInAccount extends Fake implements GoogleSignInAccount {
  _FakeGoogleSignInAccount(this.onClearAuthCache);
  static const String token = 'token-123';
  final void Function() onClearAuthCache;

  @override
  Future<GoogleSignInAuthentication> get authentication async =>
      _FakeGoogleSignInAuthentication(token);

  @override
  Future<Map<String, String>> get authHeaders async =>
      {'Authorization': 'Bearer $token'};

  @override
  Future<void> clearAuthCache() async {
    onClearAuthCache();
  }
}

class _FakeGoogleSignInAuthentication extends Fake
    implements GoogleSignInAuthentication {
  _FakeGoogleSignInAuthentication(this._token);
  final String _token;

  @override
  String? get accessToken => _token;
}

void main() {
  test('silent mode does not trigger requestScopes', () async {
    final googleSignIn = _FakeGoogleSignIn(granted: true, canAccess: true);
    var clearCalls = 0;
    final account = _FakeGoogleSignInAccount(() => clearCalls++);

    final token = await ensureGooglePhotosAccessToken(
      googleSignIn,
      account,
      scopes: const [
        kGooglePhotosAppendOnlyScope,
        kGooglePhotosReadonlyScope,
      ],
      interactive: false,
    );

    expect(token, 'token-123');
    expect(googleSignIn.canAccessScopesCalls, 1);
    expect(googleSignIn.requestScopesCalls, 0);
    expect(clearCalls, 0);
  });

  test('silent mode returns null when required scopes are missing', () async {
    final googleSignIn = _FakeGoogleSignIn(granted: true, canAccess: false);
    final account = _FakeGoogleSignInAccount(() {});

    final token = await ensureGooglePhotosAccessToken(
      googleSignIn,
      account,
      scopes: const [
        kGooglePhotosAppendOnlyScope,
        kGooglePhotosReadonlyScope,
      ],
      interactive: false,
    );

    expect(token, isNull);
    expect(googleSignIn.canAccessScopesCalls, 1);
    expect(googleSignIn.requestScopesCalls, 0);
  });

  test('interactive mode requests scopes when current token is insufficient', () async {
    final googleSignIn = _FakeGoogleSignIn(granted: true, canAccess: false);
    var clearCalls = 0;
    final account = _FakeGoogleSignInAccount(() => clearCalls++);

    final token = await ensureGooglePhotosAccessToken(
      googleSignIn,
      account,
      scopes: const [
        kGooglePhotosAppendOnlyScope,
        kGooglePhotosReadonlyScope,
      ],
      interactive: true,
    );

    expect(token, 'token-123');
    expect(googleSignIn.canAccessScopesCalls, 1);
    expect(googleSignIn.requestScopesCalls, 1);
    expect(clearCalls, 1);
  });
}
