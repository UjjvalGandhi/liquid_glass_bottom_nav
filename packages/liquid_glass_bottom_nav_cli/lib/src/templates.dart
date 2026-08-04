/// The `lib/main.dart` written into a freshly created project.
///
/// Raw string on purpose: the template is Dart source of its own, full of `$`
/// interpolation that must survive into the generated file untouched.
String mainDartTemplate(String appName) =>
    _mainDart.replaceAll('__APP_NAME__', appName);

const _mainDart = r'''
import 'package:flutter/material.dart';
import 'package:liquid_glass_bottom_nav_native/liquid_glass_bottom_nav_native.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '__APP_NAME__',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final tab = _tabs[_selectedIndex];

    return Scaffold(
      // Both of these matter. `extendBody` lets the native bar float over your
      // content, and the bar itself belongs at the bottom of a full-screen
      // Stack. Without them iOS lays the bar out above the body instead.
      extendBody: true,
      appBar: AppBar(title: Text(tab.label)),
      body: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 140),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(tab.icon, size: 72),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty
                        ? tab.label
                        : 'Searching: $_searchQuery',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: LiquidGlassBottomNav(
              items: [
                for (final tab in _tabs)
                  LiquidGlassNavItem(title: tab.label, sfSymbol: tab.symbol),
              ],
              selectedIndex: _selectedIndex,
              onTabSelected: (index) => setState(() {
                _selectedIndex = index;
                _searchQuery = '';
              }),
              onSearchChanged: (query) => setState(() => _searchQuery = query),
              onSearchDismissed: () => setState(() => _searchQuery = ''),
              // Android, web and desktop have no native bar to host, so the
              // widget renders this instead.
              fallback: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) =>
                    setState(() => _selectedIndex = index),
                destinations: [
                  for (final tab in _tabs)
                    NavigationDestination(
                      icon: Icon(tab.icon),
                      label: tab.label,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// SF Symbols drive the native iOS bar; the Material icons are for the
/// fallback on every other platform.
const _tabs = <({String label, String symbol, IconData icon})>[
  (label: 'Home', symbol: 'house.fill', icon: Icons.home_rounded),
  (label: 'Setting', symbol: 'gearshape.fill', icon: Icons.settings_rounded),
  (label: 'Profile', symbol: 'person.fill', icon: Icons.person_rounded),
  (label: 'Reels', symbol: 'play.rectangle', icon: Icons.movie_rounded),
];
''';
