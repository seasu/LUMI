/// Firestore must store Google Photos API [baseUrl] / [productUrl] (image CDN),
/// not a browser link like `https://photos.google.com/album/.../photo/...`.
bool wardrobeThumbnailNeedsApiRefresh(String thumbnailUrl) {
  final u = Uri.tryParse(thumbnailUrl.trim());
  if (u == null || !u.hasScheme) return true;
  final host = u.host.toLowerCase();
  // Browser UI — Image.network receives HTML, not raw image bytes.
  if (host == 'photos.google.com' || host.endsWith('.photos.google.com')) {
    return true;
  }
  return false;
}
