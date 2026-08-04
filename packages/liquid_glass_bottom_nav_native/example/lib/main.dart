import 'package:flutter/material.dart';
import 'package:liquid_glass_bottom_nav_native/liquid_glass_bottom_nav_native.dart';

void main() {
  runApp(const ExampleApp());
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ExampleHomePage(),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({super.key});

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  int _selectedIndex = 0;
  String _searchQuery = '';

  static const _tabTitles = ['Home', 'Explore', 'Profile', 'Reels'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('Liquid Glass Bottom Nav')),
      body: Stack(
        children: [
          Center(
            child: Text(
              _searchQuery.isEmpty
                  ? 'Selected tab: ${_tabTitles[_selectedIndex]}'
                  : 'Searching: $_searchQuery',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: LiquidGlassBottomNav(
              items: const [
                LiquidGlassNavItem(title: 'Home', sfSymbol: 'house.fill'),
                LiquidGlassNavItem(title: 'Explore', sfSymbol: 'safari'),
                LiquidGlassNavItem(title: 'Profile', sfSymbol: 'person.fill'),
                LiquidGlassNavItem(
                  title: 'Reels',
                  sfSymbol: 'play.rectangle.fill',
                ),
              ],
              selectedIndex: _selectedIndex,
              onTabSelected: (index) => setState(() => _selectedIndex = index),
              onSearchChanged: (query) => setState(() => _searchQuery = query),
              onSearchDismissed: () => setState(() => _searchQuery = ''),
            ),
          ),
        ],
      ),
    );
  }
}
