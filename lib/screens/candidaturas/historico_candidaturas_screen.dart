import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/candidatura_badge.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/providers/candidatura_provider.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:go_router/go_router.dart';

// ECRÃ HISTÓRICO DE CANDIDATURAS
// Paridade com a web (Pedidos Finalizados): pesquisa, filtro por nível e
// separador Todos/Aprovados/Rejeitados — nada disto existia.

enum _TabHistorico { todos, aprovados, rejeitados }

class HistoricoCandidaturas extends ConsumerStatefulWidget {
  const HistoricoCandidaturas({super.key});

  @override
  ConsumerState<HistoricoCandidaturas> createState() => _HistoricoCandidaturasState();
}

class _HistoricoCandidaturasState extends ConsumerState<HistoricoCandidaturas> {
  final TextEditingController _pesquisaController = TextEditingController();
  String _query = '';
  String _nivel = 'todos';
  _TabHistorico _tab = _TabHistorico.todos;

  @override
  void initState() {
    super.initState();
    atualizadorDados.stream.listen((_) => ref.invalidate(candidaturasProvider));
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  List<CandidaturaBadge> _aplicarFiltro(List<CandidaturaBadge> lista) {
    var filtrada = lista;
    if (_nivel != 'todos') {
      filtrada = filtrada.where((c) => c.nomeNivel == _nivel).toList();
    }
    if (_tab == _TabHistorico.aprovados) {
      filtrada = filtrada.where((c) => c.aprovada).toList();
    } else if (_tab == _TabHistorico.rejeitados) {
      filtrada = filtrada.where((c) => c.rejeitada).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      filtrada = filtrada.where((c) => c.nomeBadge.toLowerCase().contains(q)).toList();
    }
    return filtrada;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: D.fundo,
      drawer: const CustomDrawer(),
      appBar: _buildAppBar(),
      body: ref.watch(candidaturasProvider).when(
        loading: () => const Center(child: CircularProgressIndicator(color: D.azul600)),
        error: (err, _) => Center(child: Text('Erro: $err')),
        data: (todas) {
          final historico = todas.where((c) => c.estaConcluida).toList();
          final niveis = {for (final c in historico) if (c.nomeNivel != null) c.nomeNivel!}.toList()..sort();
          final filtradas = _aplicarFiltro(historico);

          return RefreshIndicator(
            color: D.azul600,
            onRefresh: () async {
              await APIService.instance.sincronizarCandidaturas();
              ref.invalidate(candidaturasProvider);
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(D.e4, D.e2, D.e4, D.e5),
              children: [
                _buildBarraPesquisa(),
                const SizedBox(height: D.e3),
                if (niveis.isNotEmpty) ...[
                  _buildFiltroNivel(niveis),
                  const SizedBox(height: D.e2),
                ],
                _buildTabsPills(),
                const SizedBox(height: D.e3),
                if (filtradas.isEmpty)
                  CardSimples(child: Center(child: Text('Sem candidaturas encontradas.', style: D.legenda)))
                else
                  for (final c in filtradas) _buildCard(c),
              ],
            ),
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
      title: const Text('HISTÓRICO', style: D.tituloPagina),
      actions: [
        IconButton(
          icon: SvgPicture.asset('assets/icons/notificacoesprimaria.svg', height: 24,
              colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn)),
          onPressed: () => context.push(AppConstants.routeNotificacoes),
        ),
      ],
    );
  }

  Widget _buildBarraPesquisa() {
    return Container(
      decoration: BoxDecoration(color: D.superficie, borderRadius: BorderRadius.circular(D.rMd), boxShadow: D.elev1),
      child: TextField(
        controller: _pesquisaController,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Pesquisar badge...',
          hintStyle: const TextStyle(color: D.tinta30, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: D.tinta30, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: D.e3),
        ),
      ),
    );
  }

  Widget _buildFiltroNivel(List<String> niveis) {
    final opcoes = ['todos', ...niveis];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: opcoes.map((n) {
          final ativo = _nivel == n;
          return Padding(
            padding: const EdgeInsets.only(right: D.e2),
            child: GestureDetector(
              onTap: () => setState(() => _nivel = n),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: D.e3, vertical: 6),
                decoration: BoxDecoration(
                  color: ativo ? D.azul600 : D.superficie,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: ativo ? null : D.elev1,
                ),
                child: Text(n == 'todos' ? 'Nível: Todos' : n,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ativo ? Colors.white : D.tinta30)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTabsPills() {
    final tabs = {
      _TabHistorico.todos: 'Todos',
      _TabHistorico.aprovados: 'Aprovados',
      _TabHistorico.rejeitados: 'Rejeitados',
    };
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: D.superficie, borderRadius: BorderRadius.circular(D.rSm), boxShadow: D.elev1),
      child: Row(
        children: tabs.entries.map((e) {
          final ativo = _tab == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = e.key),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(color: ativo ? D.azul600 : Colors.transparent, borderRadius: BorderRadius.circular(D.rSm - 2)),
                child: Text(e.value, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: ativo ? Colors.white : D.tinta30)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCard(CandidaturaBadge c) {
    final aprovada = c.aprovada;
    final cor = aprovada ? D.ok : D.erro;
    final corFundo = aprovada ? D.okBg : D.erroBg;
    final texto = aprovada ? 'Aprovado' : 'Rejeitado';
    final data = c.dataCriacao;
    final dataFmt = '${data.day.toString().padLeft(2, '0')}-${data.month.toString().padLeft(2, '0')}-${data.year.toString().substring(2)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: D.e2),
      child: CardSimples(
        onTap: () => context
            .push(AppConstants.routeDetalheCandidatura, extra: c.numCandidatura)
            .then((_) => ref.invalidate(candidaturasProvider)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(c.nomeBadge, style: D.tituloCard),
            if (c.nomeNivel != null) Text('Nível ${c.nomeNivel!}', style: D.legenda),
            const SizedBox(height: D.e2),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 12, color: D.tinta30),
                const SizedBox(width: 4),
                Text('Criado em: $dataFmt', style: D.legenda.copyWith(fontSize: 11)),
                const Spacer(),
                ChipEstado(texto: texto, cor: cor, corFundo: corFundo),
              ],
            ),
          ],
        ),
      ),
    );
  }
}