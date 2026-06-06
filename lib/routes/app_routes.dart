import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/models/notificacao.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:pint_mobile/screens/auth/landing_page_screen.dart';
import 'package:pint_mobile/screens/auth/login_screen.dart';
import 'package:pint_mobile/screens/auth/recuperar_password_screen.dart';
import 'package:pint_mobile/screens/auth/redefinir_password1_screen.dart';
import 'package:pint_mobile/screens/auth/redefinir_password2_screen.dart';
import 'package:pint_mobile/screens/auth/configuracao_inicial_screen.dart';
import 'package:pint_mobile/screens/dashboard/dashboard_screen.dart';
import 'package:pint_mobile/screens/badges/meus_badges_screen.dart';
import 'package:pint_mobile/screens/badges/todos_badges_screen.dart';
import 'package:pint_mobile/screens/badges/badges_especiais_screen.dart';
import 'package:pint_mobile/screens/badges/badges_expirados_screen.dart';
import 'package:pint_mobile/screens/badges/detalhe_badge_regular_screen.dart';
import 'package:pint_mobile/screens/badges/detalhe_badge_premium_screen.dart';
import 'package:pint_mobile/screens/badges/detalhe_badge_expirado_screen.dart';
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
  redirect: (context, state) async {
    //Só verifica nas rotas de auth (landing e login)
    final naAuth = state.matchedLocation == AppConstants.routeLanding ||
        state.matchedLocation == AppConstants.routeLogin;
    if (!naAuth) return null;    //noutras rotas não faz nada
    final token = await DatabaseService.instance.getToken();
    if (token != null) {
      return AppConstants.routeDashboard;  //se já tiver token, vai para dashboard
    } else {
      return null;  //senão, deixa ir para landing/login
    }
  },
  routes: [
    GoRoute(path: AppConstants.routeLanding, builder: (ctx, state) => const LandingPageScreen()),
    GoRoute(path: AppConstants.routeLogin, builder: (ctx, state) => const LoginScreen()),
    GoRoute(path: AppConstants.routeRecuperarPassword, builder: (ctx, state) => const RecuperarPasswordScreen()),
    GoRoute(path: AppConstants.routeRedefinirPassword1, builder: (ctx, state) => const RedefinirPassword1Screen()),
    GoRoute(path: AppConstants.routeRedefinirPassword2, builder: (ctx, state) => const RedefinirPassword2Screen()),
    GoRoute(path: AppConstants.routeConfiguracaoInicial, builder: (ctx, state) => const ConfiguracaoInicialScreen()),
    GoRoute(path: AppConstants.routeDashboard, builder: (ctx, state) => const DashboardScreen()),
    GoRoute(path: AppConstants.routeMeusBadges, builder: (ctx, state) => const OsMeusBadges()),
    GoRoute(path: AppConstants.routeTodosBadges, builder: (ctx, state) => const TodosOsBadges()),
    GoRoute(path: AppConstants.routeBadgesEspeciais, builder: (ctx, state) => const BadgesEspeciais()),
    GoRoute(path: AppConstants.routeBadgesExpirados, builder: (ctx, state) => const BadgesExpirados()),
    GoRoute(path: AppConstants.routeDetalheBadge, builder: (ctx, state) => DetalheBadgeRegular(badge: state.extra as BadgeUtilizador)),
    GoRoute(path: AppConstants.routeDetalheBadgePremium, builder: (ctx, state) => DetalheBadgePremium(badge: state.extra as BadgeUtilizador)),
    GoRoute(path: AppConstants.routeDetalheBadgeExpirado, builder: (ctx, state) => DetalheBadgeExpirado(badge: state.extra as BadgeUtilizador)),
    GoRoute(path: AppConstants.routeCatalogo, builder: (ctx, state) => const PlaceholderScreen(titulo: 'Catálogo')),
    GoRoute(path: AppConstants.routeDetalheCatalogo, builder: (ctx, state) => const PlaceholderScreen(titulo: 'Detalhe do Badge')),
    GoRoute(path: AppConstants.routeObjetivos, builder: (ctx, state) => const PlaceholderScreen(titulo: 'Objetivos')),
    GoRoute(path: AppConstants.routeGamification, builder: (ctx, state) => const PlaceholderScreen(titulo: 'Gamification')),
    GoRoute(path: AppConstants.routeRanking, builder: (ctx, state) => const PlaceholderScreen(titulo: 'Ranking')),
    GoRoute(path: AppConstants.routeNotificacoes, builder: (ctx, state) => const NotificacoesScreen()),
    GoRoute(path: AppConstants.routeDetalheNotificacao, builder: (ctx, state) => DetalheNotificacaoScreen(notificacao: state.extra as Notificacao)),
    GoRoute(path: AppConstants.routePerfil, builder: (ctx, state) => const Perfil()),
    GoRoute(path: AppConstants.routeDefinicoes, builder: (ctx, state) => const DefinicoesScreen()),
    GoRoute(path: AppConstants.routeAlterarPassword, builder: (ctx, state) => const AlterarPasswordScreen()),
    GoRoute(path: AppConstants.routeCandidaturasDecorrentes, builder: (ctx, state) => const CandidaturasADecorrer()),
    GoRoute(path: AppConstants.routeHistoricoCandidaturas, builder: (ctx, state) => const HistoricoCandidaturas()),
    GoRoute(path: AppConstants.routeCandidaturaSubmetida, builder: (ctx, state) => const CandidaturaSubmetida()),
    GoRoute(path: AppConstants.routeDetalheCandidatura, builder: (ctx, state) => DetalhesCandidatura(numCandidatura: state.extra as int)),
    GoRoute(path: AppConstants.routeCandidaturas, builder: (ctx, state) => const Candidaturas()),
    GoRoute(path: AppConstants.routeNovaCandidatura, builder: (ctx, state) => NovaCandidatura(rascunho: state.extra as Map<String, dynamic>?)),
  ],
);

// ECRAS PRIVISÓRIOS


class PlaceholderScreen extends StatelessWidget {
  final String titulo;
  const PlaceholderScreen({super.key, required this.titulo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const CustomDrawer(),
      appBar: AppBar(
        title: Text(titulo),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: SvgPicture.asset('assets/icons/drawerprimario.svg', height: 20,
                colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
      ),
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