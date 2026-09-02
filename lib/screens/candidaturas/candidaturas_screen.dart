import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/candidatura_badge.dart';
import 'package:pint_mobile/providers/candidatura_provider.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';
import 'package:go_router/go_router.dart';

// ECRÃ CANDIDATURAS (hub)
// Rascunhos + prévia de "Em progresso" e "Histórico" (3 de cada, com "Ver
// Todos"). Segue os tokens D e o CardSimples.

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
        title: Text(ref.tr('mobile_cand_apagar_rascunho_titulo'), style: const TextStyle(fontWeight: FontWeight.bold, color: D.azul600)),
        content: Text(
          ref.tr('mobile_cand_apagar_rascunho_texto'),
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ref.tr('mobile_notif_nao'), style: const TextStyle(color: D.tinta50))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ref.tr('mobile_cand_sim_apagar'), style: const TextStyle(color: D.erro, fontWeight: FontWeight.bold)),
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
        SnackBar(content: Text(ref.tr('mobile_cand_rascunho_apagado')), backgroundColor: D.ok),
      );
      _carregarRascunhos();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(resultado.erro ?? ref.tr('mobile_cand_erro_apagar')), backgroundColor: D.erro),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: D.fundo,
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
        title: Text(ref.t('mobile_cand_hub_titulo'), style: D.tituloPagina),
        actions: [
          IconButton(
            icon: SvgPicture.asset('assets/icons/notificacoesprimaria.svg', height: 24,
                colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => context.push(AppConstants.routeNotificacoes),
          ),
        ],
      ),
      body: ref.watch(candidaturasProvider).when(
        data: (candidaturas) {
          final emProgresso = candidaturas.where((c) => !c.estaConcluida).toList();
          final historico = candidaturas.where((c) => c.estaConcluida).toList();

          return RefreshIndicator(
            color: D.azul600,
            onRefresh: () async {
              await APIService.instance.sincronizarCandidaturas();
              await APIService.instance.sincronizarEstados();
              ref.invalidate(candidaturasProvider);
              await _carregarRascunhos();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(D.e4, D.e2, D.e4, D.e5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (emProgresso.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: D.e3),
                      child: Text(
                        '${emProgresso.length} ${emProgresso.length == 1 ? ref.t('mobile_cand_a_decorrer_singular') : ref.t('mobile_cand_a_decorrer_plural')}',
                        style: const TextStyle(color: D.azul600, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                  _buildSecao(
                    titulo: ref.t('mobile_cand_em_progresso'),
                    lista: emProgresso,
                    rotaVerTodos: AppConstants.routeCandidaturasDecorrentes,
                    vazioMsg: ref.t('mobile_cand_sem_curso'),
                  ),
                  const SizedBox(height: D.e5),
                  _buildSecaoRascunhos(),
                  if (_rascunhos.isNotEmpty) const SizedBox(height: D.e3),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push(AppConstants.routeNovaCandidatura).then((_) {
                        ref.invalidate(candidaturasProvider);
                        _carregarRascunhos();
                      }),
                      icon: const Icon(Icons.add, size: 18, color: D.azul600),
                      label: Text(ref.t('mobile_cand_nova'), style: const TextStyle(color: D.azul600, fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: D.azul600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: D.e5),
                  _buildSecao(
                    titulo: ref.t('mobile_cand_historico_titulo'),
                    lista: historico,
                    rotaVerTodos: AppConstants.routeHistoricoCandidaturas,
                    vazioMsg: ref.t('mobile_cand_sem_concluidas'),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: D.azul600)),
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
            Text(ref.t('mobile_cand_rascunhos'), style: D.etiqueta),
            const SizedBox(width: D.e2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: D.e2, vertical: 2),
              decoration: BoxDecoration(color: D.azul100, borderRadius: BorderRadius.circular(10)),
              child: Text('${_rascunhos.length}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: D.azul600)),
            ),
          ],
        ),
        const SizedBox(height: D.e2),
        ..._rascunhos.map((r) => Padding(
              padding: const EdgeInsets.only(bottom: D.e2),
              child: CardRascunho(
                rascunho: r,
                onContinuar: () => context.push(AppConstants.routeNovaCandidatura, extra: r).then((_) {
                  ref.invalidate(candidaturasProvider);
                  _carregarRascunhos();
                }),
                onApagar: () {
                  final num = (r['numCandidatura'] ?? r['num_candidatura']) as int?;
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
        Text(titulo, style: D.etiqueta),
        const SizedBox(height: D.e2),
        if (preview.isEmpty)
          CardSimples(child: Center(child: Text(vazioMsg ?? ref.t('mobile_cand_sem_dados'), style: D.legenda)))
        else
          ...preview.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: D.e2),
                child: CardCandidatura(
                  candidatura: c,
                  onTap: () => context
                      .push(AppConstants.routeDetalheCandidatura, extra: c.numCandidatura)
                      .then((_) => ref.invalidate(candidaturasProvider)),
                ),
              )),
        if (lista.length > 3)
          Center(
            child: TextButton(
              onPressed: () => context.push(rotaVerTodos).then((_) => ref.invalidate(candidaturasProvider)),
              child: Text(ref.t('mobile_cand_ver_todos'), style: const TextStyle(color: D.azul600, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
      ],
    );
  }
}

// ─── Card de candidatura ─────────────────────────────────────────────────────
class CardCandidatura extends ConsumerWidget {
  final CandidaturaBadge candidatura;
  final VoidCallback onTap;

  const CardCandidatura({super.key, required this.candidatura, required this.onTap});

  Color get _corEstado {
    if (candidatura.aprovada) return D.ok;
    if (candidatura.rejeitada) return D.erro;
    if (candidatura.aguardaAcaoConsultor) return D.aviso;
    return D.azul600;
  }

  Color get _corEstadoFundo {
    if (candidatura.aprovada) return D.okBg;
    if (candidatura.rejeitada) return D.erroBg;
    if (candidatura.aguardaAcaoConsultor) return D.avisoBg;
    return D.azul100;
  }

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year.toString().substring(2)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CardSimples(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(candidatura.nomeBadge, style: D.tituloCard),
          if (candidatura.nomeNivel != null) Text('${ref.t('mobile_cand_nivel_label')} ${candidatura.nomeNivel!}', style: D.legenda),
          const SizedBox(height: D.e2),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: D.tinta30),
              const SizedBox(width: 4),
              Text('${ref.t('mobile_cand_criado_em')} ${_fmt(candidatura.dataCriacao)}', style: D.legenda.copyWith(fontSize: 11)),
              const Spacer(),
              ChipEstado(texto: candidatura.nomeEstadoAtual, cor: _corEstado, corFundo: _corEstadoFundo),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Card de rascunho ────────────────────────────────────────────────────────
class CardRascunho extends ConsumerWidget {
  final Map<String, dynamic> rascunho;
  final VoidCallback onContinuar;
  final VoidCallback onApagar;

  const CardRascunho({super.key, required this.rascunho, required this.onContinuar, required this.onApagar});

  String _fmt(DateTime d) => '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year.toString().substring(2)}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final numEvidencias = rascunho['numEvidencias'] as int? ?? 0;
    final numRequisitos = rascunho['numRequisitos'] as int? ?? 0;
    final dataStr = rascunho['dataCriacao'] as String? ?? '';
    final data = DateTime.tryParse(dataStr);
    final dataFormatada = data != null ? _fmt(data) : '—';
    final progresso = numRequisitos > 0 ? numEvidencias / numRequisitos : 0.0;

    return CardSimples(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rascunho['nomeBadge'] as String? ?? ref.t('mobile_cand_sem_nome'), style: D.tituloCard),
                    if (rascunho['nomeNivel'] != null) Text('${ref.t('mobile_cand_nivel_label')} ${rascunho['nomeNivel']}', style: D.legenda),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onApagar,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: D.erroBg, borderRadius: BorderRadius.circular(D.rSm)),
                  child: const Icon(Icons.delete_outline, size: 18, color: D.erro),
                ),
              ),
            ],
          ),
          const SizedBox(height: D.e2),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: D.tinta30),
              const SizedBox(width: 4),
              Text('${ref.t('mobile_cand_criado_em')} $dataFormatada', style: D.legenda.copyWith(fontSize: 11)),
              const Spacer(),
              ChipEstado(texto: ref.t('mobile_cand_rascunho_chip'), cor: D.azul600, corFundo: D.azul100),
            ],
          ),
          const SizedBox(height: D.e3),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progresso,
                    minHeight: 5,
                    backgroundColor: D.fundoAlt,
                    valueColor: const AlwaysStoppedAnimation<Color>(D.azul600),
                  ),
                ),
              ),
              const SizedBox(width: D.e3),
              Text('$numEvidencias / $numRequisitos ${ref.t('mobile_cand_evidencias')}', style: D.legenda.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: D.e3),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onContinuar,
              icon: const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
              label: Text(ref.t('mobile_cand_continuar_botao'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
              style: ElevatedButton.styleFrom(
                backgroundColor: D.azul600,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}