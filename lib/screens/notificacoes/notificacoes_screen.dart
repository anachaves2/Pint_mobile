import 'package:flutter/material.dart';
import 'package:pint_mobile/models/notificacao.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/utils/notificacao_utils.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

// ============================================================================
// NotificacoesScreen
//
// Lista todas as notificações do consultor autenticado, agrupadas por data
// (Hoje / Ontem / Esta Semana / Mais Antigas), tal como na web. Segue os
// tokens D e o CardSimples. Ao tocar navega para o detalhe; ao deslizar
// para a esquerda elimina (mantém-se — é um extra próprio do mobile que a
// web não tem).
// ============================================================================

class NotificacoesScreen extends StatefulWidget {
  const NotificacoesScreen({super.key});

  @override
  State<NotificacoesScreen> createState() => _NotificacoesScreenState();
}

class _NotificacoesScreenState extends State<NotificacoesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Notificacao> _todas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _carregarNotificacoes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregarNotificacoes() async {
    await APIService.instance.sincronizarNotificacoes();
    final lista = await DatabaseService.instance.getNotificacoes();
    if (mounted) {
      setState(() {
        _todas = lista;
        _isLoading = false;
      });
    }
  }

  // Devolve true se o utilizador confirmar a eliminação
  Future<bool> _confirmarEliminar(Notificacao n) async {
    final resposta = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: D.superficie,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rLg)),
        title: const Text('Eliminar notificação', style: D.tituloSeccao),
        content: const Text(
          'Queres mesmo eliminar esta notificação? Esta ação não pode ser desfeita.',
          style: D.corpo,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Não', style: TextStyle(color: D.tinta50)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: D.erro),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sim, eliminar'),
          ),
        ],
      ),
    );
    return resposta == true;
  }

  Future<void> _eliminar(Notificacao n) async {
    final resultado = await APIService.instance.eliminarNotificacao(n.id);
    if (resultado.sucesso && mounted) {
      setState(() => _todas.removeWhere((x) => x.id == n.id));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado.erro ?? 'Erro ao eliminar notificação.'),
          backgroundColor: D.erro,
        ),
      );
    }
  }

  Future<void> _marcarComoLida(Notificacao n) async {
    if (n.lida) return;
    await APIService.instance.marcarNotificacaoLida(n.id);
    setState(() {
      final idx = _todas.indexWhere((x) => x.id == n.id);
      if (idx != -1) {
        _todas[idx] = Notificacao(
          id: n.id,
          tipoNotificacao: n.tipoNotificacao,
          descricao: n.descricao,
          data: n.data,
          lida: true,
          numCandidatura: n.numCandidatura,
          idObjetivo: n.idObjetivo,
          idBadgeUtilizador: n.idBadgeUtilizador,
          idBadgeEspecial: n.idBadgeEspecial,
        );
      }
    });
  }

  Future<void> _marcarTodasComoLidas() async {
    await APIService.instance.marcarTodasNotificacoesLidas();
    setState(() {
      _todas = _todas
          .map((n) => Notificacao(
                id: n.id,
                tipoNotificacao: n.tipoNotificacao,
                descricao: n.descricao,
                data: n.data,
                lida: true,
                numCandidatura: n.numCandidatura,
                idObjetivo: n.idObjetivo,
                idBadgeUtilizador: n.idBadgeUtilizador,
                idBadgeEspecial: n.idBadgeEspecial,
              ))
          .toList();
    });
  }

  // Agrupa uma lista já filtrada por data, na ordem Hoje/Ontem/Esta Semana/Mais Antigas
  Map<String, List<Notificacao>> _agrupar(List<Notificacao> lista) {
    final mapa = <String, List<Notificacao>>{};
    for (final n in lista) {
      final g = NotificacaoUtils.grupoData(n.data);
      mapa.putIfAbsent(g, () => []).add(n);
    }
    return mapa;
  }

  Widget _buildCard(Notificacao n) {
    final config = NotificacaoUtils.configPara(n.tipoNotificacao);

    return Dismissible(
      key: Key('notif_${n.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: D.e4),
        margin: const EdgeInsets.only(bottom: D.e2),
        decoration: BoxDecoration(color: D.erro, borderRadius: BorderRadius.circular(D.rMd)),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      // Pede confirmação ANTES de apagar. Ao contrário do onDismissed, o
      // confirmDismiss deixa cancelar: se responder Não, o cartão volta ao
      // lugar e nada é apagado. Sem isto, um deslize acidental eliminava a
      // notificação sem aviso e sem forma de recuperar.
      confirmDismiss: (_) => _confirmarEliminar(n),
      onDismissed: (_) => _eliminar(n),
      child: Padding(
        padding: const EdgeInsets.only(bottom: D.e2),
        child: CardSimples(
          padding: const EdgeInsets.all(D.e3 + 2),
          onTap: () async {
            await _marcarComoLida(n);
            if (mounted) {
              context.push(AppConstants.routeDetalheNotificacao, extra: n);
            }
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: config.corFundo, shape: BoxShape.circle),
                child: Icon(config.icone, color: config.cor, size: 20),
              ),
              const SizedBox(width: D.e3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.descricao ?? config.titulo,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: n.lida ? FontWeight.w400 : FontWeight.w600,
                              color: D.tinta,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (!n.lida) ...[
                          const SizedBox(width: D.e2),
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(color: D.azul600, shape: BoxShape.circle),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(NotificacaoUtils.tempoRelativo(n.data), style: D.legenda.copyWith(fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLista(List<Notificacao> lista) {
    if (lista.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 56, color: D.tinta30),
            const SizedBox(height: D.e3),
            Text('Sem notificações', style: D.legenda),
          ],
        ),
      );
    }

    final grupos = _agrupar(lista);

    return RefreshIndicator(
      onRefresh: _carregarNotificacoes,
      color: D.azul600,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(D.e4, D.e3, D.e4, D.e4),
        children: [
          for (final g in NotificacaoUtils.ordemGrupos)
            if (grupos[g]?.isNotEmpty ?? false) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: D.e2),
                child: Text(g, style: D.etiqueta),
              ),
              for (final n in grupos[g]!) _buildCard(n),
              const SizedBox(height: D.e2),
            ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final naoLidas = _todas.where((n) => !n.lida).toList();

    return Scaffold(
      backgroundColor: D.fundo,
      drawer: const CustomDrawer(),
      appBar: AppBar(
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
        title: const Text('NOTIFICAÇÕES', style: D.tituloPagina),
        actions: [
          if (naoLidas.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all, color: AppConstants.corPrimaria),
              tooltip: 'Marcar todas como lidas',
              onPressed: _marcarTodasComoLidas,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(D.e4, 0, D.e4, D.e2),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: D.superficie,
                borderRadius: BorderRadius.circular(D.rSm),
                boxShadow: D.elev1,
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(color: D.azul600, borderRadius: BorderRadius.circular(D.rSm)),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: D.tinta30,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                tabs: [
                  const Tab(text: 'Todas'),
                  Tab(text: naoLidas.isEmpty ? 'Não Lidas' : 'Não Lidas (${naoLidas.length})'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: D.azul600))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLista(_todas),
                _buildLista(naoLidas),
              ],
            ),
    );
  }
}