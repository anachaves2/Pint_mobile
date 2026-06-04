import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/providers/badges_provider.dart';
import 'package:pint_mobile/utils/badge_utils.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:go_router/go_router.dart';

// ECRÃ BADGES EXPIRADOS
// Lista completa de badges expirados do consultor.
// Acessível pelo botão "VER TODOS" da secção Expirados do ecrã Os Meus Badges.

class BadgesExpirados extends ConsumerStatefulWidget {
  const BadgesExpirados({super.key});

  @override
  ConsumerState<BadgesExpirados> createState() => _BadgesExpiradosState();
}

class _BadgesExpiradosState extends ConsumerState<BadgesExpirados> {
  final TextEditingController _pesquisaController = TextEditingController();
  String _queryPesquisa = '';

  static const Color _azulPrimario = AppConstants.corPrimaria;
  static const Color _cinzaClaro = Color(0xFFF5F5F5);

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  List<BadgeUtilizador> _aplicarFiltro(List<BadgeUtilizador> todos) {
    // Só badges expirados, ordenados pelo mais recentemente expirado primeiro
    final expirados = todos.where((b) => b.jaExpirou).toList()
      ..sort((a, b) => b.dataExpiracao.compareTo(a.dataExpiracao));

    if (_queryPesquisa.isEmpty) return expirados;

    final q = _queryPesquisa.toLowerCase();
    return expirados
        .where((b) =>
            b.nomeBadge.toLowerCase().contains(q) ||
            (b.nomeNivel?.toLowerCase().contains(q) ?? false) ||
            (b.nomeArea?.toLowerCase().contains(q) ?? false) ||
            (b.nomeServiceLine?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final badgesAsync = ref.watch(badgesProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const CustomDrawer(),
      appBar: _buildAppBar(),
      body: badgesAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: _azulPrimario)),
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
                onPressed: () => ref.invalidate(badgesProvider),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (todos) {
          final badges = _aplicarFiltro(todos);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _buildBarraPesquisa(),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: _azulPrimario,
                  onRefresh: () => ref.read(badgesProvider.notifier).atualizar(),
                  child: badges.isEmpty
                      ? _buildEstadoVazio()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          itemCount: badges.length,
                          itemBuilder: (context, index) =>
                              _buildBadgeCard(badges[index]),
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

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
                  icon:
                      Icon(Icons.clear, size: 18, color: Colors.grey.shade400),
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

  Widget _buildEstadoVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_disabled_outlined,
              color: Colors.grey.shade300, size: 64),
          const SizedBox(height: 16),
          Text(
            _pesquisaController.text.isNotEmpty
                ? 'Nenhum badge encontrado'
                : 'Não tens badges expirados',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(BadgeUtilizador badge) {
    final cor = Colors.grey.shade400;
    return GestureDetector(
      onTap: () =>
          context.push(AppConstants.routeDetalheBadgeExpirado, extra: badge),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          // Fundo ligeiramente acinzentado para indicar que está inativo
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildIconeExpirado(badge),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.nomeBadge,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      // Texto acinzentado para badges expirados
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (badge.nomeNivel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      badge.nomeNivel!,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade400),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Conquistado: ${BadgeUtils.formatarData(badge.dataAtribuicao)}',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                  Text(
                    'Expirou: ${BadgeUtils.formatarData(badge.dataExpiracao)}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.red.shade300),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }

  // Ícone cinzento — todos os badges expirados ficam cinzentos
  // independentemente do nível original
  Widget _buildIconeExpirado(BadgeUtilizador badge) {
    final cor = Colors.grey.shade400;
    final letra = badge.idBadgeEspecial != null
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
          child: ColorFiltered(
            // Filtro a preto e branco para reforçar o estado expirado
            colorFilter: const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0,      0,      0,      1, 0,
            ]),
            child: Image.network(
              badge.urlImagem!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildIconeLetra(letra, cor),
            ),
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
              fontSize: letra == '★' ? 18 : 16),
        ),
      ),
    );
  }
}