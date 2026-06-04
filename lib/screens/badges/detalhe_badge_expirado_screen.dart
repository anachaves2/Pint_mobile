import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/utils/badge_utils.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:go_router/go_router.dart';

// ECRÃ DETALHE BADGE EXPIRADO
// Mostra os detalhes de um badge expirado.
// Visual acinzentado para indicar o estado inativo.
// Tem botão "Renovar" que navega para nova candidatura pré-preenchida.

class DetalheBadgeExpirado extends StatelessWidget {
  final BadgeUtilizador badge;

  const DetalheBadgeExpirado({super.key, required this.badge});

  static const Color _azulPrimario = AppConstants.corPrimaria;
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
            _buildIconeExpirado(),
            const SizedBox(height: 16),
            _buildNomeEEstado(),
            const SizedBox(height: 24),
            _buildSecaoInfo(),
            const SizedBox(height: 20),
            if (badge.descricao != null) ...[
              _buildDescricao(),
              const SizedBox(height: 20),
            ],
            _buildDatas(),
            const SizedBox(height: 28),
            _buildBotaoRenovar(context),
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

  // Ícone a preto e branco para reforçar o estado expirado
  Widget _buildIconeExpirado() {
    final cor = Colors.grey.shade400;
    final letra = badge.idBadgeEspecial != null
        ? '★'
        : (badge.tipoNivel?.isNotEmpty == true
            ? badge.tipoNivel![0].toUpperCase()
            : '?');

    if (badge.urlImagem != null) {
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: cor, width: 3),
        ),
        child: ClipOval(
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0,      0,      0,      1, 0,
            ]),
            child: Image.network(
              badge.urlImagem!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _buildIconeLetra(letra, cor, 96),
            ),
          ),
        ),
      );
    }
    return _buildIconeLetra(letra, cor, 96);
  }

  Widget _buildIconeLetra(String letra, Color cor, double tamanho) {
    return Container(
      width: tamanho,
      height: tamanho,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cor.withValues(alpha: 0.15),
        border: Border.all(color: cor, width: 3),
      ),
      child: Center(
        child: Text(
          letra,
          style: TextStyle(
              color: cor,
              fontWeight: FontWeight.bold,
              fontSize: tamanho * 0.4),
        ),
      ),
    );
  }

  Widget _buildNomeEEstado() {
    return Column(
      children: [
        Text(
          badge.nomeBadge,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        if (badge.nomeNivel != null) ...[
          const SizedBox(height: 4),
          Text(badge.nomeNivel!,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade400)),
        ],
        const SizedBox(height: 8),
        // Etiqueta "Expirado" em vermelho
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Text(
            'Expirado',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade400,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
          if (badge.nomeServiceLine != null)
            _buildLinhaInfo('Service Line', badge.nomeServiceLine!),
          if (badge.nomeArea != null) ...[
            const SizedBox(height: 8),
            _buildLinhaInfo('Área', badge.nomeArea!),
          ],
          if (badge.pontos != null) ...[
            const SizedBox(height: 8),
            _buildLinhaInfo('Gamification', '${badge.pontos} Pontos'),
          ],
        ],
      ),
    );
  }

  Widget _buildLinhaInfo(String label, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        Text(valor,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600)),
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
        style: TextStyle(
            fontSize: 14, color: Colors.grey.shade600, height: 1.5),
      ),
    );
  }

  Widget _buildDatas() {
    return Row(
      children: [
        Expanded(
          child: _buildChipData(
            label: 'Conquistado em:',
            data: BadgeUtils.formatarData(badge.dataAtribuicao),
            cor: Colors.grey.shade500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildChipData(
            label: 'Expirou em:',
            data: BadgeUtils.formatarData(badge.dataExpiracao),
            cor: Colors.red.shade300,
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

  // Botão Renovar — navega para nova candidatura pré-preenchida com este badge
  Widget _buildBotaoRenovar(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Passa o idBadgeRegular como rascunho para pré-preencher a candidatura
          context.push(
            AppConstants.routeNovaCandidatura,
            extra: badge.idBadgeRegular != null
                ? {'idBadgeRegular': badge.idBadgeRegular}
                : null,
          );
        },
        icon: const Icon(Icons.refresh, size: 18),
        label: const Text('Renovar'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _azulPrimario,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}