import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/widgets/custom_drawer.dart';
import 'package:go_router/go_router.dart';

// ECRÃ OS MEUS BADGES
// Página principal dos badges do consultor autenticado
// Dividida em 3 secções: Recentes, Especiais e Expirados
// Cada secção mostra até 3 badges com botão "VER TODOS" que navega para a lista completa
// Os dados são lidos do SQLite local (sincronizados no login pelo APIService)

class OsMeusBadges extends StatefulWidget {
  const OsMeusBadges({super.key});

  @override
  State<OsMeusBadges> createState() => _OsMeusBadgesState();
}

class _OsMeusBadgesState extends State<OsMeusBadges> {
  List<BadgeUtilizador> _badges = []; // todos os badges do utilizador (regulares + especiais + expirados)
  bool _isLoading = true;

  static const Color _azulPrimario = AppConstants.corPrimaria;
  static const Color _cinzaClaro = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _carregarBadges();
  }

  // Lê todos os badges do SQLite local
  Future<void> _carregarBadges() async {
    final badges = await DatabaseService.instance.getBadges();
    if (mounted) {
      setState(() {
        _badges = badges;
        _isLoading = false;
      });
    }
  }

  // Pull to refresh: sincroniza com a API e relê do SQLite
  Future<void> _refresh() async {
    await APIService.instance.sincronizarBadges();
    await _carregarBadges();
  }

  // Filtra os 3 badges regulares válidos mais recentes (ordenados por data de atribuição)
  List<BadgeUtilizador> get _badgesRecentes {
    final lista = _badges
        .where((b) => b.valido && b.idBadgeEspecial == null)
        .toList()
      ..sort((a, b) => b.dataAtribuicao.compareTo(a.dataAtribuicao));
    return lista.take(3).toList();
  }

  // Filtra os 3 badges especiais válidos mais recentes
  List<BadgeUtilizador> get _badgesEspeciais {
    final lista = _badges
        .where((b) => b.idBadgeEspecial != null && b.valido)
        .toList()
      ..sort((a, b) => b.dataAtribuicao.compareTo(a.dataAtribuicao));
    return lista.take(3).toList();
  }

  // Filtra os 3 badges mais recentemente expirados
  List<BadgeUtilizador> get _badgesExpirados {
    final lista = _badges.where((b) => b.jaExpirou).toList()
      ..sort((a, b) => b.dataExpiracao.compareTo(a.dataExpiracao));
    return lista.take(3).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: const CustomDrawer(),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: _azulPrimario))
          : RefreshIndicator(
              color: _azulPrimario,
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBarraPesquisa(),
                    const SizedBox(height: 20),
                    // Secção de badges regulares recentes → navega para TodosOsBadges
                    _buildSecao(
                      titulo: 'RECENTES',
                      badges: _badgesRecentes,
                      rotaVerTodos: '/todos-badges',
                    ),
                    const SizedBox(height: 24),
                    // Secção de badges especiais → navega para BadgesEspeciais
                    _buildSecao(
                      titulo: 'ESPECIAIS',
                      badges: _badgesEspeciais,
                      rotaVerTodos: '/badges-especiais',
                    ),
                    const SizedBox(height: 24),
                    // Secção de badges expirados → navega para BadgesExpirados
                    _buildSecao(
                      titulo: 'EXPIRADOS',
                      badges: _badgesExpirados,
                      rotaVerTodos: '/badges-expirados',
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  // AppBar com ícones SVG na cor primária da Softinsa
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
                AppConstants.corPrimaria, BlendMode.srcIn),
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
                AppConstants.corPrimaria, BlendMode.srcIn),
          ),
          onPressed: () => context.push('/notificacoes'),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
    );
  }

  // Barra de pesquisa visual — ainda sem funcionalidade de filtro
  // neste ecrã porque só mostra 3 badges por secção
  Widget _buildBarraPesquisa() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: _cinzaClaro,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Procura...',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon:
              Icon(Icons.search, color: Colors.grey.shade400, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  // Secção genérica com título, lista de badges e botão "VER TODOS"
  // Reutilizada para Recentes, Especiais e Expirados
  Widget _buildSecao({
    required String titulo,
    required List<BadgeUtilizador> badges,
    required String rotaVerTodos,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        // Se não houver badges nesta secção, mostra estado vazio
        if (badges.isEmpty)
          _buildEstadoVazio()
        else
          ...badges.map((badge) => _buildBadgeCard(badge)),
        const SizedBox(height: 8),
        // Botão "VER TODOS" navega para a lista completa da secção
        Center(
          child: OutlinedButton(
            onPressed: () => context.push(rotaVerTodos),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
            ),
            child: const Text(
              'VER TODOS',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Estado vazio — aparece quando uma secção não tem badges
  Widget _buildEstadoVazio() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: _cinzaClaro,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(Icons.workspace_premium_outlined,
              color: Colors.grey.shade300, size: 36),
          const SizedBox(height: 8),
          Text(
            'Sem badges',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // Card de badge — reutilizado para regulares, especiais e expirados
  // Ao clicar navega para o detalhe correto conforme o tipo de badge
  Widget _buildBadgeCard(BadgeUtilizador badge) {
    final bool eEspecial = badge.idBadgeEspecial != null;
    final bool eExpirado = badge.jaExpirou;

    return GestureDetector(
      onTap: () {
        // Navega para o ecrã de detalhe correto conforme o tipo
        if (eEspecial) {
          context.push('/detalhe-badge-premium', extra: badge);
        } else if (eExpirado) {
          context.push('/detalhe-badge-expirado', extra: badge);
        } else {
          context.push('/detalhe-badge-regular', extra: badge);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _buildIconeBadge(badge, eEspecial, eExpirado),
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
                          fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    'Conquistado: ${_formatarData(badge.dataAtribuicao)}',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                  Text(
                    eExpirado
                        ? 'Expirou: ${_formatarData(badge.dataExpiracao)}'
                        : 'Válido até: ${_formatarData(badge.dataExpiracao)}',
                    style: TextStyle(
                      fontSize: 11,
                      // data a vermelho se expirou, laranja se está próximo de expirar
                      color: eExpirado
                          ? Colors.red.shade300
                          : badge.estaProximoDeExpirar
                              ? Colors.orange.shade400
                              : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  // Ícone circular do badge com cor e letra baseadas no tipo/nível
  // Especiais → estrela dourada ★
  // Expirados → cinzento (independentemente do nível original)
  // Regulares → cor e letra do nível (A=laranja, B=cinza, C=verde, D=azul, E=roxo)
  Widget _buildIconeBadge(
      BadgeUtilizador badge, bool eEspecial, bool eExpirado) {
    Color cor;
    if (eExpirado) {
      cor = Colors.grey.shade400;
    } else if (eEspecial) {
      cor = const Color(0xFFF5A623); // dourado para especiais
    } else {
      cor = _corDoNivel(badge.tipoNivel);
    }

    final letra = eEspecial
        ? '★'
        : (badge.tipoNivel?.isNotEmpty == true
            ? badge.tipoNivel![0].toUpperCase()
            : '?');

    // Se tiver imagem, mostra a imagem com fallback para a letra
    if (badge.urlImagem != null) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: cor, width: 2),
        ),
        child: ClipOval(
          child: Image.network(badge.urlImagem!, fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildIconeLetra(letra, cor)),
        ),
      );
    }
    return _buildIconeLetra(letra, cor);
  }

  // Círculo com a letra do nível ou ★ para especiais
  Widget _buildIconeLetra(String letra, Color cor) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cor.withValues(alpha: 0.15),
        border: Border.all(color: cor, width: 2),
      ),
      child: Center(
        child: Text(
          letra,
          style: TextStyle(
            color: cor,
            fontWeight: FontWeight.bold,
            fontSize: letra == '★' ? 18 : 16,
          ),
        ),
      ),
    );
  }

  // Cor do círculo com base no tipo de nível (campo TIPO da tabela NIVEL)
  // JN=Júnior=laranja, IN=Intermédio=cinza, SN=Sénior=verde,
  // EP=Especialista=azul, LD=Líder=roxo
  Color _corDoNivel(String? tipoNivel) {
    switch (tipoNivel?.toUpperCase()) {
      case 'A':
      case 'JN': return const Color(0xFFF5A623); // laranja — Júnior
      case 'B':
      case 'IN': return Colors.grey;              // cinza — Intermédio
      case 'C':
      case 'SN': return const Color(0xFF4CAF50);  // verde — Sénior
      case 'D':
      case 'EP': return const Color(0xFF0066CC);  // azul — Especialista
      case 'E':
      case 'LD': return const Color(0xFF9C27B0);  // roxo — Líder de Conhecimento
      default:   return const Color(0xFF0066CC);
    }
  }

  // Formata uma data DateTime para o formato DD-MM-AAAA
  String _formatarData(DateTime data) {
    return '${data.day.toString().padLeft(2, '0')}-'
        '${data.month.toString().padLeft(2, '0')}-'
        '${data.year}';
  }
}