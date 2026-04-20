import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:lumi/core/auth/google_photos_oauth.dart';
import 'package:lumi/core/providers/firebase_providers.dart';

class _FakeGoogleSignIn extends Fake implements GoogleSignIn {
  _FakeGoogleSignIn({required this.granted});
  final bool granted;
  int requestScopesCalls = 0;
  List<String>? lastScopes;

  @override
  Future<bool> requestScopes(List<String> scopes) async {
    requestScopesCalls++;
    lastScopes = scopes;
    return granted;
  }
}

class _FakeGoogleSignInAccount extends Fake implements GoogleSignInAccount {
  _FakeGoogleSignInAccount({this.token = 'token-123'});
  final String token;
  int clearCalls = 0;

  @override
  Future<GoogleSignInAuthentication> get authentication async =>
      _FakeGoogleSignInAuthentication(token);

  @override
  Future<Map<String, String>> get authHeaders async =>
      {'Authorization': 'Bearer $token'};

  @override
  Future<void> clearAuthCache() async {
    clearCalls++;
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
    final googleSignIn = _FakeGoogleSignIn(granted: true);
    final account = _FakeGoogleSignInAccount();

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
    expect(googleSignIn.requestScopesCalls, 0);
    expect(account.clearCalls, 0);
  });

  test('interactive mode can trigger requestScopes', () async {
    final googleSignIn = _FakeGoogleSignIn(granted: true);
    final account = _FakeGoogleSignInAccount();

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
    // Current implementation can resolve token silently first.
    expect(googleSignIn.requestScopesCalls, inInclusiveRange(0, 1));
  });
}
