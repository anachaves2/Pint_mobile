import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pint_mobile/models/consultor.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:go_router/go_router.dart';
import 'package:pint_mobile/screens/camera/camera_screen.dart';
import 'package:pint_mobile/providers/utilizador_provider.dart';
import 'package:pint_mobile/providers/badges_provider.dart';
import 'package:pint_mobile/providers/candidatura_provider.dart';
import 'package:pint_mobile/providers/objetivos_resumo_provider.dart';
import 'package:pint_mobile/providers/badges_recomendados_provider.dart';
import 'package:pint_mobile/widgets/saudacao_evento.dart';
import 'package:pint_mobile/widgets/celebracao_marco.dart';

// ============================================================================
// DefinicoesScreen
//
// Paridade com a web (components/Definicoes.jsx): 3 separadores —
//   1. Editar Perfil     — foto, telefone, LinkedIn, área
//   2. Password          — alterar password
//   3. Política de Privacidade — texto + estado do consentimento RGPD,
//                          revogável (liga ao ecrã aceitar_rgpd_screen.dart)
//
// O idioma (PT/EN/ES) é extra do mobile e mantém-se.
// ============================================================================

enum _Seccao { perfil, password, privacidade }

class DefinicoesScreen extends ConsumerStatefulWidget {
  const DefinicoesScreen({super.key});

  @override
  ConsumerState<DefinicoesScreen> createState() => _DefinicoesScreenState();
}

class _DefinicoesScreenState extends ConsumerState<DefinicoesScreen> {
  Consultor? _consultor;
  bool _isLoading = true;
  _Seccao _seccao = _Seccao.perfil;

  // ── Perfil ──
  final _telefoneController = TextEditingController();
  final _linkedinController = TextEditingController();
  String _linguaSelecionada = 'pt';
  int? _idAreaSelecionada;
  String? _nomeAreaSelecionada;
  List<_Area> _areas = [];
  bool _aGuardarPerfil = false;
  bool _aEnviarFoto = false;

  // ── Password ──
  final _passwordAtualController = TextEditingController();
  final _novaPasswordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();
  bool _aGuardarPassword = false;

  // ── Privacidade ──
  String? _politica;
  bool _aCarregarPolitica = false;
  bool _aAtualizarRgpd = false;

  String? _erro;
  String? _sucesso;

  static const _linguas = [
    _Lingua(codigo: 'pt', nome: 'Português', bandeira: '🇵🇹'),
    _Lingua(codigo: 'en', nome: 'English', bandeira: '🇬🇧'),
    _Lingua(codigo: 'es', nome: 'Español', bandeira: '🇪🇸'),
  ];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  @override
  void dispose() {
    _telefoneController.dispose();
    _linkedinController.dispose();
    _passwordAtualController.dispose();
    _novaPasswordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _carregarDados() async {
    final consultor = await DatabaseService.instance.getUser();
    final areasRaw = await APIService.instance.getAreas();
    final areas = areasRaw.map((m) => _Area(id: m['id'] as int, nome: m['nome'] as String)).toList();

    if (!mounted) return;
    setState(() {
      _consultor = consultor;
      _telefoneController.text = consultor?.telefone ?? '';
      _linkedinController.text = consultor?.urlLinkedin ?? '';
      _linguaSelecionada = consultor?.linguaPadrao ?? 'pt';
      _idAreaSelecionada = consultor?.idArea;
      _nomeAreaSelecionada = consultor?.nomeArea;
      _areas = areas;
      _isLoading = false;
    });
  }

  // Diálogo de confirmação reutilizável — usado antes de qualquer alteração
  // que fique guardada (perfil, password, foto, idioma).
  Future<bool> _confirmar({
    required String titulo,
    required String mensagem,
    String textoConfirmar = 'Sim, guardar',
    bool destrutivo = false,
  }) async {
    final resposta = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, color: D.azul600)),
        content: Text(mensagem, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: D.tinta50)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(textoConfirmar,
                style: TextStyle(color: destrutivo ? D.erro : D.azul600, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    return resposta == true;
  }

  void _limparMensagens() => setState(() {
        _erro = null;
        _sucesso = null;
      });

  // Reconstrói o Consultor mantendo TODOS os campos — em especial
  // nomeServiceLine, aceitouRgpd e primeiroAcesso, que se perdiam antes.
  Consultor _consultorComAlteracoes({
    String? telefone,
    String? urlLinkedin,
    String? urlFoto,
    String? linguaPadrao,
    int? idArea,
    String? nomeArea,
    bool? aceitouRgpd,
  }) {
    final c = _consultor!;
    return Consultor(
      id: c.id,
      nome: c.nome,
      email: c.email,
      telefone: telefone ?? c.telefone,
      urlLinkedin: urlLinkedin ?? c.urlLinkedin,
      urlFoto: urlFoto ?? c.urlFoto,
      dataMembro: c.dataMembro,
      linguaPadrao: linguaPadrao ?? c.linguaPadrao,
      idArea: idArea ?? c.idArea,
      nomeArea: nomeArea ?? c.nomeArea,
      nomeServiceLine: c.nomeServiceLine,
      idLearningPath: c.idLearningPath,
      nomeLearningPath: c.nomeLearningPath,
      totalPontos: c.totalPontos,
      posicaoRanking: c.posicaoRanking,
      aceitouRgpd: aceitouRgpd ?? c.aceitouRgpd,
      primeiroAcesso: c.primeiroAcesso,
    );
  }

  // ── Guardar perfil (telefone, LinkedIn, área) ──
  Future<void> _guardarPerfil() async {
    _limparMensagens();

    if (!await _confirmar(
      titulo: 'Guardar alterações?',
      mensagem: 'Os dados do teu perfil vão ser atualizados.',
    )) return;
    if (!mounted) return;

    setState(() => _aGuardarPerfil = true);

    final atualizado = _consultorComAlteracoes(
      telefone: _telefoneController.text.trim(),
      urlLinkedin: _linkedinController.text.trim(),
      idArea: _idAreaSelecionada,
      nomeArea: _nomeAreaSelecionada,
    );

    final resultado = await APIService.instance.atualizarPerfil(atualizado);
    if (!mounted) return;
    setState(() {
      _aGuardarPerfil = false;
      if (resultado.sucesso) {
        _consultor = atualizado;
        _sucesso = 'Perfil atualizado com sucesso!';
      } else {
        _erro = resultado.erro ?? 'Não foi possível guardar as alterações.';
      }
    });
    if (resultado.sucesso) ref.invalidate(utilizadorProvider);
  }

  // ── Alterar foto (câmara -> upload) ──
  Future<void> _alterarFotoPerfil() async {
    final caminho = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    if (caminho == null || !mounted) return;

    _limparMensagens();

    if (!await _confirmar(
      titulo: 'Alterar foto de perfil?',
      mensagem: 'Esta foto vai substituir a atual em toda a plataforma.',
      textoConfirmar: 'Sim, alterar',
    )) return;
    if (!mounted) return;

    setState(() => _aEnviarFoto = true);

    final resultado = await APIService.instance.uploadFotoPerfil(caminho);
    if (!mounted) return;

    if (resultado.sucesso) {
      final atualizado = _consultorComAlteracoes(urlFoto: resultado.urlFoto);
      await DatabaseService.instance.updateUser(atualizado);
      if (!mounted) return;
      setState(() {
        _consultor = atualizado;
        _aEnviarFoto = false;
        _sucesso = 'Foto atualizada com sucesso!';
      });
      ref.invalidate(utilizadorProvider);
    } else {
      setState(() {
        _aEnviarFoto = false;
        _erro = resultado.erro ?? 'Não foi possível enviar a foto.';
      });
    }
  }

  // ── Guardar idioma ──
  Future<void> _guardarIdioma(String codigo) async {
    if (codigo == _linguaSelecionada) return;

    if (!await _confirmar(
      titulo: 'Alterar idioma?',
      mensagem: 'O idioma preferido da tua conta vai ser atualizado.',
      textoConfirmar: 'Sim, alterar',
    )) return;
    if (!mounted) return;

    setState(() => _linguaSelecionada = codigo);
    final atualizado = _consultorComAlteracoes(linguaPadrao: codigo);
    await DatabaseService.instance.updateUser(atualizado);
    if (mounted) setState(() => _consultor = atualizado);
  }

  // ── Alterar password ──
  Future<void> _guardarPassword() async {
    _limparMensagens();

    final atual = _passwordAtualController.text;
    final nova = _novaPasswordController.text;
    final confirmar = _confirmarPasswordController.text;

    if (atual.isEmpty || nova.isEmpty || confirmar.isEmpty) {
      setState(() => _erro = 'Preenche os 3 campos.');
      return;
    }
    if (nova != confirmar) {
      setState(() => _erro = 'A nova password e a confirmação não coincidem.');
      return;
    }
    if (nova.length < 6) {
      setState(() => _erro = 'A nova password deve ter pelo menos 6 caracteres.');
      return;
    }

    if (!await _confirmar(
      titulo: 'Alterar password?',
      mensagem: 'Vais precisar da nova password no próximo início de sessão.',
      textoConfirmar: 'Sim, alterar',
    )) return;
    if (!mounted) return;

    setState(() => _aGuardarPassword = true);
    final resultado = await APIService.instance.alterarPassword(
      passwordAtual: atual,
      novaPassword: nova,
    );
    if (!mounted) return;

    setState(() {
      _aGuardarPassword = false;
      if (resultado.sucesso) {
        _passwordAtualController.clear();
        _novaPasswordController.clear();
        _confirmarPasswordController.clear();
        _sucesso = 'Password alterada com sucesso!';
      } else {
        _erro = resultado.erro ?? 'Não foi possível alterar a password.';
      }
    });
  }

  // ── Política de privacidade (carrega só quando se abre o separador) ──
  Future<void> _carregarPolitica() async {
    if (_politica != null) return;
    setState(() => _aCarregarPolitica = true);
    final texto = await APIService.instance.getPoliticaPrivacidade();
    if (!mounted) return;
    setState(() {
      _politica = texto ?? '';
      _aCarregarPolitica = false;
    });
  }

  // ── Aceitar / revogar consentimento RGPD ──
  Future<void> _alternarConsentimentoRgpd() async {
    _limparMensagens();
    final novoValor = !(_consultor?.aceitouRgpd ?? true);

    if (!novoValor) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Revogar consentimento?', style: TextStyle(fontWeight: FontWeight.bold, color: D.azul600)),
          content: const Text(
            'Se revogares, vais ter de aceitar novamente a Política de Privacidade no próximo login.',
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: D.tinta50))),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Sim, revogar', style: TextStyle(color: D.erro, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      if (confirmar != true || !mounted) return;
    }

    setState(() => _aAtualizarRgpd = true);
    final resultado = await APIService.instance.atualizarConsentimentoRgpd(novoValor);
    if (!mounted) return;

    setState(() {
      _aAtualizarRgpd = false;
      if (resultado.sucesso) {
        _consultor = _consultorComAlteracoes(aceitouRgpd: novoValor);
        _sucesso = novoValor
            ? 'Consentimento RGPD aceite com sucesso.'
            : 'Consentimento revogado. Terás de o aceitar no próximo login.';
      } else {
        _erro = resultado.erro ?? 'Não foi possível atualizar o consentimento.';
      }
    });
    if (resultado.sucesso) ref.invalidate(utilizadorProvider);
  }

  // ── Logout ──
  Future<void> _terminarSessao() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminar sessão', style: TextStyle(fontWeight: FontWeight.bold, color: D.azul600)),
        content: const Text('Pretende terminar a sua sessão?', style: TextStyle(fontSize: 13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar', style: TextStyle(color: D.tinta50))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: D.azul600),
            child: const Text('Terminar sessão'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      ref.read(utilizadorProvider.notifier).limpar();
      ref.read(badgesProvider.notifier).limpar();
      ref.read(candidaturasProvider.notifier).limpar();
      ref.read(objetivosResumoProvider.notifier).limpar();
      ref.read(badgesRecomendadosProvider.notifier).limpar();
      SaudacaoEvento.limpar();
      CelebracaoMarco.limpar();
      await APIService.instance.logout();
      if (mounted) context.go(AppConstants.routeLanding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: D.fundo,
      drawer: const CustomDrawer(),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: D.azul600))
          : _consultor == null
              ? const Center(child: Text('Erro ao carregar dados.', style: D.corpo))
              : _buildBody(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
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
      title: const Text('DEFINIÇÕES', style: D.tituloPagina),
      actions: [
        IconButton(
          icon: SvgPicture.asset('assets/icons/notificacoesprimaria.svg', height: 24,
              colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn)),
          onPressed: () => context.push(AppConstants.routeNotificacoes),
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(D.e4, D.e2, D.e4, D.e5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAvatar(),
          const SizedBox(height: D.e5),
          _buildTabs(),
          const SizedBox(height: D.e4),
          if (_erro != null) _buildMensagem(_erro!, D.erro, D.erroBg),
          if (_sucesso != null) _buildMensagem(_sucesso!, D.ok, D.okBg),
          switch (_seccao) {
            _Seccao.perfil => _buildSeccaoPerfil(),
            _Seccao.password => _buildSeccaoPassword(),
            _Seccao.privacidade => _buildSeccaoPrivacidade(),
          },
          const SizedBox(height: D.e5),
          ElevatedButton(
            onPressed: _terminarSessao,
            style: ElevatedButton.styleFrom(
              backgroundColor: D.azul600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: D.e3 + 2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
            ),
            child: const Text('Terminar Sessão', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: D.e3),
          Center(child: Text('BadgeBoost v1.0.0', style: D.legenda.copyWith(fontSize: 12))),
        ],
      ),
    );
  }

  Widget _buildMensagem(String texto, Color cor, Color fundo) {
    return Container(
      margin: const EdgeInsets.only(bottom: D.e3),
      padding: const EdgeInsets.all(D.e3),
      decoration: BoxDecoration(color: fundo, borderRadius: BorderRadius.circular(D.rSm)),
      child: Text(texto, style: TextStyle(color: cor, fontSize: 13)),
    );
  }

  Widget _buildTabs() {
    final tabs = {
      _Seccao.perfil: 'Perfil',
      _Seccao.password: 'Password',
      _Seccao.privacidade: 'Privacidade',
    };
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: D.superficie, borderRadius: BorderRadius.circular(D.rSm), boxShadow: D.elev1),
      child: Row(
        children: tabs.entries.map((e) {
          final ativo = _seccao == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => _seccao = e.key);
                _limparMensagens();
                if (e.key == _Seccao.privacidade) _carregarPolitica();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: ativo ? D.azul600 : Colors.transparent,
                  borderRadius: BorderRadius.circular(D.rSm - 2),
                ),
                child: Text(e.value, textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: ativo ? Colors.white : D.tinta30)),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Avatar ───────────────────────────────────────────────────────────────

  Widget _buildAvatar() {
    final inicial = _consultor!.nome.isNotEmpty ? _consultor!.nome[0].toUpperCase() : '?';
    final urlFoto = AppConstants.resolverUrlFicheiro(_consultor!.urlFoto);

    return Column(
      children: [
        Container(
          width: 88,
          height: 88,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: D.azul100),
          child: urlFoto != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: urlFoto,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2, color: D.azul600)),
                    errorWidget: (ctx, url, err) => Center(child: Text(inicial, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: D.azul600))),
                  ),
                )
              : Center(child: Text(inicial, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: D.azul600))),
        ),
        const SizedBox(height: D.e2),
        GestureDetector(
          onTap: _aEnviarFoto ? null : _alterarFotoPerfil,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: D.e3, vertical: 5),
            decoration: BoxDecoration(color: D.azul100, borderRadius: BorderRadius.circular(999)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_aEnviarFoto)
                  const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: D.azul600))
                else
                  const Icon(Icons.camera_alt_outlined, size: 14, color: D.azul600),
                const SizedBox(width: 5),
                Text(_aEnviarFoto ? 'A enviar...' : 'Alterar foto',
                    style: const TextStyle(fontSize: 12, color: D.azul600, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
        const SizedBox(height: D.e3),
        Text(_consultor!.nome, style: D.tituloSeccao.copyWith(fontSize: 18)),
        Text(_nomeAreaSelecionada ?? _consultor!.nomeArea ?? '', style: D.legenda),
      ],
    );
  }

  // ─── Secção Perfil ────────────────────────────────────────────────────────

  Widget _buildSeccaoPerfil() {
    return CardSimples(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('Telefone'),
          TextField(controller: _telefoneController, keyboardType: TextInputType.phone, decoration: _inputDecoration('+351 ...')),
          const SizedBox(height: D.e3),

          _label('LinkedIn'),
          TextField(controller: _linkedinController, decoration: _inputDecoration('https://linkedin.com/in/...')),
          const SizedBox(height: D.e3),

          _label('Área'),
          _buildAreaDropdown(),
          const SizedBox(height: D.e3),

          _label('Idioma'),
          _buildIdiomaDropdown(),
          const SizedBox(height: D.e4),

          ElevatedButton(
            onPressed: _aGuardarPerfil ? null : _guardarPerfil,
            style: ElevatedButton.styleFrom(
              backgroundColor: D.azul600,
              foregroundColor: Colors.white,
              disabledBackgroundColor: D.fundoAlt,
              padding: const EdgeInsets.symmetric(vertical: D.e3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
            ),
            child: _aGuardarPerfil
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Guardar Alterações', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── Secção Password ──────────────────────────────────────────────────────

  Widget _buildSeccaoPassword() {
    return CardSimples(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _label('Password Atual'),
          TextField(controller: _passwordAtualController, obscureText: true, decoration: _inputDecoration('')),
          const SizedBox(height: D.e3),

          _label('Nova Password'),
          TextField(controller: _novaPasswordController, obscureText: true, decoration: _inputDecoration('Mínimo 6 caracteres')),
          const SizedBox(height: D.e3),

          _label('Confirmar Nova Password'),
          TextField(controller: _confirmarPasswordController, obscureText: true, decoration: _inputDecoration('')),
          const SizedBox(height: D.e4),

          ElevatedButton(
            onPressed: _aGuardarPassword ? null : _guardarPassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: D.azul600,
              foregroundColor: Colors.white,
              disabledBackgroundColor: D.fundoAlt,
              padding: const EdgeInsets.symmetric(vertical: D.e3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
            ),
            child: _aGuardarPassword
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Alterar Password', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  // ─── Secção Privacidade ───────────────────────────────────────────────────

  Widget _buildSeccaoPrivacidade() {
    final aceitou = _consultor?.aceitouRgpd ?? true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CardSimples(
          child: _aCarregarPolitica
              ? const Center(child: Padding(padding: EdgeInsets.all(D.e3), child: CircularProgressIndicator(color: D.azul600)))
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: SingleChildScrollView(
                    child: Text(
                      (_politica?.isNotEmpty ?? false) ? _politica! : 'Política de privacidade não disponível de momento.',
                      style: D.corpo.copyWith(height: 1.7),
                    ),
                  ),
                ),
        ),
        const SizedBox(height: D.e3),
        CardSimples(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(aceitou ? Icons.check_circle : Icons.warning_amber_rounded,
                      color: aceitou ? D.ok : D.aviso, size: 20),
                  const SizedBox(width: D.e2),
                  Expanded(
                    child: Text(
                      aceitou ? 'Consentimento RGPD aceite' : 'Consentimento RGPD não aceite',
                      style: D.tituloCard,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: D.e3),
              OutlinedButton(
                onPressed: _aAtualizarRgpd ? null : _alternarConsentimentoRgpd,
                style: OutlinedButton.styleFrom(
                  foregroundColor: aceitou ? D.erro : D.azul600,
                  side: BorderSide(color: aceitou ? D.erro : D.azul600),
                  padding: const EdgeInsets.symmetric(vertical: D.e3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
                ),
                child: _aAtualizarRgpd
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: D.azul600))
                    : Text(aceitou ? 'Revogar consentimento' : 'Aceitar agora',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
              if (!aceitou) ...[
                const SizedBox(height: D.e2),
                Text('Terás de aceitar a Política de Privacidade no próximo login.',
                    style: D.legenda.copyWith(fontSize: 12)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ─── Auxiliares ───────────────────────────────────────────────────────────

  Widget _label(String texto) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(texto, style: D.tituloCard.copyWith(fontSize: 13)),
      );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: D.tinta30, fontSize: 13),
        filled: true,
        fillColor: D.fundoAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: D.e3, vertical: D.e3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(D.rSm), borderSide: BorderSide.none),
      );

  Widget _buildAreaDropdown() {
    // A área é definida no registo (ou pelo Admin/TM depois) — o consultor só
    // a consulta, não a edita. O Web já fazia isto assim (Perfil.jsx mostra
    // só texto); o mobile tinha ficado com um dropdown editável por engano.
    return _dropdownShell(child: Text(_consultor?.nomeArea ?? '—', style: D.corpo));
  }

  Widget _buildIdiomaDropdown() {
    final atual = _linguas.firstWhere((l) => l.codigo == _linguaSelecionada, orElse: () => _linguas.first);
    return _dropdownShell(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: atual.codigo,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: D.azul600),
          style: const TextStyle(fontSize: 14, color: D.tinta),
          onChanged: (codigo) {
            if (codigo != null) _guardarIdioma(codigo);
          },
          items: _linguas.map((l) => DropdownMenuItem(value: l.codigo, child: Text('${l.bandeira}  ${l.nome}'))).toList(),
        ),
      ),
    );
  }

  Widget _dropdownShell({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: D.e3, vertical: 2),
        decoration: BoxDecoration(color: D.fundoAlt, borderRadius: BorderRadius.circular(D.rSm)),
        child: child,
      );
}

// ── Modelos auxiliares internos ──

class _Area {
  final int id;
  final String nome;
  const _Area({required this.id, required this.nome});
}

class _Lingua {
  final String codigo;
  final String nome;
  final String bandeira;
  const _Lingua({required this.codigo, required this.nome, required this.bandeira});
}