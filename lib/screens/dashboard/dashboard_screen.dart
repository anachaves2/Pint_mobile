import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/models/badge_regular.dart';
import 'package:pint_mobile/models/notificacao.dart';
import 'package:pint_mobile/providers/utilizador_provider.dart';
import 'package:pint_mobile/providers/badges_provider.dart';
import 'package:pint_mobile/providers/candidatura_provider.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  List<BadgeRegular> _catalogoBadges = [];
  List<Notificacao> _notificacoes = [];
  String _pesquisa = '';
  StreamSubscription? _subDados;

  @override
  void initState() {
    super.initState();
    _carregarExtras();
    _subDados = atualizadorDados.stream.listen((_) {
      ref.invalidate(utilizadorProvider);
      ref.invalidate(badgesProvider);
      ref.invalidate(candidaturasProvider);
      _carregarExtras();
    });
  }

  @override
  void dispose() {
    _subDados?.cancel();
    super.dispose();
  }

  // Carrega dados que ainda não têm provider próprio (catálogo e notificações)
  Future<void> _carregarExtras() async {
    APIService.instance.sincronizarTodos();
    final catalogo = await DatabaseService.instance.getCatalogoBadges();
    final notificacoes = await DatabaseService.instance.getNotificacoes();
    if (mounted) {
      setState(() {
        _catalogoBadges = catalogo;
        _notificacoes = notificacoes;
      });
    }
  }

  int get _notificacoesNaoLidas => _notificacoes.where((n) => !n.lida).length;

  @override
  Widget build(BuildContext context) {
    // ─── Riverpod — Aula 10 ───────────────────────────────
    final consultorAsync = ref.watch(utilizadorProvider);
    final badgesAsync = ref.watch(badgesProvider);
    final candidaturasAsync = ref.watch(candidaturasProvider);

    // Enquanto qualquer um dos providers estiver a carregar, mostra spinner
    final isLoading = consultorAsync.isLoading ||
        badgesAsync.isLoading ||
        candidaturasAsync.isLoading;

    final consultor = consultorAsync.value;
    final badges = badgesAsync.value ?? [];
    final candidaturas = candidaturasAsync.value ?? [];

    final totalBadges = badges.where((b) => b.valido).length;
    final totalEspeciais = badges.where((b) => b.idBadgeEspecial != null && b.valido).length;
    final totalPontos = badges.fold(0, (sum, b) => sum + (b.pontos ?? 0));

    final idsConquistados = badges
        .where((b) => b.idBadgeRegular != null)
        .map((b) => b.idBadgeRegular!)
        .toSet();
    final badgesRecomendados = _catalogoBadges
        .where((b) => !idsConquistados.contains(b.id))
        .where((b) => _pesquisa.isEmpty ||
            b.nome.toLowerCase().contains(_pesquisa.toLowerCase()))
        .take(3)
        .toList();

    final totalBadgesLp = _catalogoBadges.length;
    final conquistadosLp = badges.where((b) => b.valido).length;
    final progressoLp = totalBadgesLp > 0 ? conquistadosLp / totalBadgesLp : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: SvgPicture.asset(
              'assets/icons/drawerprimario.svg',
              height: 20,
              colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'Dashboard',
          style: TextStyle(color: AppConstants.corPrimaria, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/notificacoesprimaria.svg',
                  height: 24,
                  colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn),
                ),
                onPressed: () => context.push(AppConstants.routeNotificacoes),
              ),
              if (_notificacoesNaoLidas > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: AppConstants.corErro, shape: BoxShape.circle),
                    child: Text(
                      '$_notificacoesNaoLidas',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.corPrimaria))
          : RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(utilizadorProvider);
                ref.invalidate(badgesProvider);
                ref.invalidate(candidaturasProvider);
                await _carregarExtras();
              },
              color: AppConstants.corPrimaria,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── Barra de pesquisa ────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(24)),
                        child: TextField(
                          onChanged: (value) => setState(() => _pesquisa = value),
                          decoration: const InputDecoration(
                            hintText: 'Procurar...',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                            prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),

                    // ─── Ações Rápidas ────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AÇÕES RÁPIDAS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildAcaoRapida(context, icon: Icons.military_tech, label: 'BADGES', valor: '$totalBadges', rota: AppConstants.routeMeusBadges),
                              _buildAcaoRapida(context, icon: Icons.star, label: 'ESPECIAIS', valor: '$totalEspeciais', rota: AppConstants.routeBadgesEspeciais),
                              _buildAcaoRapida(context, icon: Icons.description_outlined, label: 'PEDIDOS', valor: '${candidaturas.length}', rota: AppConstants.routeCandidaturas),
                              _buildAcaoRapida(context, icon: Icons.emoji_events_outlined, label: 'PONTOS', valor: '$totalPontos', rota: AppConstants.routeGamification),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // ─── Learning Path ────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        children: [
                          _buildProgressCard(
                            icon: Icons.school_outlined,
                            titulo: 'LEARNING PATH',
                            subtitulo: consultor?.nomeLearningPath ?? 'Sem learning path',
                            progresso: progressoLp.clamp(0.0, 1.0),
                            onTap: () => context.push(AppConstants.routeObjetivos),
                          ),
                          const SizedBox(height: 8),
                          _buildProgressCard(
                            icon: Icons.military_tech_outlined,
                            titulo: 'BADGES',
                            subtitulo: '$conquistadosLp de $totalBadgesLp conquistados',
                            progresso: progressoLp.clamp(0.0, 1.0),
                            onTap: () => context.push(AppConstants.routeMeusBadges),
                          ),
                          const SizedBox(height: 8),
                          _buildProgressCard(
                            icon: Icons.emoji_events_outlined,
                            titulo: 'RANKING GAMIFICATION',
                            subtitulo: consultor?.posicaoRanking != null
                                ? '${consultor!.posicaoRanking}º lugar · $totalPontos pts'
                                : '$totalPontos pontos acumulados',
                            progresso: 0.0,
                            onTap: () => context.push(AppConstants.routeRanking),
                          ),
                        ],
                      ),
                    ),

                    // ─── Badges Recomendados ──────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BADGES RECOMENDADOS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1)),
                          const SizedBox(height: 8),
                          ...badgesRecomendados.map((badge) => _buildBadgeRecomendadoItem(badge)),
                          if (badgesRecomendados.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(child: Text('Já conquistaste todos os badges!', style: TextStyle(color: Colors.grey))),
                            ),
                          const SizedBox(height: 8),
                          Center(
                            child: OutlinedButton(
                              onPressed: () => context.push(AppConstants.routeCatalogo),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppConstants.corPrimaria),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                              child: const Text('VER MAIS', style: TextStyle(color: AppConstants.corPrimaria, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAcaoRapida(BuildContext context, {required IconData icon, required String label, required String valor, required String rota}) {
    return GestureDetector(
      onTap: () => context.push(rota),
      child: Column(
        children: [
          Icon(icon, color: AppConstants.corPrimaria, size: 32),
          const SizedBox(height: 4),
          Text(valor, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildProgressCard({required IconData icon, required String titulo, required String subtitulo, required double progresso, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppConstants.corPrimaria.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: AppConstants.corPrimaria, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
                  const SizedBox(height: 2),
                  Text(subtitulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progresso,
                      backgroundColor: Colors.grey[200],
                      color: AppConstants.corSecundaria,
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgeRecomendadoItem(BadgeRegular badge) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.military_tech, color: Colors.orange, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text(badge.nomeNivel, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            children: [
              Text('${badge.pontos ?? 0}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.corPrimaria)),
              const Text('Requisitos', style: TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }
}