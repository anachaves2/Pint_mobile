import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/providers/badges_provider.dart';
import 'package:pint_mobile/utils/badge_utils.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:go_router/go_router.dart';

// ECRÃ "VER TODOS" — BADGES REGULARES OBTIDOS
// Alvo do link "Ver Todos" da secção Recentes em Os Meus Badges — lista
// completa (sem limite de 3) dos badges regulares válidos que o consultor
// já tem. Não confundir com o Catálogo (todos_badges_screen.dart), que
// mostra os badges DISPONÍVEIS na plataforma, obtidos ou não.

class BadgesRegulares extends ConsumerStatefulWidget {
  const BadgesRegulares({super.key});

  @override
  ConsumerState<BadgesRegulares> createState() => _BadgesRegularesState();
}

class _BadgesRegularesState extends ConsumerState<BadgesRegulares> {
  final TextEditingController _pesquisaController = TextEditingController();
  String _queryPesquisa = '';

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  List<BadgeUtilizador> _aplicarFiltro(List<BadgeUtilizador> todos) {
    final regulares = todos
        .where((b) => b.idBadgeEspecial == null && b.valido)
        .toList()
      ..sort((a, b) => b.dataAtribuicao.compareTo(a.dataAtribuicao));

    if (_queryPesquisa.isEmpty) return regulares;
    final q = _queryPesquisa.toLowerCase();
    return regulares.where((b) {
      return b.nomeBadge.toLowerCase().contains(q) ||
          (b.nomeNivel?.toLowerCase().contains(q) ?? false) ||
          (b.nomeArea?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  Color _corIndicadorValidade(BadgeUtilizador b) {
    if (!b.valido) return D.erro;
    final horasRestantes = b.dataExpiracao.difference(DateTime.now()).inMinutes / 60;
    if (horasRestantes > 0 && horasRestantes <= 72) return D.aviso;
    return D.ok;
  }

  String _textoExpiracao(BadgeUtilizador b) {
    final diff = b.dataExpiracao.difference(DateTime.now());
    if (diff.isNegative) return b.valido ? 'Sem data de expiração' : 'Badge inválida';
    return 'Expira em: ${diff.inHours}h e ${diff.inMinutes % 60}min';
  }

  @override
  Widget build(BuildContext context) {
    final badgesAsync = ref.watch(badgesProvider);

    return Scaffold(
      backgroundColor: D.fundo,
      drawer: const CustomDrawer(),
      appBar: _buildAppBar(),
      body: badgesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: D.azul600)),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: D.tinta30, size: 64),
              const SizedBox(height: D.e4),
              const Text('Erro ao carregar badges', style: D.corpo),
            ],
          ),
        ),
        data: (todos) {
          final badges = _aplicarFiltro(todos);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(D.e4, D.e2, D.e4, D.e2),
                child: _buildBarraPesquisa(),
              ),
              Expanded(
                child: RefreshIndicator(
                  color: D.azul600,
                  onRefresh: () => ref.read(badgesProvider.notifier).atualizar(),
                  child: badges.isEmpty
                      ? Center(
                          child: Text(
                            _pesquisaController.text.isNotEmpty ? 'Nenhum badge encontrado' : 'Ainda não tens badges obtidos',
                            style: D.corpo,
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(D.e4, D.e1, D.e4, D.e4),
                          itemCount: badges.length,
                          itemBuilder: (context, index) => _buildBadgeCard(badges[index]),
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppConstants.corPrimaria, size: 20),
        onPressed: () => context.pop(),
      ),
      title: const Text('OS MEUS BADGES', style: D.tituloPagina),
      actions: [
        IconButton(
          icon: SvgPicture.asset(
            'assets/icons/notificacoesprimaria.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn),
          ),
          onPressed: () => context.push(AppConstants.routeNotificacoes),
        ),
      ],
    );
  }

  Widget _buildBarraPesquisa() {
    return Container(
      decoration: BoxDecoration(
        color: D.superficie,
        borderRadius: BorderRadius.circular(D.rMd),
        boxShadow: D.elev1,
      ),
      child: TextField(
        controller: _pesquisaController,
        onChanged: (texto) => setState(() => _queryPesquisa = texto),
        decoration: InputDecoration(
          hintText: 'Procura...',
          hintStyle: const TextStyle(color: D.tinta30, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: D.tinta30, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: D.e3),
          suffixIcon: _pesquisaController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: D.tinta30),
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

  Widget _buildBadgeCard(BadgeUtilizador badge) {
    return Padding(
      padding: const EdgeInsets.only(bottom: D.e2),
      child: CardSimples(
        onTap: () => context.push(AppConstants.routeDetalheBadge, extra: badge),
        child: Row(
          children: [
            _buildIconeBadge(badge),
            const SizedBox(width: D.e3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(badge.nomeBadge, style: D.tituloCard),
                  if (badge.nomeNivel != null) ...[
                    const SizedBox(height: 2),
                    Text(badge.nomeNivel!, style: D.legenda),
                  ],
                  const SizedBox(height: D.e2),
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(color: _corIndicadorValidade(badge), shape: BoxShape.circle),
                      ),
                      Expanded(
                        child: Text(_textoExpiracao(badge), style: D.legenda.copyWith(fontSize: 11), overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: D.tinta30, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildIconeBadge(BadgeUtilizador badge) {
    final cor = BadgeUtils.corDoNivel(badge.tipoNivel);
    final letra = badge.tipoNivel?.isNotEmpty == true ? badge.tipoNivel![0].toUpperCase() : '?';

    if (badge.urlImagem != null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: cor, width: 2)),
        child: ClipOval(
          child: Image.network(
            AppConstants.resolverUrlFicheiro(badge.urlImagem)!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildIconeLetra(letra, cor),
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
        child: Text(letra, style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}