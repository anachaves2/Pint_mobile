import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pint_mobile/models/badge_regular.dart';
import 'package:pint_mobile/models/requisitos.dart';
import 'package:pint_mobile/models/evidencia.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';

enum _Fase { selecionarBadge, carregarEvidencias }

class NovaCandidatura extends StatefulWidget {
  const NovaCandidatura({super.key});
  @override
  State<NovaCandidatura> createState() => _NovaCandidaturaState();
}

class _NovaCandidaturaState extends State<NovaCandidatura> {
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

  @override
  void initState() {
    super.initState();
    _carregarBadges();
  }

  Future<void> _carregarBadges() async {
    final badges = await DatabaseService.instance.getCatalogoBadges();
    if (mounted) setState(() { _badges = badges; _isLoadingBadges = false; });
  }

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
      _mostrarErro(resultado.erro ?? 'Erro ao criar candidatura.');
    }
  }

  Future<void> _escolherFicheiro(Requisito req) async {
    final resultado = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'zip', 'jpg', 'jpeg', 'png'],
    );
    if (resultado == null || resultado.files.single.path == null) return;
    final caminho = resultado.files.single.path!;
    setState(() => _ficheirosPendentes[req.id] = caminho);
    await _uploadEvidencia(req, caminho);
  }

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
      _mostrarErro(resultado.erro ?? 'Erro ao enviar evidência.');
    }
  }

  Future<void> _submeter() async {
    if (_numCandidatura == null) return;
    setState(() => _isSubmitting = true);
    final resultado = await APIService.instance.submeterCandidatura(_numCandidatura!);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (resultado.sucesso) {
      Navigator.pushReplacementNamed(context, AppConstants.routeCandidaturaSubmetida, arguments: _numCandidatura);
    } else {
      _mostrarErro(resultado.erro ?? 'Erro ao submeter candidatura.');
    }
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppConstants.corErro));
  }

  bool get _podeSubmeter {
    if (_requisitos.isEmpty) return true;
    return _requisitos.every((r) => _evidenciasGuardadas.containsKey(r.id));
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
        title: const Text('CANDIDATURAS',
            style: TextStyle(color: AppConstants.corPrimaria, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 1)),
        actions: [
          IconButton(
            icon: SvgPicture.asset('assets/icons/notificacoesprimaria.svg', height: 24,
                colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn)),
            onPressed: () => Navigator.pushNamed(context, AppConstants.routeNotificacoes),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.chevron_left, color: AppConstants.corPrimaria),
                ),
                const Text('Nova Candidatura',
                    style: TextStyle(color: AppConstants.corPrimaria, fontWeight: FontWeight.w600, fontSize: 14)),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.black12),
          Expanded(child: _fase == _Fase.selecionarBadge ? _buildFaseSelecionarBadge() : _buildFaseEvidencias()),
        ],
      ),
    );
  }

  Widget _buildFaseSelecionarBadge() {
    if (_isLoadingBadges) return const Center(child: CircularProgressIndicator(color: AppConstants.corPrimaria));
    return Column(
      children: [
        if (_badgeSelecionado != null)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(children: [
              _linhaInfo('Badge:', _badgeSelecionado!.nome),
              _linhaInfo('Service line:', _badgeSelecionado!.nomeServiceLine),
              _linhaInfo('Área:', _badgeSelecionado!.nomeArea),
              _linhaInfo('Nível:', _badgeSelecionado!.nomeNivel),
            ]),
          ),
        Expanded(
          child: _badges.isEmpty
              ? const Center(child: Text('Sem badges no catálogo.', style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _badges.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final b = _badges[i];
                    final selecionado = _badgeSelecionado?.id == b.id;
                    return GestureDetector(
                      onTap: () => setState(() => _badgeSelecionado = b),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: selecionado ? AppConstants.corPrimaria.withOpacity(0.06) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
                          border: selecionado ? Border.all(color: AppConstants.corPrimaria, width: 1.5) : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: Colors.orange[100], borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.military_tech, color: Colors.orange, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(b.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                  Text('${b.nomeNivel} · ${b.nomeArea}', style: const TextStyle(fontSize: 11, color: Colors.black45)),
                                ],
                              ),
                            ),
                            if (selecionado)
                              const Icon(Icons.check_circle, color: AppConstants.corPrimaria, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _badgeSelecionado != null && !_isLoadingBadges ? _criarCandidatura : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.corPrimaria,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.black12,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoadingBadges
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Continuar', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFaseEvidencias() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(children: [
            _linhaInfo('Badge:', _badgeSelecionado!.nome),
            _linhaInfo('Service line:', _badgeSelecionado!.nomeServiceLine),
            _linhaInfo('Área:', _badgeSelecionado!.nomeArea),
            _linhaInfo('Nível:', _badgeSelecionado!.nomeNivel),
          ]),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('REQUISITOS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45, letterSpacing: 0.5)),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _requisitos.isEmpty
              ? const Center(child: Text('Este badge não tem requisitos definidos.', style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemCount: _requisitos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => _buildCardRequisito(_requisitos[i]),
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _podeSubmeter && !_isSubmitting ? _submeter : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.corPrimaria,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.black12,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSubmitting
                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submeter', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardRequisito(Requisito req) {
    final temEvidencia = _evidenciasGuardadas.containsKey(req.id);
    final emUpload = _uploading[req.id] == true;
    final nomeFicheiro = temEvidencia
        ? _evidenciasGuardadas[req.id]!.pathFicheiro.split('/').last
        : (_ficheirosPendentes.containsKey(req.id) ? _ficheirosPendentes[req.id]!.split('/').last : null);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6, offset: const Offset(0, 2))],
        border: temEvidencia ? Border.all(color: AppConstants.corSucesso.withOpacity(0.4)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(req.nome, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          if (req.descricao != null && req.descricao!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(req.descricao!, style: const TextStyle(fontSize: 11, color: Colors.black38)),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: temEvidencia ? AppConstants.corSucesso.withOpacity(0.08) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: emUpload
                    ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: AppConstants.corPrimaria))
                    : Icon(
                        temEvidencia ? Icons.check_circle : Icons.insert_drive_file_outlined,
                        color: temEvidencia ? AppConstants.corSucesso : Colors.black26,
                        size: 24,
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nomeFicheiro ?? 'Clica para carregar ${req.nome}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: nomeFicheiro != null ? Colors.black54 : Colors.black38),
                ),
              ),
              GestureDetector(
                onTap: emUpload ? null : () => _escolherFicheiro(req),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: temEvidencia ? Colors.black.withOpacity(0.05) : AppConstants.corPrimaria,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    temEvidencia ? Icons.refresh : Icons.upload_outlined,
                    size: 18,
                    color: temEvidencia ? Colors.black45 : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _linhaInfo(String label, String valor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 90, child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.black45))),
          Expanded(child: Text(valor, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87))),
        ],
      ),
    );
  }
}