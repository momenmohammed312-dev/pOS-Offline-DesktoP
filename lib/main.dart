// ignore: depend_on_referenced_packages
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:desktop_window/desktop_window.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pos_offline_desktop/core/config/theme.dart';
import 'package:pos_offline_desktop/core/router/go_router.dart';
import 'package:pos_offline_desktop/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DesktopWindow.setMinWindowSize(const Size(800, 800));

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'POS System - Developed by MO2',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        AppLocalizations.delegate, // generated localizations
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.getLightTheme().copyWith(
        textTheme: AppTheme.getLightTheme().textTheme.apply(
          fontFamily: 'Arabic',
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      darkTheme: AppTheme.getDarkTheme().copyWith(
        textTheme: AppTheme.getDarkTheme().textTheme.apply(
          fontFamily: 'Arabic',
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
      ),
      themeMode: ThemeMode.dark,
      supportedLocales: const [
        Locale('ar'), // Arabic
        Locale('en'), // English
      ],
      locale: const Locale('ar'), // Set Arabic as default
      routerConfig: ref.watch(routerProvider),
    );
  }
}
