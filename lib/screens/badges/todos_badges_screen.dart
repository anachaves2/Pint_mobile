import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/badge_regular.dart';
import 'package:pint_mobile/providers/badges_provider.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/utils/badge_utils.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';
import 'package:go_router/go_router.dart';

// ECRÃ CATÁLOGO DE BADGES
// Requisito 8 (Consultor): "Deve ter um Catálogo de badges disponíveis com
// descrições." — isto é TODOS os badges regulares da plataforma (não só os
// que o consultor já tem), com filtro por texto e por nível, tal como a
// secção "Catálogo de Badges" de views/consultor/Badges.jsx na web.
// Badges já obtidos ficam marcados, os outros levam ao detalhe + candidatura.

class TodosOsBadges extends ConsumerStatefulWidget {
  const TodosOsBadges({super.key});

  @override
  ConsumerState<TodosOsBadges> createState() => _TodosOsBadgesState();
}

class _TodosOsBadgesState extends ConsumerState<TodosOsBadges> {
  final TextEditingController _pesquisaController = TextEditingController();
  String _queryPesquisa = '';
  String _areaSelecionada = 'todos';

  List<BadgeRegular>? _catalogo;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    var lista = await DatabaseService.instance.getCatalogoBadges();

    // Se o SQLite ainda não tem catálogo (primeira utilização, ou a
    // sincronização de arranque não chegou a correr/falhou), vai buscar à
    // API antes de desistir — senão o ecrã ficava vazio para sempre.
    if (lista.isEmpty) {
      await APIService.instance.sincronizarCatalogo();
      lista = await DatabaseService.instance.getCatalogoBadges();
    }

    if (mounted) setState(() => _catalogo = lista);
  }

  // Pull-to-refresh: força sempre ida à API
  Future<void> _refrescar() async {
    await APIService.instance.sincronizarCatalogo();
    final lista = await DatabaseService.instance.getCatalogoBadges();
    if (mounted) setState(() => _catalogo = lista);
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  List<BadgeRegular> _aplicarFiltro(List<BadgeRegular> catalogo) {
    var lista = catalogo;

    if (_areaSelecionada != 'todos') {
      lista = lista.where((b) => b.nomeArea == _areaSelecionada).toList();
    }

    if (_queryPesquisa.isNotEmpty) {
      final q = _queryPesquisa.toLowerCase();
      lista = lista.where((b) {
        return b.nome.toLowerCase().contains(q) ||
            b.nomeNivel.toLowerCase().contains(q) ||
            (b.nomeArea?.toLowerCase().contains(q) ?? false) ||
            (b.nomeServiceLine?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return lista..sort((a, b) => a.nome.compareTo(b.nome));
  }

  @override
  Widget build(BuildContext context) {
    final badgesObtidos = ref.watch(badgesProvider).valueOrNull ?? [];
    final idsObtidos = badgesObtidos
        .where((b) => b.valido && b.idBadgeRegular != null)
        .map((b) => b.idBadgeRegular!)
        .toSet();

    return Scaffold(
      backgroundColor: D.fundo,
      drawer: const CustomDrawer(),
      appBar: _buildAppBar(),
      body: _catalogo == null
          ? const Center(child: CircularProgressIndicator(color: D.azul600))
          : _buildConteudo(idsObtidos),
    );
  }

  Widget _buildConteudo(Set<int> idsObtidos) {
    final areas = {for (final b in _catalogo!) if (b.nomeArea != null) b.nomeArea!}.toList()..sort();
    final filtrados = _aplicarFiltro(_catalogo!);

    return RefreshIndicator(
      color: D.azul600,
      onRefresh: _refrescar,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(D.e4, D.e2, D.e4, D.e5),
        children: [
          _buildBarraPesquisa(),
          const SizedBox(height: D.e3),
          _buildFiltroArea(areas),
          const SizedBox(height: D.e2),
          Text('${filtrados.length} badge${filtrados.length == 1 ? '' : 's'} disponíve${filtrados.length == 1 ? 'l' : 'is'}',
              style: D.legenda),
          const SizedBox(height: D.e3),
          if (filtrados.isEmpty)
            CardSimples(
              child: Center(child: Text(ref.t('mobile_catalogo_vazio'), style: D.legenda)),
            )
          else
            for (final badge in filtrados) _buildCardCatalogo(badge, idsObtidos.contains(badge.id)),
        ],
      ),
    );
  }

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
      title: Text(ref.t('mobile_catalogo_titulo'), style: D.tituloPagina),
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
          hintText: ref.t('mobile_catalogo_procurar_hint'),
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

  // Filtro por área — mostra todos os badges dessa área, seja qual for o nível
  Widget _buildFiltroArea(List<String> areas) {
    final opcoes = ['todos', ...areas];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: opcoes.map((area) {
          final ativo = _areaSelecionada == area;
          return Padding(
            padding: const EdgeInsets.only(right: D.e2),
            child: GestureDetector(
              onTap: () => setState(() => _areaSelecionada = area),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: D.e3, vertical: 6),
                decoration: BoxDecoration(
                  color: ativo ? D.azul600 : D.superficie,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: ativo ? null : D.elev1,
                ),
                child: Text(
                  area == 'todos' ? ref.t('mobile_catalogo_todas_areas') : area,
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
      ),
    );
  }

  Widget _buildCardCatalogo(BadgeRegular badge, bool jaObtido) {
    final cor = BadgeUtils.corDoNivel(badge.nomeNivel);
    final letra = badge.nomeNivel.isNotEmpty ? badge.nomeNivel[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: D.e2),
      child: CardSimples(
        onTap: () => context.push(AppConstants.routeDetalheCatalogo, extra: badge),
        child: Row(
          children: [
            _buildIconeBadge(badge, letra, cor, jaObtido),
            const SizedBox(width: D.e3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(badge.nome, style: D.tituloCard),
                  const SizedBox(height: 2),
                  Text('${badge.nomeNivel} · ${badge.nomeArea ?? '—'}', style: D.legenda),
                ],
              ),
            ),
            if (jaObtido)
              ChipEstado(texto: ref.t('mobile_catalogo_obtido'), cor: D.ok, corFundo: D.okBg)
            else
              Column(
                children: [
                  Text('${badge.pontos ?? 0}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: D.azul600)),
                  Text('pontos', style: D.legenda.copyWith(fontSize: 10)),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconeBadge(BadgeRegular badge, String letra, Color cor, bool jaObtido) {
    final corFinal = jaObtido ? D.ok : cor;
    if (badge.urlImagem != null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: corFinal, width: 2)),
        child: ClipOval(
          child: Image.network(
            AppConstants.resolverUrlFicheiro(badge.urlImagem)!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildIconeLetra(letra, corFinal, jaObtido),
          ),
        ),
      );
    }
    return _buildIconeLetra(letra, corFinal, jaObtido);
  }

  Widget _buildIconeLetra(String letra, Color cor, bool jaObtido) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cor.withValues(alpha: 0.15),
        border: Border.all(color: cor, width: 2),
      ),
      child: Center(
        child: jaObtido
            ? const Icon(Icons.check, color: D.ok, size: 20)
            : Text(letra, style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}