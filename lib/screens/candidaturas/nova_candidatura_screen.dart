import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pint_mobile/models/badge_regular.dart';
import 'package:pint_mobile/models/requisitos.dart';
import 'package:pint_mobile/models/evidencia.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:pint_mobile/widgets/requisito_evidencia_tile.dart';
import 'package:go_router/go_router.dart';
import 'package:pint_mobile/screens/camera/camera_screen.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';

// O ecrã tem 2 fases: seleccionar o badge e depois carregar as evidências
enum _Fase { selecionarBadge, carregarEvidencias }

class NovaCandidatura extends ConsumerStatefulWidget {
  /// Quando não null, o ecrã abre directamente no modo "continuar rascunho".
  final Map<String, dynamic>? rascunho;
  /// Quando não null (e sem rascunho), o ecrã salta logo para a fase de
  /// evidências com este badge — usado quando se vem do Catálogo e já se
  /// sabe exatamente a que badge se quer candidatar.
  final BadgeRegular? badgePreselecionado;
  const NovaCandidatura({super.key, this.rascunho, this.badgePreselecionado});
  @override
  ConsumerState<NovaCandidatura> createState() => _NovaCandidaturaState();
}

class _NovaCandidaturaState extends ConsumerState<NovaCandidatura> {
  _Fase _fase = _Fase.selecionarBadge;
  List<BadgeRegular> _badges = [];
  BadgeRegular? _badgeSelecionado;
  bool _isLoadingBadges = true;
  int? _numCandidatura;
  List<Requisito> _requisitos = [];
  Map<int, Evidencia> _evidenciasGuardadas = {};
  final Map<int, String> _ficheirosPendentes = {};
  final Map<int, bool> _uploading = {};
  bool _isSubmitting = false;
  bool _isCancelling = false;

  // Se true, o ecrã foi aberto para CONTINUAR um rascunho existente.
  // Caso contrário, é uma candidatura nova (fluxo original).
  bool _modoRascunho = false;

  final TextEditingController _pesquisaController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    // O parâmetro [rascunho] é passado directamente pelo route builder (app_routes.dart).
    // Evita depender de addPostFrameCallback + GoRouterState.of, que pode resolver null.
    if (widget.rascunho != null) {
      _carregarRascunho(widget.rascunho!);
    } else if (widget.badgePreselecionado != null) {
      _badgeSelecionado = widget.badgePreselecionado;
      _criarCandidatura();
    } else {
      _carregarBadges();
    }
  }

  @override
  void dispose() {
    _pesquisaController.dispose();
    super.dispose();
  }

  Future<void> _carregarBadges() async {
    var badges = await DatabaseService.instance.getCatalogoBadges();

    // Se o catálogo local ainda está vazio, vai buscá-lo à API — senão a
    // lista de badges a que te podes candidatar aparecia vazia.
    if (badges.isEmpty) {
      await APIService.instance.sincronizarCatalogo();
      badges = await DatabaseService.instance.getCatalogoBadges();
    }

    if (mounted) setState(() { _badges = badges; _isLoadingBadges = false; });
  }

  // Carrega um rascunho existente, encontra o badge no catálogo local pelo
  // idBadgeRegular, lê os requisitos e as evidências já guardadas, e salta
  // diretamente para a fase de carregamento de evidências.
  Future<void> _carregarRascunho(Map<String, dynamic> rascunho) async {
    final numCandidatura = (rascunho['numCandidatura'] ?? rascunho['num_candidatura']) as int?;
    final idBadge = (rascunho['idBadgeRegular'] ?? rascunho['id_badge_regular']) as int?;

    if (numCandidatura == null || idBadge == null) {
      if (mounted) {
        _mostrarErro('${ref.tr('mobile_novacand_rascunho_invalido')} (numCandidatura=$numCandidatura, idBadge=$idBadge).');
        setState(() => _isLoadingBadges = false);
      }
      return;
    }

    var badges = await DatabaseService.instance.getCatalogoBadges();

    // Mesmo fallback do _carregarBadges: se o catálogo local ainda está
    // vazio, vai buscá-lo à API. Sem isto, um rascunho válido falhava com
    // "Não foi possível carregar este rascunho" só porque o catálogo não
    // tinha sido sincronizado.
    if (badges.isEmpty) {
      await APIService.instance.sincronizarCatalogo();
      badges = await DatabaseService.instance.getCatalogoBadges();
    }

    BadgeRegular? badge;
    for (final b in badges) {
      if (b.id == idBadge) {
        badge = b;
        break;
      }
    }

    if (!mounted) return;

    if (badge == null) {
      _mostrarErro(ref.tr('mobile_novacand_erro_carregar_rascunho'));
      setState(() => _isLoadingBadges = false);
      return;
    }

    final requisitos = await DatabaseService.instance.getRequisitos(idBadge);
    final evidencias = await DatabaseService.instance.getEvidencias(numCandidatura);

    if (!mounted) return;
    setState(() {
      _modoRascunho = true;
      _numCandidatura = numCandidatura;
      _badgeSelecionado = badge;
      _requisitos = requisitos;
      _evidenciasGuardadas = { for (final e in evidencias) e.idRequisito: e };
      _fase = _Fase.carregarEvidencias; // salta direto para a fase 2
      _isLoadingBadges = false;
    });
  }

  // Cria a candidatura na API e avança para a fase de evidências
  Future<void> _criarCandidatura() async {
    if (_badgeSelecionado == null) return;
    setState(() => _isLoadingBadges = true);
    final resultado = await APIService.instance.criarCandidatura(_badgeSelecionado!.id);
    if (!mounted) return;
    if (resultado.numCandidatura != null) {
      final requisitos = await DatabaseService.instance.getRequisitos(_badgeSelecionado!.id);
      final evidencias = await DatabaseService.instance.getEvidencias(resultado.numCandidatura!);
      setState(() {
        _numCandidatura = resultado.numCandidatura;
        _requisitos = requisitos;
        _evidenciasGuardadas = { for (final e in evidencias) e.idRequisito: e };
        _fase = _Fase.carregarEvidencias;
        _isLoadingBadges = false;
      });
    } else {
      setState(() => _isLoadingBadges = false);
      _mostrarErro(resultado.erro ?? ref.tr('mobile_novacand_erro_criar'));
    }
  }

  // Abre o explorador de ficheiros para seleccionar uma evidência (PDF, imagem, ZIP)
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

  // Permite tirar uma foto com a câmara como evidência
  Future<void> _tirarFoto(Requisito req) async {
    final caminho = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    if (caminho == null) return;
    setState(() => _ficheirosPendentes[req.id] = caminho);
    await _uploadEvidencia(req, caminho);
  }

  // Faz upload da evidência para a API e actualiza o estado local
  Future<void> _uploadEvidencia(Requisito req, String caminho) async {
    if (_numCandidatura == null) return;
    setState(() => _uploading[req.id] = true);
    final resultado = await APIService.instance.uploadEvidencia(
      numCandidatura: _numCandidatura!, idRequisito: req.id, filePath: caminho,
    );
    if (!mounted) return;
    if (resultado.sucesso) {
      final evidencias = await DatabaseService.instance.getEvidencias(_numCandidatura!);
      setState(() {
        _evidenciasGuardadas = { for (final e in evidencias) e.idRequisito: e };
        _uploading[req.id] = false;
      });
    } else {
      setState(() => _uploading[req.id] = false);
      _mostrarErro(resultado.erro ?? ref.tr('mobile_detcand_erro_enviar_evidencia'));
    }
  }

  // Submete a candidatura — só disponível quando todos os requisitos têm evidência
  Future<void> _submeter() async {
    if (_numCandidatura == null) return;

    // Confirmação antes de submeter — depois disto a candidatura segue para
    // validação e as evidências deixam de poder ser alteradas.
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.tr('mobile_novacand_submeter_titulo'),
            style: const TextStyle(fontWeight: FontWeight.bold, color: D.azul600)),
        content: Text(
          '${ref.tr('mobile_novacand_submeter_texto1')} "${_badgeSelecionado?.nome ?? ''}".\n\n'
          '${ref.tr('mobile_novacand_submeter_texto2')}',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ref.tr('mobile_geral_cancelar'), style: const TextStyle(color: D.tinta50)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ref.tr('mobile_novacand_sim_submeter'),
                style: const TextStyle(color: D.azul600, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _isSubmitting = true);
    final resultado = await APIService.instance.submeterCandidatura(_numCandidatura!);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (resultado.sucesso) {
      context.go(AppConstants.routeCandidaturaSubmetida, extra: _numCandidatura);
    } else {
      _mostrarErro(resultado.erro ?? ref.tr('mobile_novacand_erro_submeter'));
    }
  }

  // Pede confirmação antes de cancelar, apaga a candidatura e as evidências
  Future<void> _cancelarCandidatura() async {
    if (_numCandidatura == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ref.tr('mobile_novacand_cancelar_titulo'), style: const TextStyle(fontWeight: FontWeight.bold, color: D.azul600)),
        content: Text(
          ref.tr('mobile_cand_apagar_rascunho_texto'),
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ref.tr('mobile_notif_nao'), style: const TextStyle(color: D.tinta50))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(ref.tr('mobile_novacand_sim_cancelar'), style: const TextStyle(color: D.erro, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;
    if (!mounted) return;

    setState(() => _isCancelling = true);
    final resultado = await APIService.instance.cancelarRascunho(_numCandidatura!);
    if (!mounted) return;
    setState(() => _isCancelling = false);

    if (resultado.sucesso) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ref.tr('mobile_novacand_cancelada')), backgroundColor: D.ok),
      );
      context.go(AppConstants.routeCandidaturas);
    } else {
      _mostrarErro(resultado.erro ?? ref.tr('mobile_novacand_erro_cancelar'));
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: D.erro));
  }

  // Só permite submeter se todos os requisitos tiverem evidência carregada
  bool get _podeSubmeter {
    if (_requisitos.isEmpty) return true;
    return _requisitos.every((r) => _evidenciasGuardadas.containsKey(r.id));
  }

  List<BadgeRegular> get _badgesFiltrados {
    if (_query.isEmpty) return _badges;
    final q = _query.toLowerCase();
    return _badges.where((b) =>
        b.nome.toLowerCase().contains(q) ||
        b.nomeNivel.toLowerCase().contains(q) ||
        (b.nomeArea?.toLowerCase().contains(q) ?? false)).toList();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppConstants.corPrimaria, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(_modoRascunho ? ref.t('mobile_novacand_continuar_titulo') : ref.t('mobile_novacand_nova_titulo'), style: D.tituloPagina),
        actions: [
          IconButton(
            icon: SvgPicture.asset('assets/icons/notificacoesprimaria.svg', height: 24,
                colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => context.push(AppConstants.routeNotificacoes),
          ),
        ],
      ),
      body: _fase == _Fase.selecionarBadge ? _buildFaseSelecionarBadge() : _buildFaseEvidencias(),
    );
  }

  // Fase 1: lista de badges disponíveis para o utilizador escolher
  Widget _buildFaseSelecionarBadge() {
    if (_isLoadingBadges) return const Center(child: CircularProgressIndicator(color: D.azul600));
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(D.e4, D.e3, D.e4, D.e2),
          child: Container(
            decoration: BoxDecoration(color: D.superficie, borderRadius: BorderRadius.circular(D.rMd), boxShadow: D.elev1),
            child: TextField(
              controller: _pesquisaController,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: ref.t('mobile_cand_pesquisar_badge_hint'),
                hintStyle: const TextStyle(color: D.tinta30, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: D.tinta30, size: 20),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: D.e3),
              ),
            ),
          ),
        ),
        Expanded(
          child: _badgesFiltrados.isEmpty
              ? Center(child: Text(ref.t('mobile_catalogo_vazio'), style: D.legenda))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(D.e4, D.e1, D.e4, D.e2),
                  itemCount: _badgesFiltrados.length,
                  itemBuilder: (context, i) {
                    final b = _badgesFiltrados[i];
                    final selecionado = _badgeSelecionado?.id == b.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: D.e2),
                      child: GestureDetector(
                        onTap: () => setState(() => _badgeSelecionado = b),
                        child: Container(
                          padding: const EdgeInsets.all(D.e3 + 2),
                          decoration: BoxDecoration(
                            color: selecionado ? D.azul100 : D.superficie,
                            borderRadius: BorderRadius.circular(D.rMd),
                            boxShadow: D.elev1,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: D.azul100, borderRadius: BorderRadius.circular(D.rSm)),
                                child: const Icon(Icons.military_tech, color: D.azul600, size: 22),
                              ),
                              const SizedBox(width: D.e3),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b.nome, style: D.tituloCard),
                                    Text('${b.nomeNivel} · ${b.nomeArea ?? '—'}', style: D.legenda),
                                  ],
                                ),
                              ),
                              if (selecionado) const Icon(Icons.check_circle, color: D.azul600, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(D.e4),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _badgeSelecionado != null && !_isLoadingBadges ? _criarCandidatura : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: D.azul600,
                foregroundColor: Colors.white,
                disabledBackgroundColor: D.fundoAlt,
                padding: const EdgeInsets.symmetric(vertical: D.e3 + 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
              ),
              child: _isLoadingBadges
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(ref.t('mobile_cand_continuar_botao'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ),
      ],
    );
  }

  // Fase 2: lista de requisitos com botões para carregar evidências
  Widget _buildFaseEvidencias() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(D.e4, D.e3, D.e4, D.e2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CardSimples(
                  child: Column(children: [
                    _linhaInfo(ref.t('mobile_detcand_badge_label'), _badgeSelecionado!.nome),
                    _linhaInfo(ref.t('mobile_novacand_service_line_label'), _badgeSelecionado!.nomeServiceLine ?? '—'),
                    _linhaInfo(ref.t('mobile_novacand_area_label'), _badgeSelecionado!.nomeArea ?? '—'),
                    _linhaInfo(ref.t('mobile_detcand_nivel_label'), _badgeSelecionado!.nomeNivel),
                  ]),
                ),
                const SizedBox(height: D.e4),
                Text(ref.t('mobile_geral_requisitos_maiusc'), style: D.etiqueta),
                const SizedBox(height: D.e2),
                if (_requisitos.isEmpty)
                  CardSimples(child: Center(child: Text(ref.t('mobile_novacand_sem_requisitos'), style: D.legenda)))
                else
                  for (final req in _requisitos)
                    Padding(
                      padding: const EdgeInsets.only(bottom: D.e2),
                      child: RequisitoEvidenciaTile(
                        requisito: req,
                        temEvidencia: _evidenciasGuardadas.containsKey(req.id),
                        emUpload: _uploading[req.id] == true,
                        nomeFicheiro: _evidenciasGuardadas[req.id]?.pathFicheiro.split('/').last ??
                            _ficheirosPendentes[req.id]?.split('/').last,
                        onEscolherFicheiro: () => _escolherFicheiro(req),
                        onTirarFoto: () => _tirarFoto(req),
                      ),
                    ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(D.e4),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (_isSubmitting || _isCancelling) ? null : _cancelarCandidatura,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: D.erro,
                    side: const BorderSide(color: D.erro),
                    padding: const EdgeInsets.symmetric(vertical: D.e3 + 2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
                  ),
                  child: _isCancelling
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: D.erro))
                      : Text(ref.t('mobile_geral_cancelar'), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
              const SizedBox(width: D.e3),
              Expanded(
                child: ElevatedButton(
                  onPressed: (_podeSubmeter && !_isSubmitting && !_isCancelling) ? _submeter : null,
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
          ),
        ),
      ],
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
}