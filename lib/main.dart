import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_bottom_nav/liquid_glass_bottom_nav.dart';
import 'package:neopop/neopop.dart';

import 'login_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Native Liquid Glass Nav',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF5DD6C9),
          brightness: Brightness.light,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class NativeNavHomePage extends StatefulWidget {
  const NativeNavHomePage({super.key});

  @override
  State<NativeNavHomePage> createState() => _NativeNavHomePageState();
}

class _NativeNavHomePageState extends State<NativeNavHomePage> {
  int _selectedIndex = 0;
  String _title = 'Native Glass';
  bool _searchActive = false;
  String _searchQuery = '';

  static const _titleOptions = [
    'Native Glass',
    'Dashboard',
    'Crystal View',
    'Focus Mode',
  ];

  static const _homeReadMore = '''
Liquid Glass is Apple's name for the material language introduced across iOS, iPadOS, and macOS: a translucent, refractive surface that behaves less like a flat color and more like an actual physical substance sitting above your content. Unlike the frosted blur treatments of previous years, Liquid Glass reacts to what is happening underneath and around it. It bends light along its edges, it brightens and dims with the content passing beneath it, and it responds to touch with the kind of springy, tactile feedback that makes an interface feel like it has real, if impossible, physical properties. Building a tab bar out of this material is not a cosmetic choice. It changes the entire relationship between navigation chrome and content, because the chrome is no longer a static bar sitting on top of the app — it is a lens through which the app is seen.

This harness app exists to prove that relationship can be built honestly from Flutter. Rather than attempting to redraw Liquid Glass in Flutter's own rendering pipeline — an approach that would always be an approximation, forever a version behind whatever Apple ships next — the plugin embeds an actual `UITabBarController` inside a `UiKitView` and lets iOS render its own tab bar, using its own private APIs, with its own animation curves. Flutter's job is reduced to feeding it data and listening for events. Everything you see in the pill at the bottom of this screen, on a device or simulator running iOS 26, is genuine system UI: the same code path Apple's own apps use, not a Flutter widget doing its best impression.

That decision has consequences worth sitting with. The most immediate is architectural humility: a plugin that hosts native UI is fundamentally a bridge, not an implementation, and bridges are only as good as the seams where they meet. The known limitation documented elsewhere in this project — that `selectedIndex` is write-once, because there is no native handler wired up for Dart-to-Swift calls — is a direct product of that seam. It is not a bug so much as an honest description of how far the bridge currently reaches. Extending it means deciding, deliberately, what surface area to expose across the channel, and resisting the temptation to just expose everything because it is technically possible.

The second consequence is that fidelity is not something you can fake your way into. On iOS versions before 26, the same widget renders the classic flat tab bar rather than a degraded approximation of Liquid Glass, because there is no approximation worth shipping — there is only the real thing or an honest fallback. On Android, Windows, and Linux, the widget renders whatever `fallback` widget you hand it, or nothing at all. This is a deliberate refusal to paper over platform differences with a shared, mediocre widget that looks slightly wrong everywhere. Better to be visibly, admittedly absent on platforms where the native material does not exist than to be present everywhere in a form that undermines the reason the plugin exists.

There is also a quieter, more practical argument for going native, which is that system tab bars come with decades of accumulated behavior that nobody wants to reimplement. Safe area insets, dynamic type scaling, VoiceOver semantics, keyboard avoidance during search, the exact spring curve used when a tab bar item is tapped — all of it ships for free with `UITabBarController`, tuned by people who spend their careers on exactly this problem. A hand-rolled Flutter tab bar would need to rebuild every one of those behaviors from scratch, and would still, on close inspection, feel slightly off in ways that are hard to name and harder to fix. Native hosting sidesteps the whole category of bugs by not attempting to solve a problem that has already been solved upstream.

None of this is free, of course. Platform views carry real performance and complexity costs: they break Flutter's usual assumption that everything can be composited in a single Skia or Impeller pass, they interact awkwardly with certain transform and clipping operations, and they require careful lifecycle management to avoid leaking native view controllers when a Flutter widget tree is torn down and rebuilt. The `WindowAwareContainerView` in the Swift source, which waits for the container to actually be attached to a window before wiring the tab bar controller into the parent view controller hierarchy, exists specifically to avoid a class of crashes that only show up under certain navigation timing — the kind of bug that is invisible until it isn't, and then it's on every device at once.

The search experience layered on top of the tab bar is the clearest demonstration of why this approach pays for itself. The separated circular glass button that morphs into a full search field, the automatic tab restoration when search is cancelled, the integrated placement API that only exists from iOS 26 onward with a graceful `#available` fallback for everything before it — none of that is a small amount of interaction design, and all of it comes from Apple's own `UISearchController` and `UITab` APIs rather than from code written for this project. Flutter's role is just to grow the platform view to fill the screen when search activates, so the expanding native field and keyboard have room to breathe, and to shrink it back down when the user is done. It is a small, almost invisible piece of choreography that only works because the two sides trust each other to do their part.

What ties all of this together is a fairly unfashionable idea: that the best way to make a cross-platform app feel native on a given platform is, sometimes, to stop pretending it's cross-platform at the point where it counts. Flutter is extraordinarily good at building one shared implementation across many platforms, and most of an app should live there — business logic, state management, most of the visual language. But for the handful of surfaces where "looks native" and "is native" are meaningfully different things to a user, and where the platform vendor is actively investing in new material and motion language every year, hosting the real component is not a compromise. It's the only version of the feature that will still be correct next year, without this codebase having to chase Apple's next redesign at all.
''';

  List<_TabContent> get _pages => [
    const _TabContent(
      icon: Icons.home_rounded,
      title: 'Home',
      subtitle: 'Flutter content with a native iOS tab bar underneath.',
      accentColor: Color(0xFF5DD6C9),
      bodyText: _homeReadMore,
    ),
    _TabContent(
      icon: Icons.settings_rounded,
      title: 'Setting',
      subtitle: 'The selected tab is reported from native Swift code.',
      accentColor: const Color(0xFFFFB020),
      onLogout: _logout,
    ),
    const _TabContent(
      icon: Icons.person_rounded,
      title: 'Profile',
      subtitle: 'On iOS 26, the native bar uses Apple system styling.',
      accentColor: Color(0xFFFF6B6B),
    ),
    const _TabContent(
      icon: Icons.movie_creation_rounded,
      title: 'Reels',
      subtitle: 'Short-form video space with the same native navigation.',
      accentColor: Color(0xFF8C7BFF),
    ),
  ];

  void _logout() {
    Navigator.of(
      context,
    ).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Text(_title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: LiquidGlassIconButton(
              key: const ValueKey('title-menu-trigger'),
              sfSymbol: 'slider.horizontal.3',
              menuItems: _titleOptions,
              selectedMenuItem: _title,
              onMenuItemSelected: (title) {
                setState(() => _title = title);
              },
              fallback: PopupMenuButton<String>(
                icon: const Icon(Icons.tune_rounded),
                initialValue: _title,
                onSelected: (title) {
                  setState(() => _title = title);
                },
                itemBuilder: (context) => [
                  for (final option in _titleOptions)
                    PopupMenuItem(
                      value: option,
                      child: Row(
                        children: [
                          if (option == _title)
                            const Icon(Icons.check_rounded, size: 18)
                          else
                            const SizedBox(width: 18),
                          const SizedBox(width: 8),
                          Text(option),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: ColoredBox(
        color: Colors.white,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 152),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              constraints.maxHeight - 24 - 152,
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _pages[_selectedIndex],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_searchActive && _searchQuery.isNotEmpty)
                Positioned(
                  top: 24,
                  left: 24,
                  right: 24,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: Text(
                          'Searching: $_searchQuery',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.bottomCenter,
                child: LiquidGlassBottomNav(
                  collapsedHeight: 112,
                  items: const [
                    LiquidGlassNavItem(title: 'Home', sfSymbol: 'house.fill'),
                    LiquidGlassNavItem(title: 'Setting', sfSymbol: 'gearshape.fill'),
                    LiquidGlassNavItem(title: 'Profile', sfSymbol: 'person.fill'),
                    LiquidGlassNavItem(title: 'Reels', sfSymbol: 'play.rectangle'),
                  ],

                  selectedIndex: _selectedIndex,
                  onTabSelected: (index) {
                    setState(() {
                      _selectedIndex = index;
                      _searchActive = false;
                      _searchQuery = '';
                    });
                  },
                  onSearchActivated: () {      // icons asres ssnot proper ssshssowss in conatainer check it dpdldease
                    setState(() {
                      _searchActive = true;
                    });
                  },
                  onSearchDismissed: () {
                    setState(() {
                      _searchActive = false;
                      _searchQuery = '';
                    });
                  },
                  onSearchChanged: (query) {
                    setState(() => _searchQuery = query);
                  },
                  fallback: _MaterialBottomNav(
                    selectedIndex: _selectedIndex,
                    onSelected: (index) {
                      setState(() => _selectedIndex = index);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaterialBottomNav extends StatelessWidget {
  const _MaterialBottomNav({
    required this.selectedIndex,
    required this.onSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings_rounded),
          label: 'Setting',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
        NavigationDestination(
          icon: Icon(Icons.movie_creation_outlined),
          selectedIcon: Icon(Icons.movie_creation_rounded),
          label: 'Reels',
        ),
      ],
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    this.onLogout,
    this.bodyText,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback? onLogout;
  final String? bodyText;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey(title),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Non-interactive NeoPop tile: the 3D block look comes from the
        // derived bottom/right shadow faces, not from borders or blur.
        NeoPopButton(
          color: accentColor,
          depth: 6,
          border: Border.all(color: Colors.black, width: 1.4),
          bottomShadowColor: Colors.black,
          rightShadowColor: Colors.black,
          onTapUp: () {},
          onTapDown: () {},
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Icon(icon, size: 48, color: Colors.black),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: Colors.black54),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 26),
        NeoPopButton(
          color: Colors.black,
          depth: 8,
          bottomShadowColor: accentColor,
          rightShadowColor: accentColor,
          animationDuration: const Duration(milliseconds: 50),
          onTapUp: () {
            // HapticFeedback.lightImpact();
            // ScaffoldMessenger.of(context)
            //   ..hideCurrentSnackBar()
            //   ..showSnackBar(
            //     SnackBar(
            //       behavior: SnackBarBehavior.floating,
            //       content: Text('Selected tab: $title'),
            //     ),
            //   );
          },
          onTapDown: () => HapticFeedback.lightImpact(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: Text(
              'Selected tab: $title',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (onLogout != null) ...[
          const SizedBox(height: 16),
          NeoPopButton(
            color: Colors.white,
            depth: 6,
            border: Border.all(color: Colors.black, width: 1.4),
            bottomShadowColor: const Color(0xFFE0334F),
            rightShadowColor: const Color(0xFFE0334F),
            animationDuration: const Duration(milliseconds: 50),
            onTapDown: () => HapticFeedback.lightImpact(),
            onTapUp: onLogout,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: 16,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: Color(0xFFE0334F),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Log out',
                    style: TextStyle(
                      color: Color(0xFFE0334F),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (bodyText != null) ...[
          const SizedBox(height: 32),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Read more',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final paragraph in bodyText!
              .trim()
              .split('\n\n')
              .where((p) => p.trim().isNotEmpty))
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                paragraph.trim(),
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            ),
        ],
      ],
    );
  }
}
