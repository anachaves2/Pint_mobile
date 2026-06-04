import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/providers/badges_provider.dart';
import 'package:pint_mobile/utils/badge_utils.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:go_router/go_router.dart';

// ECRÃ BADGES ESPECIAIS
// Lista completa de badges especiais (Premium) válidos do consultor.
// Acessível pelo botão "VER TODOS" da secção Especiais do ecrã Os Meus Badges.

class BadgesEspeciais extends ConsumerStatefulWidget {
  const BadgesEspeciais({super.key});

  @override
  ConsumerState<BadgesEspeciais> createState() => _BadgesEspeciaisState();
}

class _BadgesEspeciaisState extends ConsumerState<BadgesEspeciais> {
  final TextEditingController _pesquisaController = TextEditingController();
  String _queryPesquisa = '';

  static const Color _azulPrimario = AppConstants.corPrimaria;
  static const Color _dourado = Color(0xFFF5A623);
  static const Color _cinzaClaro = Color(0xFFF5F5F5);

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  List<BadgeUtilizador> _aplicarFiltro(List<BadgeUtilizador> todos) {
    // Só badges especiais válidos, ordenados do mais recente para o mais antigo
    final especiais = todos
        .where((b) => b.idBadgeEspecial != null && b.valido)
        .toList()
      ..sort((a, b) => b.dataAtribuicao.compareTo(a.dataAtribuicao));

    if (_queryPesquisa.isEmpty) return especiais;

    final q = _queryPesquisa.toLowerCase();
    return especiais
        .where((b) => b.nomeBadge.toLowerCase().contains(q) ||
            (b.descricao?.toLowerCase().contains(q) ?? false))
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
          Icon(Icons.star_outline, color: Colors.grey.shade300, size: 64),
          const SizedBox(height: 16),
          Text(
            _pesquisaController.text.isNotEmpty
                ? 'Nenhum badge encontrado'
                : 'Ainda não tens badges especiais',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(BadgeUtilizador badge) {
    return GestureDetector(
      onTap: () =>
          context.push(AppConstants.routeDetalheBadgePremium, extra: badge),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          // Borda dourada para destacar os badges especiais
          border: Border.all(color: _dourado.withValues(alpha: 0.4)),
          boxShadow: [
            BoxShadow(
              color: _dourado.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildIconeEspecial(badge),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          badge.nomeBadge,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      // Etiqueta "Premium"
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _dourado.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _dourado.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          '★ Premium',
                          style: TextStyle(
                            fontSize: 10,
                            color: _dourado,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (badge.descricao != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      badge.descricao!,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Conquistado: ${BadgeUtils.formatarData(badge.dataAtribuicao)}',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  Text(
                    'Válido até: ${BadgeUtils.formatarData(badge.dataExpiracao)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: badge.estaProximoDeExpirar
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

  // Ícone dourado com estrela — identifica visualmente os badges especiais
  Widget _buildIconeEspecial(BadgeUtilizador badge) {
    if (badge.urlImagem != null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _dourado, width: 2),
        ),
        child: ClipOval(
          child: Image.network(
            badge.urlImagem!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildIconeLetra('★', _dourado),
          ),
        ),
      );
    }
    return _buildIconeLetra('★', _dourado);
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
              color: cor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}