import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'state/app_state.dart';
import 'ui/screens/history_screen.dart';
import 'ui/screens/medicines_screen.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/screens/settings_screen.dart';
import 'ui/screens/today_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class MedApp extends StatefulWidget {
  const MedApp({super.key});

  @override
  State<MedApp> createState() => _MedAppState();
}

class _MedAppState extends State<MedApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Coming back to the app: the day may have changed, or a notification
  // button may have marked doses while the app was in the background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) context.read<AppState>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final language = state.settings.language;
    return MaterialApp(
      navigatorKey: navigatorKey,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      locale: language == 'system' ? null : Locale(language),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: state.settings.onboarded ? const HomeShell() : const OnboardingScreen(),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final base = ThemeData(
      colorSchemeSeed: const Color(0xFF00897B),
      brightness: brightness,
    );
    return base.copyWith(
      cardTheme: base.cardTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: base.chipTheme.copyWith(
        labelStyle: base.textTheme.bodyLarge,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      body: IndexedStack(
        index: _tab,
        children: const [TodayScreen(), MedicinesScreen(), HistoryScreen(), SettingsScreen()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.today_outlined), selectedIcon: const Icon(Icons.today), label: l.navToday),
          NavigationDestination(
            icon: const Icon(Icons.medication_outlined),
            selectedIcon: const Icon(Icons.medication),
            label: l.navMedicines,
          ),
          NavigationDestination(icon: const Icon(Icons.history), label: l.navHistory),
          NavigationDestination(icon: const Icon(Icons.settings_outlined), selectedIcon: const Icon(Icons.settings), label: l.navSettings),
        ],
      ),
    );
  }
}
