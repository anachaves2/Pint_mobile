import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pint_mobile/models/ranking_entrada.dart';
import 'package:pint_mobile/providers/ranking_provider.dart';
import 'package:pint_mobile/providers/utilizador_provider.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:pint_mobile/widgets/podio_ranking.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';

/// Ecrãs 44 e 46 do protótipo (Gamification / GamificationPerfil).
///
/// Estrutura igual à da web (consultor/Gamification.jsx): pódio com o top 3,
/// cartão com o desempenho do próprio, e atalho para o ranking completo.
class GamificationScreen extends ConsumerWidget {
  const GamificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(rankingProvider);
    final utilizador = ref.watch(utilizadorProvider).valueOrNull;

    return Scaffold(
      backgroundColor: D.fundo,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: SvgPicture.asset('assets/icons/drawerprimario.svg',
                height: 20,
                colorFilter: const ColorFilter.mode(
                    AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: Text(ref.t('mobile_dash_gamification_titulo'), style: D.tituloPagina),
        actions: [
          IconButton(
            icon: SvgPicture.asset('assets/icons/notificacoesprimaria.svg',
                height: 24,
                colorFilter: const ColorFilter.mode(
                    AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => context.push(AppConstants.routeNotificacoes),
          ),
        ],
      ),
      body: estado.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppConstants.corPrimaria)),
        error: (err, _) => _SemLigacao(
          aoTentar: () => ref.read(rankingProvider.notifier).atualizar(),
        ),
        data: (ranking) {
          if (ranking.isEmpty) {
            return const _Vazio();
          }

          final meu = _meuLugar(ranking, utilizador?.id);
          final top3 = ranking.take(3).toList();

          return RefreshIndicator(
            color: AppConstants.corPrimaria,
            onRefresh: () => ref.read(rankingProvider.notifier).atualizar(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(D.e4, D.e2, D.e4, D.e6),
              children: [
                // ── Pódio ──
                const Text('TOP 3', style: D.etiqueta),
                const SizedBox(height: D.e2),
                PodioRanking(
                  entradas: top3
                      .map((r) => PodioEntrada(
                            posicao: r.posicao,
                            nome: r.nome,
                            pontos: r.totalPontos,
                            urlFoto: AppConstants.resolverUrlFicheiro(r.urlFoto),
                            destacado: r.idUtilizador == utilizador?.id,
                          ))
                      .toList(),
                ),

                const SizedBox(height: D.e6),

                // ── O meu desempenho ──
                if (meu != null) ...[
                  Text(ref.t('mobile_gamif_meu_desempenho'), style: D.etiqueta),
                  const SizedBox(height: D.e2),
                  _CardDesempenho(entrada: meu, totalConsultores: ranking.length),
                  const SizedBox(height: D.e5),
                ],

                // ── Atalho para o ranking completo ──
                CardSimples(
                  onTap: () => context.push(AppConstants.routeRanking),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: D.azul100,
                          borderRadius: BorderRadius.circular(D.rSm),
                        ),
                        child: const Icon(Icons.leaderboard_outlined,
                            size: 20, color: D.azul600),
                      ),
                      const SizedBox(width: D.e3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(ref.t('mobile_gamif_ranking_completo'),
                                style: D.tituloCard),
                            const SizedBox(height: 2),
                            Text('${ranking.length} ${ref.t('mobile_gamif_consultores')}',
                                style: D.legenda),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: D.tinta30),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  RankingEntrada? _meuLugar(List<RankingEntrada> ranking, int? idUtilizador) {
    if (idUtilizador == null) return null;
    for (final r in ranking) {
      if (r.idUtilizador == idUtilizador) return r;
    }
    return null;
  }
}

// ─────────────────────────────────────────────────────────
// Cartão do desempenho do próprio
// ─────────────────────────────────────────────────────────

class _CardDesempenho extends ConsumerWidget {
  const _CardDesempenho(
      {required this.entrada, required this.totalConsultores});

  final RankingEntrada entrada;
  final int totalConsultores;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CardGradiente(
      padding: const EdgeInsets.all(D.e5),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _Metrica(
                valor: '${entrada.posicao}º',
                rotulo: ref.t('mobile_gamif_posicao'),
                sufixo: '${ref.t('mobile_gamif_de')} $totalConsultores',
              ),
              Container(width: 1, height: 44, color: D.azul100),
              _Metrica(
                valor: '${entrada.totalPontos}',
                rotulo: ref.t('mobile_ranking_pontos_maiusc'),
              ),
              Container(width: 1, height: 44, color: D.azul100),
              _Evolucao(entrada: entrada),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metrica extends StatelessWidget {
  const _Metrica({required this.valor, required this.rotulo, this.sufixo});

  final String valor;
  final String rotulo;
  final String? sufixo;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(valor,
            style: const TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: D.azul600)),
        const SizedBox(height: D.e1),
        Text(rotulo, style: D.etiqueta),
        if (sufixo != null) ...[
          const SizedBox(height: 2),
          Text(sufixo!, style: D.legenda.copyWith(fontSize: 11)),
        ],
      ],
    );
  }
}

/// Evolução face a há 7 dias — vem calculada do backend.
class _Evolucao extends ConsumerWidget {
  const _Evolucao({required this.entrada});

  final RankingEntrada entrada;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icone, cor, texto) = switch (entrada) {
      _ when entrada.subiu => (
          Icons.arrow_upward,
          D.ok,
          '+${entrada.evolucao}'
        ),
      _ when entrada.desceu => (
          Icons.arrow_downward,
          D.erro,
          '${entrada.evolucao}'
        ),
      _ => (Icons.remove, D.tinta30, '—'),
    };

    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 18, color: cor),
            const SizedBox(width: 2),
            Text(texto,
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold, color: cor)),
          ],
        ),
        const SizedBox(height: D.e1),
        Text(ref.t('mobile_gamif_7_dias'), style: D.etiqueta),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Estados
// ─────────────────────────────────────────────────────────

class _Vazio extends ConsumerWidget {
  const _Vazio();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(D.e6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.emoji_events_outlined, size: 44, color: D.tinta30),
          const SizedBox(height: D.e4),
          Text(ref.t('mobile_gamif_ranking_vazio'),
              style: D.tituloCard, textAlign: TextAlign.center),
          const SizedBox(height: D.e2),
          Text(ref.t('mobile_gamif_ranking_vazio_texto'),
              style: D.legenda, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

/// O ranking vem sempre da API — não há cópia local para mostrar offline.
class _SemLigacao extends ConsumerWidget {
  const _SemLigacao({required this.aoTentar});

  final VoidCallback aoTentar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(D.e6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 44, color: D.tinta30),
            const SizedBox(height: D.e4),
            Text(ref.t('mobile_gamif_sem_ligacao'),
                style: D.tituloCard, textAlign: TextAlign.center),
            const SizedBox(height: D.e2),
            Text(
                ref.t('mobile_gamif_sem_ligacao_texto'),
                style: D.legenda,
                textAlign: TextAlign.center),
            const SizedBox(height: D.e5),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: D.azul600,
                padding: const EdgeInsets.symmetric(
                    horizontal: D.e5, vertical: D.e3),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(D.rSm)),
              ),
              onPressed: aoTentar,
              child: Text(ref.t('mobile_geral_tentar_novamente')),
            ),
          ],
        ),
      ),
    );
  }
}