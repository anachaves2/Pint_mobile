import 'package:flutter/material.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/utils/constants.dart';

// ─=============================================================
//imports dos Screens

//IR COLOCANDO OS IMPORTS A MEDIDA QUE FOREM SENDO FEITOS
//EXEMPLO:
// import 'package:pint_mobile/screens/auth/login_screen.dart';
// import 'package:pint_mobile/screens/auth/recuperar_password_screen.dart';
// import 'package:pint_mobile/screens/auth/redefinir_password1_screen.dart';
// import 'package:pint_mobile/screens/auth/redefinir_password2_screen.dart';
// import 'package:pint_mobile/screens/auth/configuracao_inicial_screen.dart';
// import 'package:pint_mobile/screens/dashboard/dashboard_screen.dart';
// import 'package:pint_mobile/screens/badges/meus_badges_screen.dart';
// import 'package:pint_mobile/screens/badges/todos_badges_screen.dart';
// import 'package:pint_mobile/screens/badges/badges_especiais_screen.dart';
// import 'package:pint_mobile/screens/badges/badges_expirados_screen.dart';
// import 'package:pint_mobile/screens/badges/detalhe_badge_screen.dart';
// import 'package:pint_mobile/screens/candidaturas/candidaturas_screen.dart';
// import 'package:pint_mobile/screens/candidaturas/detalhe_candidatura_screen.dart';
// import 'package:pint_mobile/screens/candidaturas/nova_candidatura_screen.dart';
// import 'package:pint_mobile/screens/catalogo/catalogo_screen.dart';
// import 'package:pint_mobile/screens/catalogo/detalhe_badge_catalogo_screen.dart';
// import 'package:pint_mobile/screens/objetivos/objetivos_screen.dart';
// import 'package:pint_mobile/screens/gamification/gamification_screen.dart';
// import 'package:pint_mobile/screens/gamification/ranking_screen.dart';
// import 'package:pint_mobile/screens/notificacoes/notificacoes_screen.dart';
// import 'package:pint_mobile/screens/settings/definicoes_screen.dart';

// ============================================================================
// MAIN -> Ponto de entrada da aplicação:

//   1. Inicializa o SQLite (base de dados local)
//   2. Verifica se o utilizador já está autenticado (token guardado):
//   Se sim -> sincroniza dados e vai para o Dashboard
//   Se não -> vai para o Login
//   3. Lança a app com o tema e a navegação definidos

void main() async {
  // antes de qualquer operação assíncrona (como abrir o SQLite)
  WidgetsFlutterBinding.ensureInitialized();
 
  // Inicializa o SQLite — cria as tabelas se for a primeira vez
  await DatabaseService.instance.database;
 
  // Verifica se há um token guardado (utilizador já fez login antes)
  final token = await DatabaseService.instance.getToken();
  final estaAutenticado = token != null;
 
  if (estaAutenticado) {
    // Sincroniza dados em background (sem await conforme slide das aulas)
    APIService.instance.sincronizarTodos();
 
    // Inicia sincronização periódica a cada 5 minutos
    APIService.instance.iniciarSincronizacaoPeriodica(
      const Duration(minutes: AppConstants.intervalSincronizacaoMinutos),
    );
  }
 
  runApp(MyApp(estaAutenticado: estaAutenticado));
}
 
//==============================================================
//RAIZ da app -> temas e navegaçao

// Recebe estaAutenticado para saber se vai para login ou para dashboard
class MyApp extends StatelessWidget {
  final bool estaAutenticado;
 
  const MyApp({super.key, required this.estaAutenticado});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BadgeBoost',
      debugShowCheckedModeBanner: false,
 
      //TEMA
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppConstants.corPrimaria,
          primary: AppConstants.corPrimaria,
          secondary: AppConstants.corSecundaria,
          surface: Colors.white,
        ),
        useMaterial3: true,
 
        // Tipografia
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppConstants.corPrimaria,
          ),
          headlineMedium: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppConstants.corPrimaria,
          ),
          bodyLarge: TextStyle(fontSize: 16, color: Colors.black87),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.black54),
        ),
 
        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.corPrimaria,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
 
        // Botões principais
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.corPrimaria,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
 
        // Campos de texto
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide:
                const BorderSide(color: AppConstants.corPrimaria, width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
 
 //===========================================================================================
      //ECRA INICIAL
      home: estaAutenticado
          ? const PlaceholderScreen(titulo: 'Dashboard') // → DashboardScreen()
          : const PlaceholderScreen(titulo: 'Login'),    // → LoginScreen()
 //============================================================================================
      //ROTAS
      routes: {
        // AUTH
        AppConstants.routeLogin: (ctx) =>
            const PlaceholderScreen(titulo: 'Login'),
        AppConstants.routeRecuperarPassword: (ctx) =>
            const PlaceholderScreen(titulo: 'Recuperar Password'),
        AppConstants.routeRedefinirPassword1: (ctx) =>
            const PlaceholderScreen(titulo: 'Verificar Código'),
        AppConstants.routeRedefinirPassword2: (ctx) =>
            const PlaceholderScreen(titulo: 'Nova Password'),
        AppConstants.routeConfiguracaoInicial: (ctx) =>
            const PlaceholderScreen(titulo: 'Configuração Inicial'),
 
        // DASHBOARD
        AppConstants.routeDashboard: (ctx) =>
            const PlaceholderScreen(titulo: 'Dashboard'),
 
        // BADGES
        AppConstants.routeMeusBadges: (ctx) =>
            const PlaceholderScreen(titulo: 'Os Meus Badges'),
        AppConstants.routeTodosBadges: (ctx) =>
            const PlaceholderScreen(titulo: 'Todos os Badges'),
        AppConstants.routeBadgesEspeciais: (ctx) =>
            const PlaceholderScreen(titulo: 'Badges Especiais'),
        AppConstants.routeBadgesExpirados: (ctx) =>
            const PlaceholderScreen(titulo: 'Badges Expirados'),
        // DetalheBadge recebe o idBadgeUtilizador como argumento:
        // Navigator.pushNamed(context, AppConstants.routeDetalheBadge, arguments: badge.id)
        AppConstants.routeDetalheBadge: (ctx) =>
            const PlaceholderScreen(titulo: 'Detalhe do Badge'),
 
        // CANDIDATURAS
        AppConstants.routeCandidaturas: (ctx) =>
            const PlaceholderScreen(titulo: 'Candidaturas'),
        // DetalheCandidatura recebe o numCandidatura como argumento
        AppConstants.routeDetalheCandidatura: (ctx) =>
            const PlaceholderScreen(titulo: 'Detalhe da Candidatura'),
        AppConstants.routeNovaCandidatura: (ctx) =>
            const PlaceholderScreen(titulo: 'Nova Candidatura'),
 
        // CATÁLOGO
        AppConstants.routeCatalogo: (ctx) =>
            const PlaceholderScreen(titulo: 'Catálogo'),
        // DetalheCatalogo recebe o idBadgeRegular como argumento
        AppConstants.routeDetalheCatalogo: (ctx) =>
            const PlaceholderScreen(titulo: 'Detalhe do Badge'),
 
        // OBJETIVOS
        AppConstants.routeObjetivos: (ctx) =>
            const PlaceholderScreen(titulo: 'Objetivos'),
 
        // GAMIFICATION
        AppConstants.routeGamification: (ctx) =>
            const PlaceholderScreen(titulo: 'Gamification'),
        AppConstants.routeRanking: (ctx) =>
            const PlaceholderScreen(titulo: 'Ranking'),
 
        // NOTIFICAÇÕES
        AppConstants.routeNotificacoes: (ctx) =>
            const PlaceholderScreen(titulo: 'Notificações'),
 
        // DEFINIÇÕES / PERFIL
        AppConstants.routeDefinicoes: (ctx) =>
            const PlaceholderScreen(titulo: 'Definições'),
      },
    );
  }
}
 
// ===========================================================================
// PlaceholderScreen — Ecrã temporário
//
// Substitui cada ecrã real à medida que é construído.
// Mostra o nome do ecrã para confirmar que a navegação funciona.

 
class PlaceholderScreen extends StatelessWidget {
  final String titulo;
 
  const PlaceholderScreen({super.key, required this.titulo});
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppConstants.corPrimaria,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ecrã em construção',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}