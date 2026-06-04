import 'package:flutter/material.dart';

/// The root [NavigatorState] key passed to [GoRouter.navigatorKey].
///
/// Use this to imperatively show dialogs / sheets that must sit above the
/// ShellRoute's inner navigator (e.g. paywall, permission prompts).
/// Using the key's currentContext bypasses the widget-tree traversal that
/// Navigator.of(context, rootNavigator: true) relies on, which can be
/// unreliable inside nested navigators on iOS.
final rootNavigatorKey = GlobalKey<NavigatorState>();
