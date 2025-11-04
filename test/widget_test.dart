import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:kskfinance/main.dart';

void main() {
  testWidgets('App launches correctly', (WidgetTester tester) async {
    // Initialize EasyLocalization for testing
    await EasyLocalization.ensureInitialized();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ta')],
        path: 'assets/translations',
        fallbackLocale: const Locale('en'),
        child: ProviderScope(
          child: const MyApp(isFirstLaunch: true),
        ),
      ),
    );

    // Wait for animations and async operations
    await tester.pumpAndSettle();

    // Verify that the app launches without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
