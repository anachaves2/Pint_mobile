import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pint_mobile/models/candidatura_badge.dart';
import 'package:pint_mobile/models/historico_candidatura.dart';
import 'package:pint_mobile/models/requisitos.dart';
import 'package:pint_mobile/models/evidencia.dart';
import 'package:pint_mobile/providers/candidatura_provider.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:pint_mobile/widgets/requisito_evidencia_tile.dart';
import 'package:pint_mobile/screens/camera/camera_screen.dart';
import 'package:go_router/go_router.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';
import 'package:pint_mobile/widgets/texto_traduzido.dart';

// ECRÃ DETALHES DA CANDIDATURA
// Segue os tokens D. Acrescentei o que faltava em relação à web: "Rever
// Candidatura" — quando o TM/SLL devolve a candidatura (aguardaAcaoConsultor),
// o consultor consegue reenviar evidências e submeter outra vez, sem sair
// deste ecrã. Antes disto não existia nenhuma ação possível aqui.

class DetalhesCandidatura extends ConsumerStatefulWidget {
  final int numCandidatura;
  const DetalhesCandidatura({super.key, required this.numCandidatura});

  @override
  ConsumerState<DetalhesCandidatura> createState() => _DetalhesCandidaturaState();
}

class _DetalhesCandidaturaState extends ConsumerState<DetalhesCandidatura> {
  CandidaturaBadge? _candidatura;
  List<HistoricoCandidatura> _historico = [];
  bool _isLoading = true;
  List<Requisito> _requisitos = [];
  Map<int, Evidencia> _evidencias = {};

  // ── Estado do modo "Rever Candidatura" ──
  bool _modoRevisao = false;
  final Map<int, String> _ficheirosPendentes = {};
  final Map<int, bool> _uploading = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final numCandidatura = widget.numCandidatura;
    final todasCandidaturas = await DatabaseService.instance.getCandidaturas();
    final candidatura = todasCandidaturas.where((c) => c.numCandidatura == numCandidatura).firstOrNull;
    final historico = await DatabaseService.instance.getHistorico(numCandidatura);
    final requisitos = candidatura != null
        ? await DatabaseService.instance.getRequisitos(candidatura.idBadgeRegular)
        : <Requisito>[];
    final listaEvidencias = await DatabaseService.instance.getEvidencias(numCandidatura);

    if (mounted) {
      setState(() {
        _candidatura = candidatura;
        _historico = historico;
        _requisitos = requisitos;
        _evidencias = {for (final e in listaEvidencias) e.idRequisito: e};
        _isLoading = false;
      });
    }

    await APIService.instance.sincronizarDetalhesCandidatura(numCandidatura);
    final todasAtual = await DatabaseService.instance.getCandidaturas();
    final candidaturaAtual = todasAtual.where((c) => c.numCandidatura == numCandidatura).firstOrNull;
    final historicoAtual = await DatabaseService.instance.getHistorico(numCandidatura);
    final requisitosAtual = candidaturaAtual != null
        ? await DatabaseService.instance.getRequisitos(candidaturaAtual.idBadgeRegular)
        : <Requisito>[];
    final evidenciasAtual = await DatabaseService.instance.getEvidencias(numCandidatura);

    if (mounted) {
      setState(() {
        _candidatura = candidaturaAtual;
        _historico = historicoAtual;
        _requisitos = requisitosAtual;
        _evidencias = {for (final e in evidenciasAtual) e.idRequisito: e};
      });
      ref.invalidate(candidaturasProvider);
    }
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await _carregar();
  }

  // ── Ações do modo de revisão ──

  Future<void> _escolherFicheiro(Requisito req) async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'zip', 'jpg', 'jpeg', 'png'],
    );
    final caminho = resultado?.files.single.path;
    if (caminho == null) return;
    setState(() => _ficheirosPendentes[req.id] = caminho);
    await _uploadEvidencia(req, caminho);
  }

  Future<void> _tirarFoto(Requisito req) async {
    final caminho = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    if (caminho == null) return;
    setState(() => _ficheirosPendentes[req.id] = caminho);
    await _uploadEvidencia(req, caminho);
  }

  Future<void> _uploadEvidencia(Requisito req, String caminho) async {
    setState(() => _uploading[req.id] = true);
    final resultado = await APIService.instance.uploadEvidencia(
      numCandidatura: widget.numCandidatura, idRequisito: req.id, filePath: caminho,
    );
    if (!mounted) return;
    if (resultado.sucesso) {
      final evidencias = await DatabaseService.instance.getEvidencias(widget.numCandidatura);
      setState(() {
        _evidencias = {for (final e in evidencias) e.idRequisito: e};
        _uploading[req.id] = false;
      });
    } else {
      setState(() => _uploading[req.id] = false);
      _mostrarErro(resultado.erro ?? ref.tr('mobile_detcand_erro_enviar_evidencia'));
    }
  }

  Future<void> _submeterRevisao() async {
    setState(() => _isSubmitting = true);
    final resultado = await APIService.instance.submeterCandidatura(widget.numCandidatura);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (resultado.sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.tr('mobile_detcand_reenviada_sucesso')), backgroundColor: D.ok),
      );
      setState(() => _modoRevisao = false);
      await _refresh();
    } else {
      _mostrarErro(resultado.erro ?? ref.tr('mobile_detcand_erro_reenviar'));
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: D.erro));
  }

  bool get _podeSubmeterRevisao {
    if (_requisitos.isEmpty) return true;
    return _requisitos.every((r) => _evidencias.containsKey(r.id));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: D.fundo,
      drawer: const CustomDrawer(),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: D.azul600))
          : _candidatura == null
              ? Center(child: Text(ref.t('mobile_detcand_nao_encontrada'), style: D.corpo))
              : RefreshIndicator(
                  color: D.azul600,
                  onRefresh: _refresh,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(D.e4, D.e2, D.e4, D.e5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCabecalho(),
                        if (_candidatura!.aguardaAcaoConsultor) ...[
                          const SizedBox(height: D.e3),
                          _buildAvisoRevisao(),
                        ],
                        if (_modoRevisao) ...[
                          const SizedBox(height: D.e5),
                          _buildSecaoRevisao(),
                        ] else ...[
                          if (_requisitos.isNotEmpty) ...[
                            const SizedBox(height: D.e5),
                            Text(ref.t('mobile_detcand_requisitos_submetidos'), style: D.etiqueta),
                            const SizedBox(height: D.e3),
                            ..._requisitos.map((req) => _buildCardRequisito(req)),
                          ],
                        ],
                        const SizedBox(height: D.e5),
                        Text(ref.t('mobile_detcand_timeline'), style: D.etiqueta),
                        const SizedBox(height: D.e3),
                        _buildTimeline(),
                      ],
                    ),
                  ),
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
      title: Text(ref.t('mobile_detcand_titulo'), style: D.tituloPagina),
      actions: [
        IconButton(
          icon: SvgPicture.asset('assets/icons/notificacoesprimaria.svg', height: 24,
              colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn)),
          onPressed: () => context.push(AppConstants.routeNotificacoes),
        ),
      ],
    );
  }

  Widget _buildCabecalho() {
    final c = _candidatura!;
    final aprovada = c.aprovada;
    final rejeitada = c.rejeitada;
    final cor = aprovada ? D.ok : (rejeitada ? D.erro : D.tinta30);
    final corFundo = aprovada ? D.okBg : (rejeitada ? D.erroBg : D.fundoAlt);
    final texto = aprovada ? ref.t('mobile_cand_tab_aprovados_singular') : (rejeitada ? ref.t('mobile_cand_tab_rejeitados_singular') : '—');

    return CardSimples(
      child: Column(
        children: [
          _linhaInfo(ref.t('mobile_detcand_badge_label'), c.nomeBadge),
          if (c.nomeNivel != null) _linhaInfo(ref.t('mobile_detcand_nivel_label'), c.nomeNivel!),
          if (c.estaConcluida)
            Padding(
              padding: const EdgeInsets.only(top: D.e2),
              child: Row(
                children: [
                  SizedBox(width: 100, child: Text(ref.t('mobile_detcand_decisao_final'), style: D.legenda)),
                  ChipEstado(texto: texto, cor: cor, corFundo: corFundo),
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
          SizedBox(width: 100, child: Text(label, style: D.legenda)),
          Expanded(child: Text(valor, style: D.tituloCard)),
        ],
      ),
    );
  }

  // Banner de aviso + botão que ativa o modo de revisão
  Widget _buildAvisoRevisao() {
    return Container(
      padding: const EdgeInsets.all(D.e4),
      decoration: BoxDecoration(color: D.avisoBg, borderRadius: BorderRadius.circular(D.rLg)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: D.aviso, size: 18),
              const SizedBox(width: D.e2),
              Expanded(
                child: Text(
                  ref.t('mobile_detcand_aviso_devolvida'),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: D.aviso),
                ),
              ),
            ],
          ),
          if (!_modoRevisao) ...[
            const SizedBox(height: D.e3),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _modoRevisao = true),
                icon: const Icon(Icons.refresh, size: 18),
                label: Text(ref.t('mobile_detcand_rever_candidatura')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: D.aviso,
                  side: const BorderSide(color: D.aviso),
                  padding: const EdgeInsets.symmetric(vertical: D.e2 + 2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Modo de revisão: reenviar evidências + submeter
  Widget _buildSecaoRevisao() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(ref.t('mobile_geral_requisitos_maiusc'), style: D.etiqueta),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _modoRevisao = false),
              child: Text(ref.t('mobile_geral_cancelar'), style: const TextStyle(color: D.tinta30, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: D.e2),
        if (_requisitos.isEmpty)
          CardSimples(child: Center(child: Text(ref.t('mobile_detcand_sem_requisitos'), style: D.legenda)))
        else
          for (final req in _requisitos)
            Padding(
              padding: const EdgeInsets.only(bottom: D.e2),
              child: RequisitoEvidenciaTile(
                requisito: req,
                temEvidencia: _evidencias.containsKey(req.id),
                emUpload: _uploading[req.id] == true,
                nomeFicheiro: _evidencias[req.id]?.pathFicheiro.split('/').last ??
                    _ficheirosPendentes[req.id]?.split('/').last,
                onEscolherFicheiro: () => _escolherFicheiro(req),
                onTirarFoto: () => _tirarFoto(req),
              ),
            ),
        const SizedBox(height: D.e3),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: (_podeSubmeterRevisao && !_isSubmitting) ? _submeterRevisao : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: D.azul600,
              foregroundColor: Colors.white,
              disabledBackgroundColor: D.fundoAlt,
              padding: const EdgeInsets.symmetric(vertical: D.e3 + 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
            ),
            child: _isSubmitting
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(ref.t('mobile_detcand_submeter'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
        ),
      ],
    );
  }

  // Mostra o estado de cada requisito quando NÃO está em modo de revisão
  Widget _buildCardRequisito(Requisito req) {
    final evidencia = _evidencias[req.id];

    Color cor;
    IconData icone;
    String texto;

    if (evidencia == null) {
      cor = D.aviso;
      icone = Icons.upload_file_outlined;
      texto = ref.t('mobile_detcand_sem_evidencia');
    } else if (evidencia.aprovada) {
      cor = D.ok;
      icone = Icons.check_circle_outline;
      texto = ref.t('mobile_cand_tab_aprovados_singular');
    } else if (evidencia.rejeitada) {
      cor = D.erro;
      icone = Icons.cancel_outlined;
      texto = ref.t('mobile_cand_tab_rejeitados_singular');
    } else {
      cor = D.azul600;
      icone = Icons.hourglass_empty_outlined;
      texto = ref.t('mobile_detcand_pendente');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: D.e2),
      child: CardSimples(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icone, color: cor, size: 18),
                const SizedBox(width: D.e2),
                Expanded(child: Text(req.nome, style: D.tituloCard)),
                ChipEstado(texto: texto, cor: cor, corFundo: cor.withValues(alpha: 0.1)),
              ],
            ),
            if (req.descricao != null && req.descricao!.isNotEmpty) ...[
              const SizedBox(height: 6),
              TextoTraduzido(texto: req.descricao, style: D.legenda.copyWith(height: 1.4)),
            ],
            if (evidencia != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.attach_file, size: 12, color: D.tinta30),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(evidencia.pathFicheiro.split('/').last, style: D.legenda.copyWith(fontSize: 11), overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    if (_historico.isEmpty) {
      return CardSimples(child: Center(child: Text(ref.t('mobile_detcand_sem_historico'), style: D.legenda)));
    }
    final invertido = _historico.reversed.toList();
    return Column(
      children: List.generate(invertido.length, (i) => _ItemTimeline(entrada: invertido[i], isLast: i == invertido.length - 1)),
    );
  }
}

class _ItemTimeline extends ConsumerWidget {
  final HistoricoCandidatura entrada;
  final bool isLast;
  const _ItemTimeline({required this.entrada, required this.isLast});

  Color get _corPonto {
    switch (entrada.idEstadoAtual) {
      case 5: return D.ok;
      case 6: return D.erro;
      case 2: case 4: return D.aviso;
      default: return D.azul600;
    }
  }

  String _textoDecisao(WidgetRef ref) {
    switch (entrada.idEstadoAtual) {
      case 5: return ref.t('mobile_cand_tab_aprovados_singular');
      case 6: return ref.t('mobile_cand_tab_rejeitados_singular');
      case 2: case 4: return ref.t('mobile_detcand_incorreto');
      case 1: case 3: return ref.t('mobile_detcand_correto');
      default: return '';
    }
  }

  Color get _corDecisao {
    switch (entrada.idEstadoAtual) {
      case 5: case 1: case 3: return D.ok;
      case 6: case 2: case 4: return D.erro;
      default: return D.tinta30;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hora = '${entrada.dataAlteracao.day} ${_mesAbrev(entrada.dataAlteracao.month, ref)} ${entrada.dataAlteracao.year} '
        '${entrada.dataAlteracao.hour.toString().padLeft(2, '0')}:${entrada.dataAlteracao.minute.toString().padLeft(2, '0')}';
    final textoDecisao = _textoDecisao(ref);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: _corPonto, shape: BoxShape.circle)),
              if (!isLast) Expanded(child: Container(width: 2, color: D.fundoAlt)),
            ],
          ),
          const SizedBox(width: D.e3),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: D.e4),
              child: CardSimples(
                padding: const EdgeInsets.all(D.e3),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 11, color: D.tinta30),
                        const SizedBox(width: 4),
                        Text(hora, style: D.legenda.copyWith(fontSize: 11)),
                        const Spacer(),
                        ChipEstado(texto: entrada.nomeEstadoAtual, cor: D.tinta50, corFundo: D.fundoAlt),
                      ],
                    ),
                    if (textoDecisao.isNotEmpty) ...[
                      const SizedBox(height: D.e2),
                      Row(
                        children: [
                          Text('${ref.t('mobile_detcand_decisao')} ', style: D.legenda),
                          ChipEstado(texto: textoDecisao, cor: _corDecisao, corFundo: _corDecisao.withValues(alpha: 0.12)),
                        ],
                      ),
                    ],
                    if (entrada.comentario != null && entrada.comentario!.isNotEmpty) ...[
                      const SizedBox(height: D.e2),
                      RichText(
                        text: TextSpan(style: D.legenda.copyWith(fontSize: 12), children: [
                          TextSpan(text: '${ref.t('mobile_detcand_comentario')} ', style: const TextStyle(color: D.tinta30)),
                        ]),
                      ),
                      TextoTraduzido(texto: entrada.comentario, style: D.legenda.copyWith(fontSize: 12, color: D.tinta50)),
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

  String _mesAbrev(int mes, WidgetRef ref) {
    final chaves = [
      'mobile_mes_jan', 'mobile_mes_fev', 'mobile_mes_mar', 'mobile_mes_abr',
      'mobile_mes_mai', 'mobile_mes_jun', 'mobile_mes_jul', 'mobile_mes_ago',
      'mobile_mes_set', 'mobile_mes_out', 'mobile_mes_nov', 'mobile_mes_dez',
    ];
    return ref.t(chaves[mes - 1]);
  }
}