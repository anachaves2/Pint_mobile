import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/utils/constants.dart';

class TodosOsBadges extends StatefulWidget {
  const TodosOsBadges({super.key});

  @override
  State<TodosOsBadges> createState() => _TodosOsBadgesState();
}

class _TodosOsBadgesState extends State<TodosOsBadges> {
  // Lista completa vinda da BD
  List<BadgeUtilizador> _badges = [];
  // Lista filtrada pela pesquisa
  List<BadgeUtilizador> _badgesFiltrados = [];
  bool _isLoading = true;
  final TextEditingController _pesquisaController = TextEditingController();

  static const Color _azulPrimario = AppConstants.corPrimaria;
  static const Color _cinzaClaro = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _carregarBadges();
  }

  @override
  void dispose() {
    // Liberta o controller quando o ecrã é destruído — boa prática para evitar memory leaks
    _pesquisaController.dispose();
    super.dispose();
  }

  Future<void> _carregarBadges() async {
    final badges = await DatabaseService.instance.getBadges();

    // Filtra apenas badges regulares válidos (sem especiais e sem expirados)
    final regulares = badges
        .where((b) => b.idBadgeEspecial == null && !b.jaExpirou)
        .toList()
      ..sort((a, b) => b.dataAtribuicao.compareTo(a.dataAtribuicao));

    if (mounted) {
      setState(() {
        _badges = regulares;
        _badgesFiltrados = regulares;
        _isLoading = false;
      });
    }
  }

  // Filtra a lista com base no texto de pesquisa
  void _filtrar(String texto) {
    final query = texto.toLowerCase();
    setState(() {
      _badgesFiltrados = _badges.where((b) {
        return b.nomeBadge.toLowerCase().contains(query) ||
            (b.nomeNivel?.toLowerCase().contains(query) ?? false) ||
            (b.nomeArea?.toLowerCase().contains(query) ?? false) ||
            (b.nomeServiceLine?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  // Dados fictícios para desenvolvimento (remover quando a BD estiver ligada)
  List<BadgeUtilizador> get _mockBadges {
    final agora = DateTime.now();
    return List.generate(6, (i) {
      final niveis = ['A', 'B', 'C', 'D', 'E'];
      final nomesNivel = ['Júnior', 'Intermédio', 'Sénior', 'Especialista', 'Líder de Conhecimento'];
      final nivel = niveis[i % niveis.length];
      return BadgeUtilizador(
        id: i + 1,
        idUtilizador: 1,
        idBadgeRegular: i + 1,
        nomeBadge: 'App Developer',
        nomeNivel: nomesNivel[i % nomesNivel.length],
        tipoNivel: nivel,
        dataAtribuicao: agora.subtract(Duration(days: i * 30)),
        dataExpiracao: agora.add(const Duration(days: 365)),
        valido: true,
        nomeServiceLine: 'Mobile Solutions',
        nomeArea: 'Mobile Apps',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usa dados fictícios se a BD estiver vazia
    final lista = _badgesFiltrados.isEmpty && !_isLoading && _pesquisaController.text.isEmpty
        ? _mockBadges
        : _badgesFiltrados;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _azulPrimario))
          : Column(
              children: [
                // Barra de pesquisa fixa no topo
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: _buildBarraPesquisa(),
                ),
                // Lista de badges
                Expanded(
                  child: RefreshIndicator(
                    color: _azulPrimario,
                    onRefresh: _carregarBadges,
                    child: lista.isEmpty
                        ? _buildEstadoVazio()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                            itemCount: lista.length,
                            itemBuilder: (context, index) =>
                                _buildBadgeCard(lista[index]),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

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
        'BADGES',
        style: TextStyle(
          color: _azulPrimario,
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
          onPressed: () => Navigator.pushNamed(context, '/notificacoes'),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
    );
  }

  Widget _buildBarraPesquisa() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: _cinzaClaro,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: _pesquisaController,
        onChanged: _filtrar,
        decoration: InputDecoration(
          hintText: 'Procura...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          // Botão para limpar a pesquisa
          suffixIcon: _pesquisaController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 18, color: Colors.grey.shade400),
                  onPressed: () {
                    _pesquisaController.clear();
                    _filtrar('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildEstadoVazio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium_outlined,
              color: Colors.grey.shade300, size: 64),
          const SizedBox(height: 16),
          Text(
            _pesquisaController.text.isNotEmpty
                ? 'Nenhum badge encontrado'
                : 'Ainda não tens badges conquistados',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(BadgeUtilizador badge) {
    return GestureDetector(
      // Navega para o detalhe do badge ao clicar no card
      onTap: () => Navigator.pushNamed(
        context,
        '/detalhe-badge-regular',
        arguments: badge,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildIconeBadge(badge),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    badge.nomeBadge,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  if (badge.nomeNivel != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      badge.nomeNivel!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  _buildDatas(badge),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildIconeBadge(BadgeUtilizador badge) {
    final cor = _corDoNivel(badge.tipoNivel);
    final letra = badge.tipoNivel?.isNotEmpty == true
        ? badge.tipoNivel![0].toUpperCase()
        : '?';

    if (badge.urlImagem != null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: cor, width: 2),
        ),
        child: ClipOval(
          child: Image.network(
            badge.urlImagem!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildIconeLetra(letra, cor),
          ),
        ),
      );
    }
    return _buildIconeLetra(letra, cor);
  }

  Widget _buildIconeLetra(String letra, Color cor) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cor.withOpacity(0.15),
        border: Border.all(color: cor, width: 2),
      ),
      child: Center(
        child: Text(
          letra,
          style: TextStyle(
            color: cor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildDatas(BadgeUtilizador badge) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Conquistado: ${_formatarData(badge.dataAtribuicao)}',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        Text(
          'Válido até: ${_formatarData(badge.dataExpiracao)}',
          style: TextStyle(
            fontSize: 11,
            color: badge.estaProximoDeExpirar
                ? Colors.orange.shade400
                : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  // Cor do círculo com base no tipo de nível
  Color _corDoNivel(String? tipoNivel) {
    switch (tipoNivel?.toUpperCase()) {
      case 'A': return const Color(0xFFF5A623); // laranja — Júnior
      case 'B': return Colors.grey;              // cinza — Intermédio
      case 'C': return const Color(0xFF4CAF50);  // verde — Sénior
      case 'D': return const Color(0xFF0066CC);  // azul — Especialista
      case 'E': return const Color(0xFF9C27B0);  // roxo — Líder de Conhecimento
      default:  return const Color(0xFF0066CC);
    }
  }

  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.year}';
  }
}