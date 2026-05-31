import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pint_mobile/utils/constants.dart';

import 'package:pint_mobile/screens/auth/landing_page_screen.dart';
import 'package:pint_mobile/screens/auth/login_screen.dart';
import 'package:pint_mobile/screens/auth/recuperar_password_screen.dart';
import 'package:pint_mobile/screens/auth/redefinir_password1_screen.dart';
import 'package:pint_mobile/screens/auth/redefinir_password2_screen.dart';
import 'package:pint_mobile/screens/dashboard/dashboard_screen.dart';
import 'package:pint_mobile/screens/badges/meus_badges_screen.dart';
import 'package:pint_mobile/screens/badges/todos_badges_screen.dart';
import 'package:pint_mobile/screens/notificacoes/notificacoes_screen.dart';
import 'package:pint_mobile/screens/notificacoes/detalhe_notificacao_screen.dart';
import 'package:pint_mobile/screens/perfil/perfil_screen.dart';
import 'package:pint_mobile/screens/settings/definicoes_screen.dart';
import 'package:pint_mobile/screens/settings/alterar_password_screen.dart';
import 'package:pint_mobile/screens/candidaturas/candidaturas_screen.dart';
import 'package:pint_mobile/screens/candidaturas/candidaturas_decorrentes_screen.dart';
import 'package:pint_mobile/screens/candidaturas/historico_candidaturas_screen.dart';
import 'package:pint_mobile/screens/candidaturas/candidatura_submetida_screen.dart';
import 'package:pint_mobile/screens/candidaturas/detalhes_candidaturas_screen.dart';
import 'package:pint_mobile/screens/candidaturas/nova_candidatura_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppConstants.routeLanding,
  routes: [
    GoRoute(path: AppConstants.routeLanding, builder: (ctx, state) => const LandingPageScreen()),
    GoRoute(path: AppConstants.routeLogin, builder: (ctx, state) => const LoginScreen()),
    GoRoute(path: AppConstants.routeRecuperarPassword, builder: (ctx, state) => const RecuperarPasswordScreen()),
    GoRoute(path: AppConstants.routeRedefinirPassword1, builder: (ctx, state) => const RedefinirPassword1Screen()),
    GoRoute(path: AppConstants.routeRedefinirPassword2, builder: (ctx, state) => const RedefinirPassword2Screen()),
    GoRoute(path: AppConstants.routeDashboard, builder: (ctx, state) => const DashboardScreen()),
    GoRoute(path: AppConstants.routeMeusBadges, builder: (ctx, state) => const OsMeusBadges()),
    GoRoute(path: AppConstants.routeTodosBadges, builder: (ctx, state) => const TodosOsBadges()),
    GoRoute(path: AppConstants.routeBadgesEspeciais, builder: (ctx, state) => const PlaceholderScreen(titulo: 'Badges Especiais')),
    GoRoute(path: AppConstants.routeBadgesExpirados, builder: (ctx, state) => const PlaceholderScreen(titulo: 'Badges Expirados')),
    GoRoute(path: AppConstants.routeDetalheBadge, builder: (ctx, state) => const PlaceholderScreen(titulo: 'Detalhe do Badge')),
    GoRoute(path: AppConstants.routeCatalogo, builder: (ctx, state) => const PlaceholderScreen(titulo: 'Catálogo')),
    GoRoute(path: AppConstants.routeDetalheCatalogo, builder: (ctx, state) => const PlaceholderScreen(titulo: 'Detalhe do Badge')),
    GoRoute(path: AppConstants.routeObjetivos, builder: (ctx, state) => const PlaceholderScreen(titulo: 'Objetivos')),
    GoRoute(path: AppConstants.routeGamification, builder: (ctx, state) => const PlaceholderScreen(titulo: 'Gamification')),
    GoRoute(path: AppConstants.routeRanking, builder: (ctx, state) => const PlaceholderScreen(titulo: 'Ranking')),
    GoRoute(path: AppConstants.routeNotificacoes, builder: (ctx, state) => const NotificacoesScreen()),
    GoRoute(path: AppConstants.routeDetalheNotificacao, builder: (ctx, state) => const DetalheNotificacaoScreen()),
    GoRoute(path: AppConstants.routePerfil, builder: (ctx, state) => const Perfil()),
    GoRoute(path: AppConstants.routeDefinicoes, builder: (ctx, state) => const DefinicoesScreen()),
    GoRoute(path: AppConstants.routeAlterarPassword, builder: (ctx, state) => const AlterarPasswordScreen()),
    GoRoute(path: AppConstants.routeCandidaturasDecorrentes, builder: (ctx, state) => const CandidaturasADecorrer()),
    GoRoute(path: AppConstants.routeHistoricoCandidaturas, builder: (ctx, state) => const HistoricoCandidaturas()),
    GoRoute(path: AppConstants.routeCandidaturaSubmetida, builder: (ctx, state) => const CandidaturaSubmetida()),
    GoRoute(path: AppConstants.routeDetalheCandidatura, builder: (ctx, state) => const DetalhesCandidatura()),
    GoRoute(path: AppConstants.routeCandidaturas, builder: (ctx, state) => const Candidaturas()),
    GoRoute(path: AppConstants.routeNovaCandidatura, builder: (ctx, state) => const NovaCandidatura()),  
  ],
);



// ECRAS PRIVISÓRIOS


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
            Text(titulo, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConstants.corPrimaria)),
            const SizedBox(height: 8),
            const Text('Ecrã em construção', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}