/// Semantic font sizes for Lumi UI (logical px).
/// App [ThemeData] sets Noto Sans TC globally; use these sizes for hierarchy.
/// Wordmark / logo script stays separate (Dancing Script — see `pubspec.yaml` fonts).
abstract class LumiTypeScale {
  LumiTypeScale._();

  /// Large screen titles, zero-state hero titles.
  static const double displayLg = 52;

  /// Page titles (e.g. 我的衣櫥).
  static const double headlineMd = 28;

  /// Section titles, modal titles.
  static const double titleLg = 20;

  /// List item titles, emphasis body.
  static const double titleSm = 16;

  /// Body, buttons.
  static const double body = 15;

  /// Captions, metadata, tab labels.
  static const double labelMd = 13;

  /// Small chips, badges.
  static const double labelSm = 11;
}
