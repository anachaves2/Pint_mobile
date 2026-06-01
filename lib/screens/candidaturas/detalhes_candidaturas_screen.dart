import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pint_mobile/models/candidatura_badge.dart';
import 'package:pint_mobile/models/historico_candidatura.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:go_router/go_router.dart';
import 'package:pint_mobile/models/requisitos.dart';
import 'package:pint_mobile/models/evidencia.dart';

class DetalhesCandidatura extends StatefulWidget {
  final int numCandidatura;
  const DetalhesCandidatura({super.key, required this.numCandidatura});

  @override
  State<DetalhesCandidatura> createState() => _DetalhesCandidaturaState();
}

class _DetalhesCandidaturaState extends State<DetalhesCandidatura> {
  CandidaturaBadge? _candidatura;
  List<HistoricoCandidatura> _historico = [];
  bool _isLoading = true;
  int? _numCandidatura;
  List<Requisito> _requisitos = [];
  Map<int, Evidencia> _evidencias = {};


  @override
  void initState() {
    super.initState();
    _numCandidatura = widget.numCandidatura;
    _carregar();
  }

  Future<void> _carregar() async {
    if (_numCandidatura == null) return;
    // Mostra cache primeiro
    final todasCandidaturas = await DatabaseService.instance.getCandidaturas();
    final candidatura = todasCandidaturas.where((c) => c.numCandidatura == _numCandidatura).firstOrNull;
    final historico = await DatabaseService.instance.getHistorico(_numCandidatura!);
    final requisitos = candidatura != null ? await DatabaseService.instance.getRequisitos(candidatura.idBadgeRegular) : <Requisito>[];
    final listaEvidencias = await DatabaseService.instance.getEvidencias(_numCandidatura!);
    if (mounted) {
      setState(() {
        _candidatura = candidatura;
        _historico = historico;
        _isLoading = false;
        _requisitos = requisitos;
        _evidencias = { for (final e in listaEvidencias) e.idRequisito: e };
      });
    }
    // Sincroniza em background
    await APIService.instance.sincronizarDetalhesCandidatura(_numCandidatura!);
    final todasAtual = await DatabaseService.instance.getCandidaturas();
    final candidaturaAtual = todasAtual.where((c) => c.numCandidatura == _numCandidatura).firstOrNull;
    final historicoAtual = await DatabaseService.instance.getHistorico(_numCandidatura!);
    final requisitosAtual = candidaturaAtual != null ? await DatabaseService.instance.getRequisitos(candidaturaAtual.idBadgeRegular) : <Requisito>[];
    final evidenciasAtual = await DatabaseService.instance.getEvidencias(_numCandidatura!);
    if (mounted) {
      setState(() {
        _candidatura = candidaturaAtual;
        _historico = historicoAtual;
        _requisitos = requisitosAtual;
        _evidencias = { for (final e in evidenciasAtual) e.idRequisito: e };
      });
    }
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _carregar();
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
            icon: SvgPicture.asset('assets/icons/drawerprimario.svg', height: 20,
                colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        title: const Text('Candidaturas',
            style: TextStyle(color: AppConstants.corPrimaria, fontWeight: FontWeight.bold, fontSize: 20)),
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
          : _candidatura == null
              ? const Center(child: Text('Candidatura não encontrada.'))
              : RefreshIndicator(
                  color: AppConstants.corPrimaria,
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sub-título
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Icon(Icons.chevron_left, color: AppConstants.corPrimaria),
                            ),
                            const Text('Detalhes da Candidatura',
                                style: TextStyle(color: AppConstants.corPrimaria, fontWeight: FontWeight.w600, fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildCabecalho(),
                        if (_requisitos.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const Text('Requisitos submetidos:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54, letterSpacing: 0.3)),
                          const SizedBox(height: 10),
                          ..._requisitos.map((req) => _buildCardRequisito(req)),
                        ],
                        const SizedBox(height: 20),
                        const Text('Timeline:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54, letterSpacing: 0.3)),
                        const SizedBox(height: 10),
                        _buildTimeline(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildCabecalho() {
    final c = _candidatura!;
    final aprovada = c.aprovada;
    final rejeitada = c.rejeitada;
    final corDecisao = aprovada ? AppConstants.corSucesso : (rejeitada ? AppConstants.corErro : Colors.black38);
    final textoDecisao = aprovada ? 'Aprovado' : (rejeitada ? 'Rejeitado' : '—');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _linhaInfo('Badge:', c.nomeBadge),
          if (c.nomeNivel != null) _linhaInfo('Nível:', c.nomeNivel!),
          if (c.estaConcluida)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  const SizedBox(width: 100, child: Text('Decisão final:', style: TextStyle(fontSize: 12, color: Colors.black45))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: corDecisao.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(textoDecisao, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: corDecisao)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _linhaInfo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.black45))),
          Expanded(child: Text(valor, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87))),
        ],
      ),
    );
  }

  Widget _buildTimeline() {
    if (_historico.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('Sem histórico disponível.', style: TextStyle(color: Colors.grey)),
      ));
    }
    final invertido = _historico.reversed.toList();
    return Column(
      children: List.generate(invertido.length, (i) => _ItemTimeline(entrada: invertido[i], isLast: i == invertido.length - 1)),
    );
  }

  Widget _buildCardRequisito(Requisito req) {
  final evidencia = _evidencias[req.id];

  Color corEstado;
  IconData iconEstado;
  String textoEstado;

  if (evidencia == null) {
    corEstado = Colors.orange;
    iconEstado = Icons.upload_file_outlined;
    textoEstado = 'Sem evidência';
  } else if (evidencia.aprovada) {
    corEstado = AppConstants.corSucesso;
    iconEstado = Icons.check_circle_outline;
    textoEstado = 'Aprovada';
  } else if (evidencia.rejeitada) {
    corEstado = AppConstants.corErro;
    iconEstado = Icons.cancel_outlined;
    textoEstado = 'Rejeitada';
  } else {
    corEstado = AppConstants.corPrimaria;
    iconEstado = Icons.hourglass_empty_outlined;
    textoEstado = 'Pendente';
  }

  return Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: corEstado.withOpacity(0.3)),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(iconEstado, color: corEstado, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(req.nome,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: corEstado.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(textoEstado,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: corEstado)),
            ),
          ],
        ),
        if (req.descricao != null && req.descricao!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(req.descricao!,
              style: const TextStyle(fontSize: 12, color: Colors.black45, height: 1.4)),
        ],
        if (evidencia != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.attach_file, size: 12, color: Colors.black38),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  evidencia.pathFicheiro.split('/').last,
                  style: const TextStyle(fontSize: 11, color: Colors.black38),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
  }
}

class _ItemTimeline extends StatelessWidget {
  final HistoricoCandidatura entrada;
  final bool isLast;
  const _ItemTimeline({required this.entrada, required this.isLast});

  Color get _corPonto {
    switch (entrada.idEstadoAtual) {
      case 5: return AppConstants.corSucesso;
      case 6: return AppConstants.corErro;
      case 2: case 4: return Colors.orange;
      default: return AppConstants.corSecundaria;
    }
  }

  String get _textoDecisao {
    switch (entrada.idEstadoAtual) {
      case 5: return 'Aprovado';
      case 6: return 'Rejeitado';
      case 2: case 4: return 'Incorreto';
      case 1: case 3: return 'Correto';
      default: return '';
    }
  }

  Color get _corDecisao {
    switch (entrada.idEstadoAtual) {
      case 5: case 1: case 3: return AppConstants.corSucesso;
      case 6: case 2: case 4: return AppConstants.corErro;
      default: return Colors.black38;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hora = '${entrada.dataAlteracao.day} ${_mesAbrev(entrada.dataAlteracao.month)} ${entrada.dataAlteracao.year} '
        '${entrada.dataAlteracao.hour.toString().padLeft(2, '0')}:${entrada.dataAlteracao.minute.toString().padLeft(2, '0')}';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: _corPonto, shape: BoxShape.circle)),
              if (!isLast) Expanded(child: Container(width: 2, color: Colors.black12)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 1))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 11, color: Colors.black38),
                        const SizedBox(width: 4),
                        Text(hora, style: const TextStyle(fontSize: 11, color: Colors.black45)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(entrada.nomeEstadoAtual,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.black54)),
                        ),
                      ],
                    ),
                    if (_textoDecisao.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text('Decisão: ', style: TextStyle(fontSize: 12, color: Colors.black45)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _corDecisao.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(_textoDecisao, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _corDecisao)),
                          ),
                        ],
                      ),
                    ],
                    if (entrada.comentario != null && entrada.comentario!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(style: const TextStyle(fontSize: 12), children: [
                          const TextSpan(text: 'Comentário: ', style: TextStyle(color: Colors.black45)),
                          TextSpan(text: entrada.comentario!, style: const TextStyle(color: Colors.black54)),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _mesAbrev(int mes) {
    const meses = ['Jan','Fev','Mar','Abr','Mai','Jun','Jul','Ago','Set','Out','Nov','Dez'];
    return meses[mes - 1];
  }
}