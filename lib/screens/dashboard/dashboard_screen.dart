import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/models/consultor.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/models/badge_regular.dart';
import 'package:pint_mobile/models/notificacao.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Dados carregados do SQLite
  Consultor? _consultor;
  List<BadgeUtilizador> _badges = [];
  List<BadgeRegular> _catalogoBadges = [];
  List<Notificacao> _notificacoes = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  // Carrega dados do SQLite (já sincronizados pelo main.dart)
  // e dispara nova sincronização em background
  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);

    // Sincroniza em background sem bloquear a UI
    APIService.instance.sincronizarTodos();

    // Lê do SQLite local
    final consultor = await DatabaseService.instance.getUser();
    final badges = await DatabaseService.instance.getBadges();
    final catalogo = await DatabaseService.instance.getCatalogoBadges();
    final notificacoes = await DatabaseService.instance.getNotificacoes();

    if (mounted) {
      setState(() {
        _consultor = consultor;
        _badges = badges;
        _catalogoBadges = catalogo;
        _notificacoes = notificacoes;
        _isLoading = false;
      });
    }
  }

  // Contadores para as Ações Rápidas
  int get _totalBadges => _badges.where((b) => b.valido).length;
  int get _totalEspeciais => _badges.where((b) => b.idBadgeEspecial != null && b.valido).length;
  int get _totalPontos => _badges.fold(0, (sum, b) => sum + (b.pontos ?? 0));
  int get _notificacoesNaoLidas => _notificacoes.where((n) => !n.lida).length;

  // Badges recomendados = do catálogo que ainda não tem
  List<BadgeRegular> get _badgesRecomendados {
    final idsConquistados = _badges
        .where((b) => b.idBadgeRegular != null)
        .map((b) => b.idBadgeRegular!)
        .toSet();
    return _catalogoBadges
        .where((b) => !idsConquistados.contains(b.id))
        .take(3)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const CustomDrawer(),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.corPrimaria))
          : RefreshIndicator(
              onRefresh: _carregarDados,
              color: AppConstants.corPrimaria,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchBar(),
                    _buildAcoesRapidas(),
                    _buildLearningPathSection(),
                    _buildGamificationSection(),
                    _buildBadgesRecomendados(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────
  AppBar _buildAppBar() {
    return AppBar(
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
      title: SvgPicture.asset('assets/icons/logo-softinsa.svg', height: 45),
      actions: [
        Stack(
          children: [
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/notificacoesprimaria.svg',
                height: 24,
                colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn),
              ),
              onPressed: () => Navigator.pushNamed(context, AppConstants.routeNotificacoes),
            ),
            if (_notificacoesNaoLidas > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppConstants.corErro,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$_notificacoesNaoLidas',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  // ─── Barra de pesquisa ────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(24),
        ),
        child: const TextField(
          decoration: InputDecoration(
            hintText: 'Procurar...',
            hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
            prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
    );
  }

  // ─── Ações Rápidas ────────────────────────────────────────
  Widget _buildAcoesRapidas() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AÇÕES RÁPIDAS',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAcaoRapida(
                icon: Icons.military_tech,
                label: 'BADGES',
                valor: '$_totalBadges',
                rota: AppConstants.routeMeusBadges,
              ),
              _buildAcaoRapida(
                icon: Icons.star,
                label: 'ESPECIAIS',
                valor: '$_totalEspeciais',
                rota: AppConstants.routeBadgesEspeciais,
              ),
              _buildAcaoRapida(
                icon: Icons.description_outlined,
                label: 'PEDIDOS',
                valor: '0',
                rota: AppConstants.routeCandidaturas,
              ),
              _buildAcaoRapida(
                icon: Icons.emoji_events_outlined,
                label: 'PONTOS',
                valor: '$_totalPontos',
                rota: AppConstants.routeGamification,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAcaoRapida({
    required IconData icon,
    required String label,
    required String valor,
    required String rota,
  }) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, rota),
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

  // ─── Learning Path ────────────────────────────────────────
  Widget _buildLearningPathSection() {
    final nomeLp = _consultor?.nomeLearningPath ?? 'Sem learning path';
    final totalBadgesLp = _catalogoBadges.length;
    final conquistadosLp = _badges.where((b) => b.valido).length;
    final progressoLp = totalBadgesLp > 0 ? conquistadosLp / totalBadgesLp : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          _buildProgressCard(
            icon: Icons.school_outlined,
            titulo: 'LEARNING PATH',
            subtitulo: nomeLp,
            progresso: progressoLp.clamp(0.0, 1.0),
            onTap: () => Navigator.pushNamed(context, AppConstants.routeObjetivos),
          ),
          const SizedBox(height: 8),
          _buildProgressCard(
            icon: Icons.military_tech_outlined,
            titulo: 'BADGES',
            subtitulo: '$conquistadosLp de $totalBadgesLp conquistados',
            progresso: progressoLp.clamp(0.0, 1.0),
            onTap: () => Navigator.pushNamed(context, AppConstants.routeMeusBadges),
          ),
          const SizedBox(height: 8),
          _buildProgressCard(
            icon: Icons.emoji_events_outlined,
            titulo: 'RANKING GAMIFICATION',
            subtitulo: _consultor?.posicaoRanking != null
                ? '${_consultor!.posicaoRanking}º lugar'
                : 'Sem dados',
            progresso: 0.6,
            onTap: () => Navigator.pushNamed(context, AppConstants.routeRanking),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard({
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required double progresso,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppConstants.corPrimaria.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
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

  // ─── Gamification ─────────────────────────────────────────
  Widget _buildGamificationSection() {
    // Top 3 badges por pontos (simulando ranking)
    final topBadges = List<BadgeUtilizador>.from(_badges)
      ..sort((a, b) => (b.pontos ?? 0).compareTo(a.pontos ?? 0));
    final top3 = topBadges.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'GAMIFICATION',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          ...List.generate(top3.length, (i) => _buildRankingItem(top3[i], i + 1)),
          if (top3.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Sem dados de gamification', style: TextStyle(color: Colors.grey))),
            ),
          const SizedBox(height: 8),
          Center(
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, AppConstants.routeRanking),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppConstants.corPrimaria),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('VER MAIS', style: TextStyle(color: AppConstants.corPrimaria, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankingItem(BadgeUtilizador badge, int posicao) {
    final cores = [Colors.amber, Colors.grey[400]!, Colors.brown[300]!];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[200],
            child: const Icon(Icons.person, color: Colors.grey, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(badge.nomeBadge ?? 'Badge', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                Text('${badge.pontos ?? 0} pontos', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          Text(
            '$posicaoº',
            style: TextStyle(fontWeight: FontWeight.bold, color: cores[posicao - 1], fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ─── Badges Recomendados ──────────────────────────────────
  Widget _buildBadgesRecomendados() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'BADGES RECOMENDADOS',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 8),
          ..._badgesRecomendados.map((badge) => _buildBadgeRecomendadoItem(badge)),
          if (_badgesRecomendados.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: Text('Já conquistaste todos os badges!', style: TextStyle(color: Colors.grey))),
            ),
          const SizedBox(height: 8),
          Center(
            child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, AppConstants.routeCatalogo),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppConstants.corPrimaria),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('VER MAIS', style: TextStyle(color: AppConstants.corPrimaria, fontSize: 12)),
            ),
          ),
        ],
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(8),
            ),
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
              Text(
                '${badge.pontos ?? 0}',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.corPrimaria),
              ),
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