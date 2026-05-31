import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pint_mobile/models/candidatura_badge.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:go_router/go_router.dart';

class Candidaturas extends StatefulWidget {
  const Candidaturas({super.key});

  @override
  State<Candidaturas> createState() => _CandidaturasState();
}

class _CandidaturasState extends State<Candidaturas> {
  List<CandidaturaBadge> _candidaturas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
    atualizadorDados.stream.listen((_) => _carregar());
  }

  Future<void> _carregar() async {
    final lista = await DatabaseService.instance.getCandidaturas();
    if (mounted) setState(() { _candidaturas = lista; _isLoading = false; });
  }

  Future<void> _refresh() async {
    await APIService.instance.sincronizarCandidaturas();
    await APIService.instance.sincronizarEstados();
    await _carregar();
  }

  List<CandidaturaBadge> get _emProgresso => _candidaturas.where((c) => !c.estaConcluida).toList();
  List<CandidaturaBadge> get _historico => _candidaturas.where((c) => c.estaConcluida).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: SvgPicture.asset('assets/icons/drawerprimario.svg', height: 20,
                colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('CANDIDATURAS',
            style: TextStyle(color: AppConstants.corPrimaria, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
        actions: [
          IconButton(
            icon: SvgPicture.asset('assets/icons/notificacoesprimaria.svg', height: 24,
                colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => context.push(AppConstants.routeNotificacoes),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppConstants.corPrimaria))
          : RefreshIndicator(
              color: AppConstants.corPrimaria,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_emProgresso.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.chevron_left, size: 18, color: AppConstants.corPrimaria),
                            Text(
                              '${_emProgresso.length} candidatura${_emProgresso.length == 1 ? '' : 's'} a decorrer',
                              style: const TextStyle(color: AppConstants.corPrimaria, fontWeight: FontWeight.w600, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    _buildSecao(
                      titulo: 'Em progresso',
                      lista: _emProgresso,
                      rotaVerTodos: AppConstants.routeCandidaturasDecorrentes,
                      vazioMsg: 'Não tens candidaturas em curso.',
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push(AppConstants.routeNovaCandidatura).then((_) => _refresh()),
                        icon: const Icon(Icons.add, size: 18, color: AppConstants.corPrimaria),
                        label: const Text('Nova Candidatura', style: TextStyle(color: AppConstants.corPrimaria, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppConstants.corPrimaria),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildSecao(
                      titulo: 'Histórico',
                      lista: _historico,
                      rotaVerTodos: AppConstants.routeHistoricoCandidaturas,
                      vazioMsg: 'Ainda não tens candidaturas concluídas.',
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSecao({
    required String titulo,
    required List<CandidaturaBadge> lista,
    required String rotaVerTodos,
    String? vazioMsg,
  }) {
    final preview = lista.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(titulo, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        if (preview.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: Text(vazioMsg ?? 'Sem dados.', style: const TextStyle(color: Colors.black38, fontSize: 13))),
          )
        else
          ...preview.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CardCandidatura(
                  candidatura: c,
                  onTap: () => context.push(AppConstants.routeDetalheCandidatura, extra: c.numCandidatura).then((_) => _refresh()),
                ),
              )),
        if (lista.length > 3)
          Center(
            child: OutlinedButton(
              onPressed: () => context.push(rotaVerTodos).then((_) => _refresh()),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppConstants.corPrimaria),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('VER TODOS', style: TextStyle(color: AppConstants.corPrimaria, fontSize: 12)),
            ),
          ),
      ],
    );
  }
}

// ─── Card reutilizável ───────────────────────────────────────────────────────
class CardCandidatura extends StatelessWidget {
  final CandidaturaBadge candidatura;
  final VoidCallback onTap;

  const CardCandidatura({super.key, required this.candidatura, required this.onTap});

  Color get _corEstado {
    if (candidatura.aprovada) return AppConstants.corSucesso;
    if (candidatura.rejeitada) return AppConstants.corErro;
    if (candidatura.aguardaAcaoConsultor) return Colors.orange;
    return AppConstants.corPrimaria;
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year.toString().substring(2)}';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(candidatura.nomeBadge,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
            if (candidatura.nomeNivel != null)
              Text('Nível ${candidatura.nomeNivel!}',
                  style: const TextStyle(fontSize: 12, color: Colors.black45)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.black38),
                const SizedBox(width: 4),
                Text('Criado em: ${_fmt(candidatura.dataCriacao)}',
                    style: const TextStyle(fontSize: 11, color: Colors.black38)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _corEstado.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    candidatura.nomeEstadoAtual,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _corEstado),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}