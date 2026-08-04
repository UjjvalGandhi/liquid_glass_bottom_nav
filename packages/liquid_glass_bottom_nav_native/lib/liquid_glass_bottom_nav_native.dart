import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// One tab in the native bottom bar.
///
/// [sfSymbol] is an SF Symbols name (e.g. `house.fill`, `magnifyingglass`,
/// `person.fill`) rendered by iOS itself.
class LiquidGlassNavItem {
  const LiquidGlassNavItem({required this.title, required this.sfSymbol});

  final String title;
  final String sfSymbol;

  Map<String, Object> toMap() => {'title': title, 'sfSymbol': sfSymbol};
}

/// A bottom navigation bar rendered natively by iOS's system tab bar
/// (a real `UITabBarController` under the hood).
///
/// On iOS 26+ this is the Liquid Glass treatment: the floating glass
/// pill, sliding selection platter, and — when [showSearchTab] is true —
/// the separated circular search button that morphs into the system
/// search field. On iOS 16–25 the same widget renders the classic flat
/// tab bar, with search as a regular tab that opens a standard search
/// field. The API and callbacks are identical on every version.
///
/// Place it at the bottom of a fullscreen `Stack`. While the native search
/// field is open the widget grows to cover the whole screen so the field
/// and keyboard can render; the native layer is transparent, so your
/// content stays visible behind it.
///
/// iOS-only: on other platforms it renders [fallback] (or nothing).
class LiquidGlassBottomNav extends StatefulWidget {
  const LiquidGlassBottomNav({
    required this.items,
    this.selectedIndex = 0,
    this.showSearchTab = true,
    this.searchPlaceholder = 'Search',
    this.collapsedHeight = 112,
    this.onTabSelected,
    this.onSearchActivated,
    this.onSearchDismissed,
    this.onSearchChanged,
    this.fallback,
    super.key,
  });

  final List<LiquidGlassNavItem> items;

  /// Tab shown as selected when the bar is first created.
  final int selectedIndex;

  /// Adds the system search tab: the separate circular glass button that
  /// expands into the native search field when tapped.
  final bool showSearchTab;

  final String searchPlaceholder;

  /// Height of the bar strip when search is closed.
  final double collapsedHeight;

  final ValueChanged<int>? onTabSelected;
  final VoidCallback? onSearchActivated;
  final VoidCallback? onSearchDismissed;

  /// Live text of the native search field as the user types.
  final ValueChanged<String>? onSearchChanged;

  /// Rendered on non-iOS platforms, where the native bar is unavailable.
  final Widget? fallback;

  @override
  State<LiquidGlassBottomNav> createState() => _LiquidGlassBottomNavState();
}

class _LiquidGlassBottomNavState extends State<LiquidGlassBottomNav> {
  MethodChannel? _channel;
  bool _searchActive = false;

  static bool get _isIOS => !kIsWeb && Platform.isIOS;

  void _onPlatformViewCreated(int viewId) {
    _channel = MethodChannel('liquid_glass_bottom_nav_$viewId')
      ..setMethodCallHandler(_handleNativeCall);
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'tabSelected':
        final index = call.arguments as int?;
        if (index == null || index < 0 || index >= widget.items.length) {
          return;
        }
        if (_searchActive) {
          setState(() => _searchActive = false);
        }
        widget.onTabSelected?.call(index);
      case 'searchActivated':
        setState(() => _searchActive = true);
        widget.onSearchActivated?.call();
      case 'searchDismissed':
        if (_searchActive) {
          setState(() => _searchActive = false);
        }
        widget.onSearchDismissed?.call();
      case 'searchChanged':
        widget.onSearchChanged?.call(call.arguments as String? ?? '');
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isIOS) {
      return widget.fallback ?? const SizedBox.shrink();
    }

    return SizedBox(
      height: _searchActive
          ? MediaQuery.sizeOf(context).height
          : widget.collapsedHeight,
      child: UiKitView(
        viewType: 'liquid_glass_bottom_nav',
        creationParams: {
          'items': [for (final item in widget.items) item.toMap()],
          'selectedIndex': widget.selectedIndex,
          'showSearchTab': widget.showSearchTab,
          'searchPlaceholder': widget.searchPlaceholder,
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      ),
    );
  }
}

/// A single icon button rendered by a real `UIButton`.
///
/// On iOS 26+ this uses the system Liquid Glass button style
/// (`UIButton.Configuration.glass()` / `.prominentGlass()`) — the same
/// refractive, capsule-shaped material as [LiquidGlassBottomNav], rendered
/// entirely by UIKit. On iOS 16–25 there is no glass API, so it falls back
/// to a plain tinted capsule button rather than an approximation. On other
/// platforms it renders [fallback].
///
/// If [menuItems] is non-empty, tapping the button opens a real `UIMenu`
/// anchored to it instead of firing [onPressed] — on iOS 26 that menu is
/// presented in the same system Liquid Glass material, not a Flutter
/// popup styled to look native. [onMenuItemSelected] fires with the tapped
/// item's title; [selectedMenuItem] shows a checkmark next to the matching
/// item when the menu is built.
class LiquidGlassIconButton extends StatefulWidget {
  const LiquidGlassIconButton({
    required this.sfSymbol,
    this.prominent = false,
    this.size = 44,
    this.pointSize = 18,
    this.onPressed,
    this.menuItems,
    this.selectedMenuItem,
    this.onMenuItemSelected,
    this.fallback,
    super.key,
  });

  /// SF Symbol name rendered inside the button by iOS itself.
  final String sfSymbol;

  /// Uses `.prominentGlass()` (filled/tinted emphasis) instead of the
  /// regular `.glass()` style.
  final bool prominent;

  /// Side length of the square button.
  final double size;

  /// Point size of the SF Symbol glyph.
  final double pointSize;

  /// Fires on tap when [menuItems] is null or empty.
  final VoidCallback? onPressed;

  /// Titles for a native `UIMenu` anchored to the button. When non-empty,
  /// the button opens this menu on tap instead of calling [onPressed].
  final List<String>? menuItems;

  /// The item shown checked when the menu is built. Only read once, at
  /// native view creation — like the rest of this plugin's platform views,
  /// the menu is not rebuilt when Dart-side state changes.
  final String? selectedMenuItem;

  /// Fires with the tapped item's title.
  final ValueChanged<String>? onMenuItemSelected;

  /// Rendered on non-iOS platforms, where the native button is unavailable.
  final Widget? fallback;

  @override
  State<LiquidGlassIconButton> createState() => _LiquidGlassIconButtonState();
}

class _LiquidGlassIconButtonState extends State<LiquidGlassIconButton> {
  MethodChannel? _channel;

  static bool get _isIOS => !kIsWeb && Platform.isIOS;

  void _onPlatformViewCreated(int viewId) {
    _channel = MethodChannel('liquid_glass_icon_button_$viewId')
      ..setMethodCallHandler(_handleNativeCall);
  }

  Future<void> _handleNativeCall(MethodCall call) async {
    switch (call.method) {
      case 'tap':
        widget.onPressed?.call();
      case 'menuItemSelected':
        widget.onMenuItemSelected?.call(call.arguments as String? ?? '');
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isIOS) {
      return widget.fallback ?? const SizedBox.shrink();
    }

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: UiKitView(
        viewType: 'liquid_glass_icon_button',
        creationParams: {
          'sfSymbol': widget.sfSymbol,
          'prominent': widget.prominent,
          'pointSize': widget.pointSize,
          if (widget.menuItems case final items? when items.isNotEmpty) ...{
            'menuItems': items,
            'selectedMenuItem': ?widget.selectedMenuItem,
          },
        },
        creationParamsCodec: const StandardMessageCodec(),
        onPlatformViewCreated: _onPlatformViewCreated,
      ),
    );
  }
}
