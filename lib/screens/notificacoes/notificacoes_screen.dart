import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pint_mobile/models/notificacao.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:flutter_svg/flutter_svg.dart';
 
// ============================================================================
// NotificacoesScreen — Ecrãs 47 / 48
//
// Lista todas as notificações do consultor autenticado.
// Tabs: Todas | Não Lidas
// Cada card tem ícone colorido por tipo, título, descrição curta e data.
// Ao tocar navega para o detalhe; ao deslizar para a esquerda elimina.
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
    // Sincroniza com a API antes de ler do SQLite
    await APIService.instance.sincronizarNotificacoes();
    final lista = await DatabaseService.instance.getNotificacoes();
    if (mounted) {
      setState(() {
        _todas = lista;
        _isLoading = false;
      });
    }
  }
 
  Future<void> _eliminar(Notificacao n) async {
    final resultado = await APIService.instance.eliminarNotificacao(n.id);
    if (resultado.sucesso && mounted) {
      setState(() => _todas.removeWhere((x) => x.id == n.id));
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado.erro ?? 'Erro ao eliminar notificação.'),
          backgroundColor: AppConstants.corErro,
        ),
      );
    }
  }
 
  // Marca como lida no SQLite local e atualiza a UI
  Future<void> _marcarComoLida(Notificacao n) async {
    if (n.lida) return;
    await DatabaseService.instance.markAsRead(n.id);
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
 
  // ── Configuração visual por tipo de notificação ──
  static const Map<String, _TipoConfig> _configs = {
    'Badge Atribuido': _TipoConfig(
      icone: Icons.verified,
      cor: AppConstants.corSucesso,
      titulo: 'Badge Aprovado',
    ),
    'Evidencias Aprovadas': _TipoConfig(
      icone: Icons.check_circle_outline,
      cor: AppConstants.corSucesso,
      titulo: 'Evidências Aprovadas',
    ),
    'Objetivo Alcancado': _TipoConfig(
      icone: Icons.emoji_events_outlined,
      cor: AppConstants.corSucesso,
      titulo: 'Objetivo Alcançado',
    ),
    'Candidatura Devolvida': _TipoConfig(
      icone: Icons.warning_amber_outlined,
      cor: Color(0xFFF59E0B),
      titulo: 'Candidatura Devolvida',
    ),
    'Badge a Expirar': _TipoConfig(
      icone: Icons.timer_outlined,
      cor: Color(0xFFF59E0B),
      titulo: 'Badge a Expirar',
    ),
    'Badge Rejeitado': _TipoConfig(
      icone: Icons.cancel_outlined,
      cor: AppConstants.corErro,
      titulo: 'Badge Rejeitado',
    ),
  };
 
  static _TipoConfig _configPara(String tipo) {
    return _configs[tipo] ??
        const _TipoConfig(
          icone: Icons.notifications_outlined,
          cor: AppConstants.corPrimaria,
          titulo: 'Notificação',
        );
  }
 
  // ── Card de notificação ──
  Widget _buildCard(Notificacao n) {
    final config = _configPara(n.tipoNotificacao);
    final dataFmt = DateFormat('dd-MM-yyyy  HH:mm').format(n.data);
 
    return Dismissible(
      key: Key('notif_${n.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppConstants.corErro,
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => _eliminar(n),
      child: InkWell(
        onTap: () async {
          await _marcarComoLida(n);
          if (mounted) {
            Navigator.pushNamed(
              context,
              AppConstants.routeDetalheNotificacao,
              arguments: n,
            );
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: n.lida ? Colors.white : AppConstants.corPrimaria.withValues(alpha:0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: n.lida ? Colors.grey.shade200 : AppConstants.corPrimaria.withValues(alpha:0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ícone colorido
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: config.cor.withValues(alpha:0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icone, color: config.cor, size: 22),
              ),
              const SizedBox(width: 12),
 
              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            config.titulo,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: n.lida ? FontWeight.w500 : FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        if (!n.lida)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppConstants.corPrimaria,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.descricao ?? '',
                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dataFmt,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
            ],
          ),
        ),
      ),
    );
  }
 
  Widget _buildLista(List<Notificacao> lista) {
    if (lista.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined, size: 56, color: Colors.grey),
            SizedBox(height: 12),
            Text('Sem notificações', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
 
    return RefreshIndicator(
      onRefresh: _carregarNotificacoes,
      color: AppConstants.corPrimaria,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: lista.length,
        itemBuilder: (_, i) => _buildCard(lista[i]),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    final naoLidas = _todas.where((n) => !n.lida).toList();
 
    return Scaffold(
      backgroundColor: Colors.white,
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
              colorFilter: const ColorFilter.mode(
                AppConstants.corPrimaria,
                BlendMode.srcIn,
              ),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text('NOTIFICAÇÕES'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppConstants.corPrimaria,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppConstants.corPrimaria,
          tabs: [
            const Tab(text: 'Todas'),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Não Lidas'),
                  if (naoLidas.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppConstants.corPrimaria,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${naoLidas.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
 
// Classe auxiliar para configuração visual por tipo
class _TipoConfig {
  final IconData icone;
  final Color cor;
  final String titulo;
  const _TipoConfig({
    required this.icone,
    required this.cor,
    required this.titulo,
  });
}