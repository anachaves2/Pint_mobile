import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pint_mobile/models/consultor.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:go_router/go_router.dart';
import 'package:pint_mobile/screens/camera/camera_screen.dart';
import 'package:pint_mobile/providers/utilizador_provider.dart';
import 'package:pint_mobile/providers/badges_provider.dart';
import 'package:pint_mobile/providers/candidatura_provider.dart';

// ============================================================================
// DefinicoesScreen — Ecrã 54
//
// Permite ao consultor:
//   - Ver o seu avatar e nome
//   - Mudar de área (dropdown)
//   - Mudar o idioma (dropdown — PT/EN/ES)
//   - Navegar para "Alterar Password"
//   - Fazer logout
// ============================================================================

class DefinicoesScreen extends ConsumerStatefulWidget {
  const DefinicoesScreen({super.key});

  @override
  ConsumerState<DefinicoesScreen> createState() => _DefinicoesScreenState();
}

class _DefinicoesScreenState extends ConsumerState<DefinicoesScreen> {
  Consultor? _consultor;
  bool _isLoading = true;

  // Estado local dos dropdowns
  String _linguaSelecionada = 'pt';
  int? _idAreaSelecionada;
  String? _nomeAreaSelecionada;

  // Áreas disponíveis (carregadas da API)
  List<_Area> _areas = [];

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

  Future<void> _carregarDados() async {
    final consultor = await DatabaseService.instance.getUser();
    final areasRaw = await APIService.instance.getAreas();
    final areas = areasRaw
        .map((m) => _Area(id: m['id'] as int, nome: m['nome'] as String))
        .toList();

    if (mounted) {
      setState(() {
        _consultor = consultor;
        _linguaSelecionada = consultor?.linguaPadrao ?? 'pt';
        _idAreaSelecionada = consultor?.idArea;
        _nomeAreaSelecionada = consultor?.nomeArea;
        _areas = areas;
        _isLoading = false;
      });
    }
  }

  // ── Guarda a área selecionada ──
  Future<void> _guardarArea() async {
    if (_idAreaSelecionada == null || _nomeAreaSelecionada == null) return;

    final sucesso = await APIService.instance.configuracaoInicial(
      idArea: _idAreaSelecionada!,
      nomeArea: _nomeAreaSelecionada!,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(sucesso ? 'Área atualizada.' : 'Erro ao atualizar área.'),
          backgroundColor: sucesso ? AppConstants.corSucesso : AppConstants.corErro,
        ),
      );
    }
  }

  // ── Guarda o idioma ──
  Future<void> _guardarIdioma(String codigo) async {
    if (_consultor == null) return;

    // Atualiza localmente
    setState(() => _linguaSelecionada = codigo);

    // Guarda na API e no SQLite através do updatePerfil
    final consultorAtualizado = Consultor(
      id: _consultor!.id,
      nome: _consultor!.nome,
      email: _consultor!.email,
      telefone: _consultor!.telefone,
      urlLinkedin: _consultor!.urlLinkedin,
      urlFoto: _consultor!.urlFoto,
      dataMembro: _consultor!.dataMembro,
      linguaPadrao: codigo,
      idArea: _consultor!.idArea,
      nomeArea: _consultor!.nomeArea,
      idLearningPath: _consultor!.idLearningPath,
      nomeLearningPath: _consultor!.nomeLearningPath,
      totalPontos: _consultor!.totalPontos,
      posicaoRanking: _consultor!.posicaoRanking,
    );

    await APIService.instance.atualizarPerfil(consultorAtualizado);
  }

  // ── Logout com confirmação ──
  Future<void> _terminarSessao() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Terminar sessão'),
        content: const Text('Pretende terminar a sua sessão?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.corPrimaria,
            ),
            child: const Text('Terminar sessão'),
          ),
        ],
      ),
    );

    if (confirmar == true && mounted) {
      ref.read(utilizadorProvider.notifier).limpar();
      ref.read(badgesProvider.notifier).limpar();
      ref.read(candidaturasProvider.notifier).limpar();
      await APIService.instance.logout();
      if (mounted) {
        context.go(AppConstants.routeLanding);
      }
    }
  }

  // ── AppBar ──
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: SvgPicture.asset(
            'assets/icons/drawerprimario.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              AppConstants.corPrimaria,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: const Text(
        'DEFINIÇÕES',
        style: TextStyle(
          color: AppConstants.corPrimaria,
          fontWeight: FontWeight.bold,
          fontSize: 16,
          letterSpacing: 1.2,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: SvgPicture.asset(
            'assets/icons/notificacoesprimaria.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(
              AppConstants.corPrimaria,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () =>
              context.push(AppConstants.routeNotificacoes),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const CustomDrawer(),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppConstants.corPrimaria),
            )
          : _consultor == null
              ? const Center(child: Text('Erro ao carregar dados.'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Avatar + nome ──
          _buildAvatar(),
          const SizedBox(height: 32),

          // ── Área ──
          _buildSectionLabel('Área'),
          const SizedBox(height: 8),
          _buildAreaDropdown(),
          const SizedBox(height: 24),

          // ── Idioma ──
          _buildSectionLabel('Idioma'),
          const SizedBox(height: 8),
          _buildIdiomaDropdown(),
          const SizedBox(height: 24),

          // ── Alterar password ──
          _buildSectionLabel('Segurança'),
          const SizedBox(height: 8),
          _buildListItem(
            icone: Icons.lock_outline,
            label: 'Alterar Password',
            onTap: () => context.push(AppConstants.routeAlterarPassword),
          ),
          const SizedBox(height: 32),

          // ── Terminar sessão ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _terminarSessao,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.corPrimaria,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Terminar Sessão',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Versão da app
          Text(
            'BadgeBoost v1.0.0',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  // image_picker 
  // Permite ao consultor tirar uma foto ou escolher da galeria para o perfil
  Future<void> _alterarFotoPerfil() async {
    final caminho = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const CameraScreen()),
    );
    if (caminho == null) return;
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto tirada com sucesso!'),
          backgroundColor: AppConstants.corSucesso,
        ),
      );
    }
  }

  // ── Avatar circular com nome e cargo ──
  Widget _buildAvatar() {
    final nomeInicial = _consultor!.nome.isNotEmpty
        ? _consultor!.nome[0].toUpperCase()
        : '?';

    return Column(
      children: [
        // Imagem ou iniciais
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppConstants.corPrimaria.withValues(alpha:0.15),
            border: Border.all(
              color: AppConstants.corPrimaria.withValues(alpha:0.3),
              width: 2,
            ),
          ),
          child: _consultor!.urlFoto != null
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: _consultor!.urlFoto!,
                    fit: BoxFit.cover,
                    placeholder: (ctx, url) => const CircularProgressIndicator(),
                    errorWidget: (ctx, url, err) => Center(
                      child: Text(
                        nomeInicial,
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppConstants.corPrimaria,
                        ),
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    nomeInicial,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppConstants.corPrimaria,
                    ),
                  ),
                ),
        ),
        const SizedBox(height: 8),
        // Botão para alterar foto — image_picker (Aula 11)
        GestureDetector(
          onTap: _alterarFotoPerfil,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppConstants.corPrimaria.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt_outlined, size: 14, color: AppConstants.corPrimaria),
                SizedBox(width: 4),
                Text('Alterar foto', style: TextStyle(fontSize: 12, color: AppConstants.corPrimaria)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Nome
        Text(
          _consultor!.nome,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppConstants.corPrimaria,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),

        // Área / nível
        Text(
          _nomeAreaSelecionada ?? _consultor!.nomeArea ?? '',
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ── Label de secção ──
  Widget _buildSectionLabel(String texto) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ── Dropdown de área ──
  Widget _buildAreaDropdown() {
    if (_areas.isEmpty) {
      // Sem áreas carregadas — mostra a atual como texto e um botão de guardar
      return _buildDropdownShell(
        child: Text(
          _consultor!.nomeArea ?? '',
          style: const TextStyle(fontSize: 15, color: Colors.black87),
        ),
        onTap: null,
      );
    }

    return _buildDropdownShell(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _idAreaSelecionada,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: AppConstants.corPrimaria),
          style: const TextStyle(fontSize: 15, color: Colors.black87),
          onChanged: (novoId) {
            if (novoId == null) return;
            final area = _areas.firstWhere((a) => a.id == novoId);
            setState(() {
              _idAreaSelecionada = novoId;
              _nomeAreaSelecionada = area.nome;
            });
            _guardarArea();
          },
          items: _areas
              .map(
                (a) => DropdownMenuItem(
                  value: a.id,
                  child: Text(a.nome),
                ),
              )
              .toList(),
        ),
      ),
      onTap: null,
    );
  }

  // ── Dropdown de idioma ──
  Widget _buildIdiomaDropdown() {
    final linguaAtual = _linguas.firstWhere(
      (l) => l.codigo == _linguaSelecionada,
      orElse: () => _linguas.first,
    );

    return _buildDropdownShell(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: linguaAtual.codigo,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: AppConstants.corPrimaria),
          style: const TextStyle(fontSize: 15, color: Colors.black87),
          onChanged: (codigo) {
            if (codigo == null) return;
            _guardarIdioma(codigo);
          },
          items: _linguas
              .map(
                (l) => DropdownMenuItem(
                  value: l.codigo,
                  child: Text('${l.bandeira}  ${l.nome}'),
                ),
              )
              .toList(),
        ),
      ),
      onTap: null,
    );
  }

  // ── Container partilhado para campos do tipo dropdown/row ──
  Widget _buildDropdownShell({
    required Widget child,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: child,
      ),
    );
  }

  // ── Item de lista (ex: Alterar Password) ──
  Widget _buildListItem({
    required IconData icone,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Row(
          children: [
            Icon(icone, color: AppConstants.corPrimaria, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
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
  const _Lingua({
    required this.codigo,
    required this.nome,
    required this.bandeira,
  });
}