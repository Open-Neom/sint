import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../../core/src/sint_main.dart';
import '../../domain/extensions/navigation_extensions.dart';

/// A Sint-aware AppBar that integrates with Sint's routing stack.
///
/// Inherits AppBarChild's benefits:
/// - Custom height (default 50.0, matching AppTheme.appBarHeight)
/// - Auto-capitalize title (toggleable via [capitalize])
/// - Consistent dark elevated background color
///
/// Sint-specific benefits:
/// - Back button uses `Sint.back()` (updates browser URL on web)
/// - Fallback route when no back history exists
/// - Auto-detects root routes to hide back button
/// - Supports `bottom:` widget (TabBar)
///
/// Usage:
/// ```dart
/// SintAppBar(title: 'Dashboard ERP')
/// SintAppBar(title: 'shop', actions: [...], fallbackRoute: '/home')
/// ```
class SintAppBar extends StatelessWidget implements PreferredSizeWidget {

  /// The title text displayed in the AppBar.
  final String title;

  /// Optional widget displayed before the title (e.g., an icon or avatar).
  final Widget? preTitle;

  /// Background color. If null, uses the app's elevated surface color.
  /// Pass `Colors.transparent` for modal/sheet pages.
  final Color? backgroundColor;

  /// Action widgets on the right side of the AppBar.
  final List<Widget>? actions;

  /// Whether to center the title. Defaults to null (platform default).
  final bool? centerTitle;

  /// Custom leading widget. If provided, overrides the Sint back button.
  final Widget? leading;

  /// Title spacing override.
  final double? titleSpacing;

  /// Route to navigate to when there's no back history in the Sint stack.
  /// Defaults to `'/'`.
  final String fallbackRoute;

  /// AppBar elevation. Defaults to 0.
  final double elevation;

  /// Title text style override. If null, uses white bold text.
  final TextStyle? titleStyle;

  /// Whether to show the back button. If null, automatically determined
  /// based on the current route and Sint stack.
  final bool? showBackButton;

  /// Bottom widget (e.g., TabBar).
  final PreferredSizeWidget? bottom;

  /// Whether to auto-capitalize the first letter of the title.
  /// Defaults to true (matching AppBarChild behavior).
  final bool capitalize;

  /// Custom AppBar height. Defaults to 50.0 (matching AppTheme.appBarHeight).
  final double height;

  const SintAppBar({
    super.key,
    this.title = '',
    this.preTitle,
    this.backgroundColor,
    this.actions,
    this.centerTitle,
    this.leading,
    this.titleSpacing,
    this.fallbackRoute = '/',
    this.elevation = 0,
    this.titleStyle,
    this.showBackButton,
    this.bottom,
    this.capitalize = true,
    this.height = 50.0,
  });

  @override
  Size get preferredSize {
    final bottomHeight = bottom?.preferredSize.height ?? 0;
    return Size.fromHeight(height + bottomHeight);
  }

  @override
  Widget build(BuildContext context) {
    final shouldShowBack = showBackButton ?? _shouldShowBackButton();

    return AppBar(
      leading: leading ?? (shouldShowBack ? _buildBackButton() : null),
      automaticallyImplyLeading: false,
      title: _buildTitle(),
      titleSpacing: titleSpacing,
      backgroundColor: backgroundColor,
      elevation: elevation,
      actions: actions,
      centerTitle: centerTitle,
      bottom: bottom,
      toolbarHeight: height,
    );
  }

  /// Capitalizes the first letter of a string (mirrors GetX .capitalize).
  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  Widget _buildTitle() {
    final displayTitle = capitalize ? _capitalize(title) : title;
    final style = titleStyle ?? TextStyle(
      color: Colors.white.withAlpha(204),
      fontWeight: FontWeight.bold,
    );

    if (preTitle != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          preTitle!,
          const SizedBox(width: 10),
          Flexible(
            child: Text(displayTitle, style: style, overflow: TextOverflow.ellipsis),
          ),
        ],
      );
    }

    return Text(displayTitle, style: style, overflow: TextOverflow.ellipsis);
  }

  Widget _buildBackButton() {
    return IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      tooltip: 'Back',
      onPressed: () {
        if (_canSintGoBack()) {
          Sint.back();
        } else {
          Sint.offAllNamed(fallbackRoute);
        }
      },
    );
  }

  /// Whether Sint's route stack has a previous page to go back to.
  static bool _canSintGoBack() {
    try {
      return Sint.rootController.rootDelegate.canBack;
    } catch (_) {
      return false;
    }
  }

  bool _shouldShowBackButton() {
    final current = Sint.currentRoute;
    final isRootRoute = current == '/' || current == '/root'
        || current == '/home' || current == '/login' || current.isEmpty;

    if (isRootRoute) return false;

    // On web, always show back for non-root routes
    if (kIsWeb) return true;

    // On mobile, show if Sint has back history
    return _canSintGoBack();
  }
}
