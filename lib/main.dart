import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'models/consulta_service.dart';
import 'utils/settings_service.dart';
import 'utils/notification_service.dart';
import 'config/supabase_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.anonKey,
  );

  await ConsultaService().carregar();
  await SettingsService().carregar();

  if (!kIsWeb) {
    try {
      await NotificationService().inicializar();
    } catch (_) {}
  }

  runApp(const BemEstarApp());
}

class BemEstarApp extends StatelessWidget {
  const BemEstarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BemEstar',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
        Locale('en'),
      ],
      locale: const Locale('pt', 'BR'),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB8A88A),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF3EEE7),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
