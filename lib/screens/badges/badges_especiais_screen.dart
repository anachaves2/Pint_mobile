import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/providers/badges_provider.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';
import 'package:pint_mobile/widgets/texto_traduzido.dart';
import 'package:go_router/go_router.dart';

// ECRÃ BADGES ESPECIAIS
// Lista completa de badges especiais válidos do consultor.
// Paridade com a web: indicador colorido de validade + contagem
// decrescente, iguais aos de "Os Meus Badges". Segue os tokens D e o
// CardSimples; o dourado (D.aviso) mantém-se como o acento próprio dos
// badges especiais, tal como na web.

class BadgesEspeciais extends ConsumerStatefulWidget {
  const BadgesEspeciais({super.key});

  @override
  ConsumerState<BadgesEspeciais> createState() => _BadgesEspeciaisState();
}

class _BadgesEspeciaisState extends ConsumerState<BadgesEspeciais> {
  final TextEditingController _pesquisaController = TextEditingController();
  String _queryPesquisa = '';

  @override
  void initState() {
    super.initState();
    // Mesma correção do ecrã "Os Meus Badges": sem isto, este ecrã só
    // mostrava o SQLite de uma sincronização anterior e só se atualizava
    // com um pull-to-refresh manual.
    ref.read(badgesProvider.notifier).atualizar();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  List<BadgeUtilizador> _aplicarFiltro(List<BadgeUtilizador> todos) {
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

  // ── Indicador de validade — igual ao corIndicadorValidade da web ──────────
  Color _corIndicadorValidade(BadgeUtilizador b) {
    if (!b.valido) return D.erro;
    final horasRestantes = b.dataExpiracao.difference(DateTime.now()).inMinutes / 60;
    if (horasRestantes > 0 && horasRestantes <= 72) return D.aviso;
    return D.ok;
  }

  String _textoExpiracao(BadgeUtilizador b) {
    final diff = b.dataExpiracao.difference(DateTime.now());
    if (diff.isNegative) return b.valido ? ref.t('mobile_badges_sem_data_expiracao') : ref.t('mobile_badges_invalida');
    final horas = diff.inHours;
    final minutos = diff.inMinutes % 60;
    return '${ref.t('mobile_badges_expira_em')} ${horas}h ${ref.t('mobile_badges_e')} ${minutos}min';
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
              Text(ref.t('mobile_badges_erro_carregar'), style: D.corpo),
              const SizedBox(height: D.e4),
              OutlinedButton(
                onPressed: () => ref.invalidate(badgesProvider),
                style: OutlinedButton.styleFrom(foregroundColor: D.azul600),
                child: Text(ref.t('mobile_geral_tentar_novamente')),
              ),
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
                      ? _buildEstadoVazio()
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
      title: Text(ref.t('mobile_badges_titulo'), style: D.tituloPagina),
      actions: [
        IconButton(
          icon: SvgPicture.asset(
            'assets/icons/notificacoesprimaria.svg',
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
          hintText: ref.t('mobile_geral_procura_hint'),
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

  Widget _buildEstadoVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.star_outline, color: D.tinta30, size: 64),
          const SizedBox(height: D.e4),
          Text(
            _pesquisaController.text.isNotEmpty
                ? ref.t('mobile_badges_nenhum_encontrado')
                : ref.t('mobile_badges_sem_especiais'),
            style: D.corpo,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(BadgeUtilizador badge) {
    return Padding(
      padding: const EdgeInsets.only(bottom: D.e2),
      child: CardSimples(
        onTap: () => context.push(AppConstants.routeDetalheBadgePremium, extra: badge),
        child: Row(
          children: [
            _buildIconeEspecial(badge),
            const SizedBox(width: D.e3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(badge.nomeBadge, style: D.tituloCard)),
                      ChipEstado(texto: '★ ${ref.t('mobile_badges_premium')}', cor: D.aviso, corFundo: D.avisoBg),
                    ],
                  ),
                  if (badge.descricao != null) ...[
                    const SizedBox(height: 2),
                    TextoTraduzido(texto: badge.descricao, style: D.legenda, maxLines: 1, overflow: TextOverflow.ellipsis),
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
                        child: Text(
                          _textoExpiracao(badge),
                          style: D.legenda.copyWith(fontSize: 11),
                          overflow: TextOverflow.ellipsis,
                        ),
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

  Widget _buildIconeEspecial(BadgeUtilizador badge) {
    if (badge.urlImagem != null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: D.aviso, width: 2)),
        child: ClipOval(
          child: Image.network(
            AppConstants.resolverUrlFicheiro(badge.urlImagem)!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildIconeLetra('★', D.aviso),
          ),
        ),
      );
    }
    return _buildIconeLetra('★', D.aviso);
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
        child: Text(letra, style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
    );
  }
}