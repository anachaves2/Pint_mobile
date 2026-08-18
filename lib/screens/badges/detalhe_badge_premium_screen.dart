import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

// ECRÃ DETALHE BADGE PREMIUM
// Mostra os detalhes de um badge especial. Segue os tokens D — o dourado
// (D.aviso) é o acento próprio dos badges especiais, tal como na web.

class DetalheBadgePremium extends StatelessWidget {
  final BadgeUtilizador badge;

  const DetalheBadgePremium({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: D.fundo,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: D.e5, vertical: D.e5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIconePremium(),
            const SizedBox(height: D.e4),
            _buildNomeEEtiqueta(),
            const SizedBox(height: D.e5),
            if (badge.descricao != null) ...[
              _buildDescricao(),
              const SizedBox(height: D.e4),
            ],
            _buildSecaoInfo(),
            const SizedBox(height: D.e4),
            _buildDatas(),
            const SizedBox(height: D.e6),
            _buildBotoesPartilha(context),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppConstants.corPrimaria, size: 20),
        onPressed: () => context.pop(),
      ),
      title: const Text('BADGES', style: D.tituloPagina),
      actions: [
        IconButton(
          icon: SvgPicture.asset(
            'assets/icons/notificacoesprimaria.svg',
            width: 24,
            height: 24,
            colorFilter: const ColorFilter.mode(AppConstants.corPrimaria, BlendMode.srcIn),
          ),
          onPressed: () => context.push(AppConstants.routeNotificacoes),
        ),
      ],
    );
  }

  // Ícone grande dourado com estrela — brilho colorido é a exceção
  // deliberada aqui, tal como no pódio do ranking.
  Widget _buildIconePremium() {
    if (badge.urlImagem != null) {
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: D.aviso, width: 3),
          boxShadow: [BoxShadow(color: D.aviso.withValues(alpha: 0.25), blurRadius: 12, spreadRadius: 2)],
        ),
        child: ClipOval(
          child: Image.network(
            AppConstants.resolverUrlFicheiro(badge.urlImagem)!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildIconeLetra('★', 96),
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
        color: D.aviso.withValues(alpha: 0.15),
        border: Border.all(color: D.aviso, width: 3),
        boxShadow: [BoxShadow(color: D.aviso.withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 2)],
      ),
      child: Center(
        child: Text(letra, style: TextStyle(color: D.aviso, fontWeight: FontWeight.bold, fontSize: tamanho * 0.4)),
      ),
    );
  }

  Widget _buildNomeEEtiqueta() {
    return Column(
      children: [
        Text(badge.nomeBadge, style: D.tituloSeccao.copyWith(fontSize: 20), textAlign: TextAlign.center),
        const SizedBox(height: D.e2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: D.e3 + 2, vertical: 5),
          decoration: BoxDecoration(color: D.avisoBg, borderRadius: BorderRadius.circular(999)),
          child: const Text('★ Badge Especial',
              style: TextStyle(fontSize: 12, color: D.aviso, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildDescricao() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(D.e4),
      decoration: BoxDecoration(color: D.fundoAlt, borderRadius: BorderRadius.circular(D.rLg)),
      child: Text(badge.descricao!, style: D.corpo.copyWith(height: 1.5)),
    );
  }

  Widget _buildSecaoInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(D.e4),
      decoration: BoxDecoration(color: D.fundoAlt, borderRadius: BorderRadius.circular(D.rLg)),
      child: Column(
        children: [
          if (badge.pontos != null) _buildLinhaInfo('Gamification', '${badge.pontos} Pontos', destaque: true),
        ],
      ),
    );
  }

  Widget _buildLinhaInfo(String label, String valor, {bool destaque = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: D.legenda),
        Text(valor, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: destaque ? D.aviso : D.tinta)),
      ],
    );
  }

  Widget _buildDatas() {
    return Row(
      children: [
        Expanded(
          child: _buildChipData(
            label: 'Conquistado em:',
            data: _formatarData(badge.dataAtribuicao),
            cor: D.aviso,
          ),
        ),
        const SizedBox(width: D.e3),
        Expanded(
          child: _buildChipData(
            label: 'Válido até:',
            data: _formatarData(badge.dataExpiracao),
            cor: badge.estaProximoDeExpirar ? D.erro : D.tinta50,
          ),
        ),
      ],
    );
  }

  String _formatarData(DateTime data) =>
      '${data.day.toString().padLeft(2, '0')}-${data.month.toString().padLeft(2, '0')}-${data.year}';

  Widget _buildChipData({required String label, required String data, required Color cor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: D.e3, vertical: D.e2 + 2),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(D.rMd), color: cor.withValues(alpha: 0.08)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: D.legenda.copyWith(fontSize: 11)),
          const SizedBox(height: 2),
          Text(data, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: cor)),
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
              padding: const EdgeInsets.symmetric(vertical: D.e3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
            ),
          ),
        ),
        const SizedBox(height: D.e2 + 2),
        if (badge.urlPublico != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _abrirPaginaPublica(context),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Ver página pública'),
              style: OutlinedButton.styleFrom(
                foregroundColor: D.aviso,
                side: const BorderSide(color: D.aviso),
                padding: const EdgeInsets.symmetric(vertical: D.e3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
              ),
            ),
          ),
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