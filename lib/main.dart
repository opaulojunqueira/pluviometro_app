import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pluviometro_app/services/database_service.dart';
import 'package:pluviometro_app/services/preferences_service.dart';
import 'package:pluviometro_app/theme/app_theme.dart';
import 'package:pluviometro_app/features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  await DatabaseService.instance.database;
  await PreferencesService.instance.init();
  runApp(const PluviometroApp());
}

class PluviometroApp extends StatelessWidget {
  const PluviometroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pluviômetro Digital',
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
