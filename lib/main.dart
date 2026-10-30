import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/app_theme.dart';
import 'screens/home_screen.dart';

void main() => runApp(const ReBornApp());

class ReBornApp extends StatelessWidget {
  const ReBornApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'ReBorn AI',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    locale: const Locale('tr'),
    supportedLocales: const [Locale('tr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: const HomeScreen(),
  );
}
