import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/candidatura_badge.dart';
import 'package:pint_mobile/providers/candidatura_provider.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:go_router/go_router.dart';

class Candidaturas extends ConsumerStatefulWidget {
  const Candidaturas({super.key});

  @override
  ConsumerState<Candidaturas> createState() => _CandidaturasState();
}

class _CandidaturasState extends ConsumerState<Candidaturas> {
  List<Map<String, dynamic>> _rascunhos = [];
  StreamSubscription<void>? _subAtualizador;

  @override
  void initState() {
    super.initState();
    _carregarRascunhos();
    _subAtualizador = atualizadorDados.stream.listen((_) {
      ref.invalidate(candidaturasProvider);
      _carregarRascunhos();
    });
  }

  @override
  void dispose() {
    _subAtualizador?.cancel();
    super.dispose();
  }

  Future<void> _carregarRascunhos() async {
    final resultadoRascunhos = await APIService.instance.getRascunhos();
    if (mounted) {
      setState(() => _rascunhos = resultadoRascunhos.rascunhos ?? []);
    }
  }

  Future<void> _apagarRascunho(int numCandidatura) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Apagar rascunho?',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppConstants.corPrimaria),
        ),
        content: const Text(
          'Esta acção não pode ser desfeita. As evidências carregadas serão removidas.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Não', style: TextStyle(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sim, apagar',
              style: TextStyle(color: AppConstants.corErro, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    if (!mounted) return;

    final resultado = await APIService.instance.cancelarRascunho(numCandidatura);
    if (!mounted) return;

    if (resultado.sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Rascunho apagado.'),
            backgroundColor: AppConstants.corSucesso),
      );
      _carregarRascunhos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(resultado.erro ?? 'Erro ao apagar'),
            backgroundColor: AppConstants.corErro),
      );
    }
  }

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
            icon: SvgPicture.asset('assets/icons/drawerprimario.svg',
                height: 20,
                colorFilter: const ColorFilter.mode(
                    AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('Candidaturas',
            style: TextStyle(
                color: AppConstants.corPrimaria,
                fontWeight: FontWeight.bold,
                fontSize: 20)),
        actions: [
          IconButton(
            icon: SvgPicture.asset('assets/icons/notificacoesprimaria.svg',
                height: 24,
                colorFilter: const ColorFilter.mode(
                    AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => context.push(AppConstants.routeNotificacoes),
          ),
        ],
      ),
      // ─── Riverpod — Aula 10 ───────────────────────────────────────────
      body: ref.watch(candidaturasProvider).when(
        data: (candidaturas) {
          final emProgresso = candidaturas.where((c) => !c.estaConcluida).toList();
          final historico = candidaturas.where((c) => c.estaConcluida).toList();

          return RefreshIndicator(
            color: AppConstants.corPrimaria,
            onRefresh: () async {
              await APIService.instance.sincronizarCandidaturas();
              await APIService.instance.sincronizarEstados();
              ref.invalidate(candidaturasProvider);
              await _carregarRascunhos();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (emProgresso.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.chevron_left,
                              size: 18, color: AppConstants.corPrimaria),
                          Text(
                            '${emProgresso.length} candidatura${emProgresso.length == 1 ? '' : 's'} a decorrer',
                            style: const TextStyle(
                                color: AppConstants.corPrimaria,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  _buildSecao(
                    titulo: 'Em progresso',
                    lista: emProgresso,
                    rotaVerTodos: AppConstants.routeCandidaturasDecorrentes,
                    vazioMsg: 'Não tens candidaturas em curso.',
                  ),
                  const SizedBox(height: 24),
                  _buildSecaoRascunhos(),
                  if (_rascunhos.isNotEmpty) const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => context
                          .push(AppConstants.routeNovaCandidatura)
                          .then((_) {
                        ref.invalidate(candidaturasProvider);
                        _carregarRascunhos();
                      }),
                      icon: const Icon(Icons.add,
                          size: 18, color: AppConstants.corPrimaria),
                      label: const Text('Nova Candidatura',
                          style: TextStyle(
                              color: AppConstants.corPrimaria,
                              fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppConstants.corPrimaria),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSecao(
                    titulo: 'Histórico',
                    lista: historico,
                    rotaVerTodos: AppConstants.routeHistoricoCandidaturas,
                    vazioMsg: 'Ainda não tens candidaturas concluídas.',
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppConstants.corPrimaria)),
        error: (err, _) => Center(child: Text('Erro: $err')),
      ),
    );
  }

  Widget _buildSecaoRascunhos() {
    if (_rascunhos.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Rascunhos',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    letterSpacing: 0.5)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppConstants.corPrimaria.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${_rascunhos.length}',
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.corPrimaria),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._rascunhos.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CardRascunho(
                rascunho: r,
                onContinuar: () => context
                    .push(AppConstants.routeNovaCandidatura, extra: r)
                    .then((_) {
                  ref.invalidate(candidaturasProvider);
                  _carregarRascunhos();
                }),
                onApagar: () {
                  final num =
                      (r['numCandidatura'] ?? r['num_candidatura']) as int?;
                  if (num != null) _apagarRascunho(num);
                },
              ),
            )),
      ],
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
        Text(titulo,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
                letterSpacing: 0.5)),
        const SizedBox(height: 8),
        if (preview.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
                child: Text(vazioMsg ?? 'Sem dados.',
                    style: const TextStyle(
                        color: Colors.black38, fontSize: 13))),
          )
        else
          ...preview.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CardCandidatura(
                  candidatura: c,
                  onTap: () => context
                      .push(AppConstants.routeDetalheCandidatura,
                          extra: c.numCandidatura)
                      .then((_) => ref.invalidate(candidaturasProvider)),
                ),
              )),
        if (lista.length > 3)
          Center(
            child: OutlinedButton(
              onPressed: () => context
                  .push(rotaVerTodos)
                  .then((_) => ref.invalidate(candidaturasProvider)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppConstants.corPrimaria),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              child: const Text('VER TODOS',
                  style: TextStyle(
                      color: AppConstants.corPrimaria, fontSize: 12)),
            ),
          ),
      ],
    );
  }
}

// ─── Card de candidatura ─────────────────────────────────────────────────────
class CardCandidatura extends StatelessWidget {
  final CandidaturaBadge candidatura;
  final VoidCallback onTap;

  const CardCandidatura(
      {super.key, required this.candidatura, required this.onTap});

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
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(candidatura.nomeBadge,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.black87)),
            if (candidatura.nomeNivel != null)
              Text('Nível ${candidatura.nomeNivel!}',
                  style: const TextStyle(fontSize: 12, color: Colors.black45)),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 12, color: Colors.black38),
                const SizedBox(width: 4),
                Text('Criado em: ${_fmt(candidatura.dataCriacao)}',
                    style:
                        const TextStyle(fontSize: 11, color: Colors.black38)),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: _corEstado.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    candidatura.nomeEstadoAtual,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _corEstado),
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

// ─── Card de rascunho ────────────────────────────────────────────────────────
class CardRascunho extends StatelessWidget {
  final Map<String, dynamic> rascunho;
  final VoidCallback onContinuar;
  final VoidCallback onApagar;

  const CardRascunho({
    super.key,
    required this.rascunho,
    required this.onContinuar,
    required this.onApagar,
  });

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year.toString().substring(2)}';

  @override
  Widget build(BuildContext context) {
    final numEvidencias = rascunho['numEvidencias'] as int? ?? 0;
    final numRequisitos = rascunho['numRequisitos'] as int? ?? 0;
    final dataStr = rascunho['dataCriacao'] as String? ?? '';
    final data = DateTime.tryParse(dataStr);
    final dataFormatada = data != null ? _fmt(data) : '—';
    final progresso =
        numRequisitos > 0 ? numEvidencias / numRequisitos : 0.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
        border: Border.all(
            color: AppConstants.corPrimaria.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rascunho['nomeBadge'] as String? ?? 'Sem nome',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Colors.black87),
                    ),
                    if (rascunho['nomeNivel'] != null)
                      Text('Nível ${rascunho['nomeNivel']}',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.black45)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onApagar,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppConstants.corErro.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.delete_outline,
                      size: 18, color: AppConstants.corErro),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 12, color: Colors.black38),
              const SizedBox(width: 4),
              Text('Criado em: $dataFormatada',
                  style: const TextStyle(fontSize: 11, color: Colors.black38)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppConstants.corPrimaria.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Rascunho',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppConstants.corPrimaria),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progresso,
                    minHeight: 5,
                    backgroundColor: Colors.black12,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        AppConstants.corPrimaria),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$numEvidencias / $numRequisitos evidências',
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onContinuar,
              icon: const Icon(Icons.arrow_forward,
                  size: 16, color: Colors.white),
              label: const Text('Continuar',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.corPrimaria,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}