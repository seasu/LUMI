import 'package:flutter_test/flutter_test.dart';
import 'package:lumi/features/wardrobe/utils/wardrobe_thumbnail_url.dart';

void main() {
  test('photos.google.com browser URL needs API refresh', () {
    expect(
      wardrobeThumbnailNeedsApiRefresh(
        'https://photos.google.com/album/x/photo/y',
      ),
      isTrue,
    );
  });

  test('Google CDN-like host does not force refresh by host rule', () {
    expect(
      wardrobeThumbnailNeedsApiRefresh(
        'https://lh3.googleusercontent.com/xyz=s2048',
      ),
      isFalse,
    );
  });

  test('invalid URL needs refresh', () {
    expect(wardrobeThumbnailNeedsApiRefresh('not-a-url'), isTrue);
    expect(wardrobeThumbnailNeedsApiRefresh(''), isTrue);
  });
}
