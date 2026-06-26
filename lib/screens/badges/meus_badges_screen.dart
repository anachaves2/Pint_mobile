import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/providers/badges_provider.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/badge_utils.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:go_router/go_router.dart';

// ECRÃ OS MEUS BADGES

class OsMeusBadges extends ConsumerStatefulWidget {
  const OsMeusBadges({super.key});

  @override
  ConsumerState<OsMeusBadges> createState() => _OsMeusBadgesState();
}

class _OsMeusBadgesState extends ConsumerState<OsMeusBadges> {
  final TextEditingController _pesquisaController = TextEditingController();
  String _queryPesquisa = '';

  static const Color _azulPrimario = AppConstants.corPrimaria;
  static const Color _cinzaClaro = Color(0xFFF5F5F5);

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  // Filtra todos os badges com base no texto de pesquisa.
  List<BadgeUtilizador> _filtrar(List<BadgeUtilizador> lista) {
    if (_queryPesquisa.isEmpty) return lista;
    final q = _queryPesquisa.toLowerCase();
    return lista.where((b) {
      return b.nomeBadge.toLowerCase().contains(q) ||
          (b.nomeNivel?.toLowerCase().contains(q) ?? false) ||
          (b.nomeArea?.toLowerCase().contains(q) ?? false) ||
          (b.nomeServiceLine?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  // Getters que filtram a lista completa vinda do provider
  List<BadgeUtilizador> _badgesRecentes(List<BadgeUtilizador> todos) {
    final lista = todos
        .where((b) => b.valido && b.idBadgeEspecial == null)
        .toList()
      ..sort((a, b) => b.dataAtribuicao.compareTo(a.dataAtribuicao));
    return _filtrar(lista).take(3).toList();
  }

  List<BadgeUtilizador> _badgesEspeciais(List<BadgeUtilizador> todos) {
    final lista = todos
        .where((b) => b.idBadgeEspecial != null && b.valido)
        .toList()
      ..sort((a, b) => b.dataAtribuicao.compareTo(a.dataAtribuicao));
    return _filtrar(lista).take(3).toList();
  }

  List<BadgeUtilizador> _badgesExpirados(List<BadgeUtilizador> todos) {
    final lista = todos.where((b) => b.jaExpirou).toList()
      ..sort((a, b) => b.dataExpiracao.compareTo(a.dataExpiracao));
    return _filtrar(lista).take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    final badgesAsync = ref.watch(badgesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const CustomDrawer(),
      appBar: _buildAppBar(),
      body: badgesAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: _azulPrimario)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.grey.shade300, size: 64),
              const SizedBox(height: 16),
              Text('Erro ao carregar badges',
                  style: TextStyle(color: Colors.grey.shade400)),
              const SizedBox(height: 16),
              OutlinedButton(
                // Invalida o provider → build() corre novamente → relê do SQLite
                onPressed: () => ref.invalidate(badgesProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (todos) => RefreshIndicator(
          color: _azulPrimario,
          onRefresh: () => ref.read(badgesProvider.notifier).atualizar(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBarraPesquisa(),
                const SizedBox(height: 20),
                _buildSecao(
                  titulo: 'RECENTES',
                  badges: _badgesRecentes(todos),
                  rotaVerTodos: AppConstants.routeTodosBadges,
                ),
                const SizedBox(height: 24),
                _buildSecao(
                  titulo: 'ESPECIAIS',
                  badges: _badgesEspeciais(todos),
                  rotaVerTodos: AppConstants.routeBadgesEspeciais,
                ),
                const SizedBox(height: 24),
                _buildSecao(
                  titulo: 'EXPIRADOS',
                  badges: _badgesExpirados(todos),
                  rotaVerTodos: AppConstants.routeBadgesExpirados,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: SvgPicture.asset(
            'assets/icons/drawerprimario.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
                AppConstants.corPrimaria, BlendMode.srcIn),
          ),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: const Text(
        'BADGES',
        style: TextStyle(
          color: _azulPrimario,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 1.2,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: SvgPicture.asset(
            'assets/icons/notificacoesprimaria.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
                AppConstants.corPrimaria, BlendMode.srcIn),
          ),
          onPressed: () => context.push(AppConstants.routeNotificacoes),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
    );
  }

  // ─── Barra de pesquisa ────────────────────────────────────────────────────

  Widget _buildBarraPesquisa() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: _cinzaClaro,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _pesquisaController,
        onChanged: (texto) => setState(() => _queryPesquisa = texto),
        decoration: InputDecoration(
          hintText: 'Procura...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          suffixIcon: _pesquisaController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 18, color: Colors.grey.shade400),
                  onPressed: () {
                    _pesquisaController.clear();
                    setState(() => _queryPesquisa = '');
                  },
                )
              : null,
        ),
      ),
    );
  }

  // ─── Secção genérica ──────────────────────────────────────────────────────

  Widget _buildSecao({
    required String titulo,
    required List<BadgeUtilizador> badges,
    required String rotaVerTodos,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        if (badges.isEmpty)
          _buildEstadoVazio()
        else
          ...badges.map((badge) => _buildBadgeCard(badge)),
        const SizedBox(height: 8),
        Center(
          child: OutlinedButton(
            onPressed: () => context.push(rotaVerTodos),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            ),
            child: const Text(
              'VER TODOS',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoVazio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: _cinzaClaro,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(Icons.workspace_premium_outlined,
              color: Colors.grey.shade300, size: 36),
          const SizedBox(height: 8),
          Text(
            'Sem badges',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─── Card de badge ────────────────────────────────────────────────────────

  Widget _buildBadgeCard(BadgeUtilizador badge) {
    final bool eEspecial = badge.idBadgeEspecial != null;
    final bool eExpirado = badge.jaExpirou;

    return GestureDetector(
      onTap: () {
        if (eEspecial) {
          context.push(AppConstants.routeDetalheBadgePremium, extra: badge);
        } else if (eExpirado) {
          context.push(AppConstants.routeDetalheBadgeExpirado, extra: badge);
        } else {
          context.push(AppConstants.routeDetalheBadge, extra: badge);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildIconeBadge(badge, eEspecial, eExpirado),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.nomeBadge,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  if (badge.nomeNivel != null) ...[
                    const SizedBox(height: 2),
                    Text(badge.nomeNivel!,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500)),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Conquistado: ${BadgeUtils.formatarData(badge.dataAtribuicao)}',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  Text(
                    eExpirado
                        ? 'Expirou: ${BadgeUtils.formatarData(badge.dataExpiracao)}'
                        : 'Válido até: ${BadgeUtils.formatarData(badge.dataExpiracao)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: eExpirado
                          ? Colors.red.shade300
                          : badge.estaProximoDeExpirar
                              ? Colors.orange.shade400
                              : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildIconeBadge(BadgeUtilizador badge, bool eEspecial, bool eExpirado) {
    final Color cor;
    if (eExpirado) {
      cor = Colors.grey.shade400;
    } else if (eEspecial) {
      cor = const Color(0xFFF5A623);
    } else {
      cor = BadgeUtils.corDoNivel(badge.tipoNivel);
    }

    final letra = eEspecial
        ? '★'
        : (badge.tipoNivel?.isNotEmpty == true
            ? badge.tipoNivel![0].toUpperCase()
            : '?');

    if (badge.urlImagem != null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: cor, width: 2),
        ),
        child: ClipOval(
          child: Image.network(
            badge.urlImagem!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildIconeLetra(letra, cor),
          ),
        ),
      );
    }
    return _buildIconeLetra(letra, cor);
  }

  Widget _buildIconeLetra(String letra, Color cor) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cor.withValues(alpha: 0.15),
        border: Border.all(color: cor, width: 2),
      ),
      child: Center(
        child: Text(
          letra,
          style: TextStyle(
            color: cor,
            fontWeight: FontWeight.bold,
            fontSize: letra == '★' ? 18 : 16,
          ),
        ),
      ),
    );
  }
}