import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/providers/badges_provider.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/utils/badge_utils.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';
import 'package:go_router/go_router.dart';

// ECRÃ OS MEUS BADGES
// Paridade com a web (views/consultor/Badges.jsx): filtro por texto + por
// estado (Todos/Válidos/Expirados), indicador colorido de validade e
// contagem decrescente até à expiração. Segue os tokens D e o CardSimples.

enum _FiltroEstado { todos, validos, expirados }

class OsMeusBadges extends ConsumerStatefulWidget {
  const OsMeusBadges({super.key});

  @override
  ConsumerState<OsMeusBadges> createState() => _OsMeusBadgesState();
}

class _OsMeusBadgesState extends ConsumerState<OsMeusBadges> {
  final TextEditingController _pesquisaController = TextEditingController();
  String _queryPesquisa = '';
  _FiltroEstado _filtroEstado = _FiltroEstado.todos;

  @override
  void initState() {
    super.initState();
    // Ao contrário do ecrã de Objetivos, este nunca sincronizava ao abrir —
    // só mostrava o que já estava em SQLite de uma sincronização anterior
    // (ex.: a do arranque da app), e só se atualizava com um pull-to-refresh
    // manual. Um badge atribuído entretanto (ex.: candidatura aprovada
    // enquanto a app estava aberta) só aparecia depois de puxar a lista para
    // baixo — daí a sensação de que "não atualiza logo".
    ref.read(badgesProvider.notifier).atualizar();
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  // Filtra por texto (nome, nível, área, service line).
  List<BadgeUtilizador> _filtrarTexto(List<BadgeUtilizador> lista) {
    if (_queryPesquisa.isEmpty) return lista;
    final q = _queryPesquisa.toLowerCase();
    return lista.where((b) {
      return b.nomeBadge.toLowerCase().contains(q) ||
          (b.nomeNivel?.toLowerCase().contains(q) ?? false) ||
          (b.nomeArea?.toLowerCase().contains(q) ?? false) ||
          (b.nomeServiceLine?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  // Filtra por estado (igual ao "tipoMeus" da web).
  List<BadgeUtilizador> _filtrarEstado(List<BadgeUtilizador> lista) {
    switch (_filtroEstado) {
      case _FiltroEstado.validos:
        return lista.where((b) => b.valido).toList();
      case _FiltroEstado.expirados:
        return lista.where((b) => !b.valido).toList();
      case _FiltroEstado.todos:
        return lista;
    }
  }

  List<BadgeUtilizador> _filtrar(List<BadgeUtilizador> lista) =>
      _filtrarTexto(_filtrarEstado(lista));

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
      ..sort((a, b) => (b.dataExpiracao ?? DateTime(0)).compareTo(a.dataExpiracao ?? DateTime(0)));
    return _filtrar(lista).take(3).toList();
  }

  // ── Indicador de validade — igual ao corIndicadorValidade da web ──────────
  Color _corIndicadorValidade(BadgeUtilizador b) {
    if (!b.valido) return D.erro;
    if (b.dataExpiracao == null) return D.ok; // sem data de expiração = válido para sempre
    final horasRestantes = b.dataExpiracao!.difference(DateTime.now()).inMinutes / 60;
    if (horasRestantes > 0 && horasRestantes <= 72) return D.aviso;
    return D.ok;
  }

  // ── Texto de expiração — igual ao formatarTempoRestante da web ───────────
  String _textoExpiracao(BadgeUtilizador b) {
    if (b.dataExpiracao == null) return ref.t('mobile_badges_sem_data_expiracao');
    final diff = b.dataExpiracao!.difference(DateTime.now());
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
        data: (todos) => RefreshIndicator(
          color: D.azul600,
          onRefresh: () => ref.read(badgesProvider.notifier).atualizar(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(D.e4, D.e2, D.e4, D.e5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBarraPesquisa(),
                const SizedBox(height: D.e2),
                _buildFiltroEstado(),
                const SizedBox(height: D.e5),
                _buildSecao(
                  titulo: ref.t('mobile_meusbadges_recentes'),
                  badges: _badgesRecentes(todos),
                  rotaVerTodos: AppConstants.routeTodosBadges,
                  vazioTitulo: ref.t('mobile_meusbadges_vazio_titulo'),
                  vazioSubtitulo: ref.t('mobile_meusbadges_vazio_subtitulo'),
                  vazioComBotao: true,
                ),
                const SizedBox(height: D.e5),
                _buildSecao(
                  titulo: ref.t('mobile_badges_especiais_maiusc'),
                  badges: _badgesEspeciais(todos),
                  rotaVerTodos: AppConstants.routeBadgesEspeciais,
                  vazioTitulo: ref.t('mobile_meusbadges_especiais_vazio_titulo'),
                  vazioSubtitulo: ref.t('mobile_meusbadges_especiais_vazio_subtitulo'),
                ),
                const SizedBox(height: D.e5),
                _buildSecao(
                  titulo: ref.t('mobile_meusbadges_expirados_maiusc'),
                  badges: _badgesExpirados(todos),
                  rotaVerTodos: AppConstants.routeBadgesExpirados,
                  vazioTitulo: ref.t('mobile_meusbadges_expirados_vazio_titulo'),
                  vazioSubtitulo: ref.t('mobile_meusbadges_expirados_vazio_subtitulo'),
                ),
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: SvgPicture.asset(
            'assets/icons/drawerprimario.svg',
            height: 20,
            colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn),
          ),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
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

  // ─── Barra de pesquisa ────────────────────────────────────────────────────

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

  // ─── Filtro por estado — igual ao <select> tipoMeus da web ────────────────

  Widget _buildFiltroEstado() {
    final opcoes = {
      _FiltroEstado.todos: ref.t('mobile_cand_tab_todos'),
      _FiltroEstado.validos: ref.t('mobile_meusbadges_validos'),
      _FiltroEstado.expirados: ref.t('mobile_meusbadges_expirados'),
    };
    return Row(
      children: opcoes.entries.map((entry) {
        final ativo = _filtroEstado == entry.key;
        return Padding(
          padding: const EdgeInsets.only(right: D.e2),
          child: GestureDetector(
            onTap: () => setState(() => _filtroEstado = entry.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: D.e3, vertical: 6),
              decoration: BoxDecoration(
                color: ativo ? D.azul600 : D.superficie,
                borderRadius: BorderRadius.circular(999),
                boxShadow: ativo ? null : D.elev1,
              ),
              child: Text(
                entry.value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: ativo ? Colors.white : D.tinta30,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Secção genérica ──────────────────────────────────────────────────────

  Widget _buildSecao({
    required String titulo,
    required List<BadgeUtilizador> badges,
    required String rotaVerTodos,
    required String vazioTitulo,
    required String vazioSubtitulo,
    bool vazioComBotao = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: D.etiqueta),
        const SizedBox(height: D.e3),
        if (badges.isEmpty)
          // Sem badges não faz sentido oferecer "VER TODOS" — mostra antes
          // uma explicação e, quando aplicável, o caminho para o catálogo.
          _buildEstadoVazio(titulo: vazioTitulo, subtitulo: vazioSubtitulo, comBotao: vazioComBotao)
        else ...[
          ...badges.map((badge) => _buildBadgeCard(badge)),
          const SizedBox(height: D.e2),
          Center(
            child: TextButton(
              onPressed: () => context.push(rotaVerTodos),
              child: Text(ref.t('mobile_cand_ver_todos'),
                  style: const TextStyle(color: D.azul600, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEstadoVazio({required String titulo, required String subtitulo, bool comBotao = false}) {
    return CardSimples(
      child: Column(
        // stretch: sem isto a Column encolhia à largura do texto e o cartão
        // ficava mais estreito do que os cartões de badge das outras secções.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.workspace_premium_outlined, color: D.tinta30, size: 36),
          const SizedBox(height: D.e2),
          Text(titulo, style: D.tituloCard, textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(subtitulo, style: D.legenda, textAlign: TextAlign.center),
          if (comBotao) ...[
            const SizedBox(height: D.e3),
            OutlinedButton.icon(
              onPressed: () => context.push(AppConstants.routeCatalogo),
              icon: const Icon(Icons.search, size: 16),
              label: Text(ref.t('mobile_meusbadges_ver_disponiveis')),
              style: OutlinedButton.styleFrom(
                foregroundColor: D.azul600,
                side: const BorderSide(color: D.azul600),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Card de badge ────────────────────────────────────────────────────────

  Widget _buildBadgeCard(BadgeUtilizador badge) {
    final bool eEspecial = badge.idBadgeEspecial != null;
    final bool eExpirado = badge.jaExpirou;

    return Padding(
      padding: const EdgeInsets.only(bottom: D.e2),
      child: CardSimples(
        onTap: () {
          if (eEspecial) {
            context.push(AppConstants.routeDetalheBadgePremium, extra: badge);
          } else if (eExpirado) {
            context.push(AppConstants.routeDetalheBadgeExpirado, extra: badge);
          } else {
            context.push(AppConstants.routeDetalheBadge, extra: badge);
          }
        },
        child: Row(
          children: [
            _buildIconeBadge(badge, eEspecial, eExpirado),
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
                        decoration: BoxDecoration(
                          color: _corIndicadorValidade(badge),
                          shape: BoxShape.circle,
                        ),
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

  Widget _buildIconeBadge(BadgeUtilizador badge, bool eEspecial, bool eExpirado) {
    final Color cor;
    if (eExpirado) {
      cor = D.tinta30;
    } else if (eEspecial) {
      cor = D.aviso;
    } else {
      cor = BadgeUtils.corDoNivel(badge.tipoNivel);
    }

    final letra = eEspecial
        ? '★'
        : (badge.tipoNivel?.isNotEmpty == true ? badge.tipoNivel![0].toUpperCase() : '?');

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
        child: Text(
          letra,
          style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: letra == '★' ? 18 : 16),
        ),
      ),
    );
  }
}