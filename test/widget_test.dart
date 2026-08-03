import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:untitled/main.dart';

void main() {
  testWidgets('switches tabs from the bottom navigation bar', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Selected tab: Home'), findsOneWidget);
    expect(find.text('Selected tab: Explore'), findsNothing);

    await tester.tap(find.text('Explore').first);
    await tester.pumpAndSettle();

    expect(find.text('Selected tab: Explore'), findsOneWidget);

    await tester.tap(find.text('Profile').first);
    await tester.pumpAndSettle();

    expect(find.text('Selected tab: Profile'), findsOneWidget);

    await tester.tap(find.text('Reels').first);
    await tester.pumpAndSettle();

    expect(find.text('Selected tab: Reels'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Add'));
    await tester.pumpAndSettle();

    expect(find.text('Add tapped'), findsOneWidget);
  });

  testWidgets('selects a title from the top right glass menu', (tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Native Glass'), findsOneWidget);
    expect(find.text('Crystal View'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('title-menu-trigger')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Title options'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Crystal View'), findsOneWidget);
    expect(find.text('Focus Mode'), findsOneWidget);

    await tester.tap(find.text('Crystal View'));
    await tester.pumpAndSettle();

    expect(find.text('Crystal View'), findsOneWidget);
  });
}
