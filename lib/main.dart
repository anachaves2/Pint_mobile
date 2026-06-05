import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ADICIONADO
import 'package:pint_mobile/routes/app_routes.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/services/notificacoes_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/widgets/banner_sem_rede.dart';
import 'package:pint_mobile/services/preferencias_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
    await NotificacoesService.instance.inicializar();
  } catch (e) {
    debugPrint('Erro ao inicializar Firebase ou Notificações: $e');
  }

  await DatabaseService.instance.database;


  final prefs = PreferenciasService();
  final tokenPrefs = await prefs.lerToken();
  final token = tokenPrefs ?? await DatabaseService.instance.getToken();

  if (token != null) {
    APIService.instance.sincronizarTodos();
    APIService.instance.iniciarSincronizacaoPeriodica(
      const Duration(minutes: AppConstants.intervalSincronizacaoMinutos),
    );
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'BadgeBoost',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
      //BannerSemRede envolve toda a app
      builder:(context, child) => BannerSemRede(child: child!),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.corPrimaria,
          primary: AppConstants.corPrimaria,
          secondary: AppConstants.corSecundaria,
          surface: Colors.white,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppConstants.corPrimaria),
          headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppConstants.corPrimaria),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.corPrimaria,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.corPrimaria,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppConstants.corPrimaria, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}