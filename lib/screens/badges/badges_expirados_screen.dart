import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/providers/badges_provider.dart';
import 'package:pint_mobile/utils/badge_utils.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:go_router/go_router.dart';

// ECRÃ BADGES EXPIRADOS
// Lista completa de badges expirados do consultor. Segue os tokens D e o
// CardSimples, mantendo o tratamento a cinzento/preto-e-branco que já
// distinguia visualmente o estado "inativo" — isso é intencional, fica.

class BadgesExpirados extends ConsumerStatefulWidget {
  const BadgesExpirados({super.key});

  @override
  ConsumerState<BadgesExpirados> createState() => _BadgesExpiradosState();
}

class _BadgesExpiradosState extends ConsumerState<BadgesExpirados> {
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
    final expirados = todos.where((b) => b.jaExpirou).toList()
      ..sort((a, b) => (b.dataExpiracao ?? DateTime(0)).compareTo(a.dataExpiracao ?? DateTime(0)));

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
          Icon(Icons.hourglass_disabled_outlined, color: D.tinta30, size: 64),
          const SizedBox(height: D.e4),
          Text(
            _pesquisaController.text.isNotEmpty ? ref.t('mobile_badges_nenhum_encontrado') : ref.t('mobile_badges_sem_expirados'),
            style: D.corpo,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(BadgeUtilizador badge) {
    return Padding(
      padding: const EdgeInsets.only(bottom: D.e2),
      child: Container(
        // Fundo ligeiramente acinzentado + sombra mais discreta para indicar
        // que está inativo — mesma elevação neutra, só mais suave.
        decoration: BoxDecoration(
          color: D.fundoAlt,
          borderRadius: BorderRadius.circular(D.rMd),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(D.rMd),
          onTap: () => context.push(AppConstants.routeDetalheBadgeExpirado, extra: badge),
          child: Padding(
            padding: const EdgeInsets.all(D.e4),
            child: Row(
              children: [
                _buildIconeExpirado(badge),
                const SizedBox(width: D.e3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(badge.nomeBadge,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: D.tinta50)),
                      if (badge.nomeNivel != null) ...[
                        const SizedBox(height: 2),
                        Text(badge.nomeNivel!, style: D.legenda.copyWith(color: D.tinta30)),
                      ],
                      const SizedBox(height: D.e2),
                      Text('Conquistado: ${BadgeUtils.formatarData(badge.dataAtribuicao)}',
                          style: D.legenda.copyWith(fontSize: 11, color: D.tinta30)),
                      Text('Expirou: ${BadgeUtils.formatarData(badge.dataExpiracao)}',
                          style: const TextStyle(fontSize: 11, color: D.erro)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: D.tinta30, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconeExpirado(BadgeUtilizador badge) {
    const cor = D.tinta30;
    final letra = badge.idBadgeEspecial != null
        ? '★'
        : (badge.tipoNivel?.isNotEmpty == true ? badge.tipoNivel![0].toUpperCase() : '?');

    if (badge.urlImagem != null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: cor, width: 2)),
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
              AppConstants.resolverUrlFicheiro(badge.urlImagem)!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildIconeLetra(letra, cor),
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
        child: Text(letra, style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: letra == '★' ? 18 : 16)),
      ),
    );
  }
}