/// Corner radius scale for Lumi UI.
/// Align with [DESIGN.md] (soft corners, capsule CTAs). Use instead of magic numbers.
abstract class LumiRadii {
  LumiRadii._();

  /// Chips, small controls.
  static const double sm = 8;

  /// Thumbnails, small cards.
  static const double md = 12;

  /// Wardrobe cards, standard surfaces.
  static const double lg = 16;

  /// Sheets, large cards.
  static const double xl = 24;

  /// Full pill / capsule buttons.
  static const double pill = 9999;
}
