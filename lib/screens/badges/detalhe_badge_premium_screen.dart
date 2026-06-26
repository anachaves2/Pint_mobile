import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/utils/badge_utils.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

// ECRÃ DETALHE BADGE PREMIUM
// Mostra os detalhes de um badge especial

class DetalheBadgePremium extends StatelessWidget {
  final BadgeUtilizador badge;

  const DetalheBadgePremium({super.key, required this.badge});

  static const Color _azulPrimario = AppConstants.corPrimaria;
  static const Color _dourado = Color(0xFFF5A623);
  static const Color _cinzaClaro = Color(0xFFF5F5F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIconePremium(),
            const SizedBox(height: 16),
            _buildNomeEEtiqueta(),
            const SizedBox(height: 24),
            if (badge.descricao != null) ...[
              _buildDescricao(),
              const SizedBox(height: 20),
            ],
            _buildSecaoInfo(),
            const SizedBox(height: 20),
            _buildDatas(),
            const SizedBox(height: 28),
            _buildBotoesPartilha(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: _azulPrimario, size: 20),
        onPressed: () => context.pop(),
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
          onPressed: () => context.push(AppConstants.routeNotificacoes),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(color: Colors.grey.shade200, height: 1),
      ),
    );
  }

  // Ícone grande dourado com estrela
  Widget _buildIconePremium() {
    if (badge.urlImagem != null) {
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: _dourado, width: 3),
          boxShadow: [
            BoxShadow(
              color: _dourado.withValues(alpha: 0.25),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: Image.network(
            badge.urlImagem!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                _buildIconeLetra('★', 96),
          ),
        ),
      );
    }
    return _buildIconeLetra('★', 96);
  }

  Widget _buildIconeLetra(String letra, double tamanho) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _dourado.withValues(alpha: 0.15),
        border: Border.all(color: _dourado, width: 3),
        boxShadow: [
          BoxShadow(
            color: _dourado.withValues(alpha: 0.2),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: Text(
          letra,
          style: TextStyle(
              color: _dourado,
              fontWeight: FontWeight.bold,
              fontSize: tamanho * 0.4),
        ),
      ),
    );
  }

  Widget _buildNomeEEtiqueta() {
    return Column(
      children: [
        Text(
          badge.nomeBadge,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        // Etiqueta Premium dourada
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: _dourado.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _dourado.withValues(alpha: 0.5)),
          ),
          child: const Text(
            '★ Especial',
            style: TextStyle(
              fontSize: 12,
              color: _dourado,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescricao() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cinzaClaro,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        badge.descricao!,
        style: const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
      ),
    );
  }

  Widget _buildSecaoInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cinzaClaro,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (badge.pontos != null)
            _buildLinhaInfo('Gamification', '${badge.pontos} Pontos',
                destaque: true),
        ],
      ),
    );
  }

  Widget _buildLinhaInfo(String label, String valor, {bool destaque = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        Text(
          valor,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: destaque ? _dourado : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildDatas() {
    return Row(
      children: [
        Expanded(
          child: _buildChipData(
            label: 'Conquistado em:',
            data: BadgeUtils.formatarData(badge.dataAtribuicao),
            cor: _azulPrimario,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildChipData(
            label: 'Válido até:',
            data: BadgeUtils.formatarData(badge.dataExpiracao),
            cor: badge.estaProximoDeExpirar
                ? Colors.orange.shade400
                : Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildChipData(
      {required String label, required String data, required Color cor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: cor.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(10),
        color: cor.withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 2),
          Text(data,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: cor)),
        ],
      ),
    );
  }

  Widget _buildBotoesPartilha(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _partilharLinkedIn(context),
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Partilhar no LinkedIn'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0077B5),
              side: const BorderSide(color: Color(0xFF0077B5)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        if (badge.urlPublico != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _abrirPaginaPublica(context),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Ver página pública'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _azulPrimario,
                side: const BorderSide(color: _azulPrimario),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _partilharLinkedIn(BuildContext context) async {
    final url = badge.urlPublico != null
        ? 'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(badge.urlPublico!)}'
        : 'https://www.linkedin.com';
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir o LinkedIn')),
      );
    }
  }

  Future<void> _abrirPaginaPublica(BuildContext context) async {
    final uri = Uri.parse(badge.urlPublico!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a página')),
      );
    }
  }
}