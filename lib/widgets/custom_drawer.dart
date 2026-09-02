import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pint_mobile/providers/utilizador_provider.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:pint_mobile/providers/badges_provider.dart';
import 'package:pint_mobile/providers/candidatura_provider.dart';
import 'package:pint_mobile/providers/objetivos_resumo_provider.dart';
import 'package:pint_mobile/providers/badges_recomendados_provider.dart';
import 'package:pint_mobile/widgets/saudacao_evento.dart';
import 'package:pint_mobile/widgets/celebracao_marco.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';

// ConsumerWidget: padrão do Riverpod 
class CustomDrawer extends ConsumerWidget {
  const CustomDrawer({super.key});

  // Item de menu reutilizável — navega para a rota ou executa uma acção personalizada
  Widget _buildMenuItem(BuildContext context, String title, String routeName, {VoidCallback? onTapOverride}) {
    return Column(
      children: [
        ListTile(
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color.fromARGB(255, 32, 32, 32),
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            size: 20,
            color: Color.fromARGB(255, 32, 32, 32),
          ),
          onTap: onTapOverride ?? () {
            if (routeName.isNotEmpty) {
              context.go(routeName);
            }
          },
        ),
        const Divider(height: 1, color: Colors.black12),
      ],
    );
  }

  // Pede confirmação, limpa os 3 providers e faz logout
  Future<void> _terminarSessao(BuildContext context, WidgetRef ref) async {
    // ref.tr(...): estamos num callback (não no build), por isso lemos o
    // idioma uma vez em vez de o observar (ver TraducaoRef em idioma_provider.dart)
    final tituloSessao = ref.tr('mobile_geral_terminar_sessao');
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tituloSessao),
        content: Text(ref.tr('mobile_geral_terminar_sessao_confirmar')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ref.tr('mobile_geral_cancelar')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.corPrimaria,
            ),
            child: Text(tituloSessao, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      // Limpa o estado de todos os providers antes de navegar para o login
      ref.read(utilizadorProvider.notifier).limpar();
      ref.read(candidaturasProvider.notifier).limpar();
      ref.read(badgesProvider.notifier).limpar();
      ref.read(objetivosResumoProvider.notifier).limpar();
      ref.read(badgesRecomendadosProvider.notifier).limpar();
      SaudacaoEvento.limpar();
      CelebracaoMarco.limpar();
      await APIService.instance.logout();
      if (context.mounted) {
        context.go(AppConstants.routeLanding);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch: o drawer atualiza automaticamente quando o consultor muda
    final consultorAsync = ref.watch(utilizadorProvider);

    return Drawer(
      backgroundColor: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            // CABEÇALHO
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SvgPicture.asset(
                    'assets/icons/logo-softinsa.svg',
                    height: 45,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color.fromARGB(255, 0, 0, 0)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Colors.black12),

            // LISTA DE ITENS
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(context, ref.t('mobile_drawer_dashboard'), AppConstants.routeDashboard),
                  _buildMenuItem(context, ref.t('mobile_drawer_meus_badges'), AppConstants.routeMeusBadges),
                  _buildMenuItem(context, ref.t('mobile_drawer_catalogo'), AppConstants.routeCatalogo),
                  _buildMenuItem(context, ref.t('mobile_drawer_candidaturas'), AppConstants.routeCandidaturas),
                  _buildMenuItem(context, ref.t('mobile_drawer_objetivos'), AppConstants.routeObjetivos),
                  _buildMenuItem(context, ref.t('mobile_drawer_gamification'), AppConstants.routeGamification),
                  _buildMenuItem(context, ref.t('mobile_drawer_perfil'), AppConstants.routePerfil),
                  _buildMenuItem(context, ref.t('mobile_geral_terminar_sessao'), '', onTapOverride: () => _terminarSessao(context, ref)),
                ],
              ),
            ),
            
            // Mostra nome e email do consultor no fundo do drawer usando .when(data/loading/error)
            // INFO DO CONSULTOR NO FUNDO: usa .when() do Riverpod 
            const Divider(height: 1, color: Colors.black12),
            consultorAsync.when(
              data: (consultor) => consultor == null
                  ? const SizedBox.shrink()
                  : Container(
                      color: AppConstants.corPrimaria.withValues(alpha: 0.05),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Avatar com a inicial do nome do consultor
                          CircleAvatar(
                            backgroundColor: AppConstants.corPrimaria,
                            radius: 22,
                            child: Text(
                              consultor.nome.isNotEmpty
                                  ? consultor.nome[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  consultor.nome,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: AppConstants.corPrimaria,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  consultor.email,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
              loading: () => const LinearProgressIndicator(),
              error: (err, _) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}