import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/utils/badge_utils.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';
import 'package:pint_mobile/widgets/texto_traduzido.dart';
import 'package:go_router/go_router.dart';

// ECRÃ DETALHE BADGE EXPIRADO
// Mostra os detalhes de um badge expirado. Segue os tokens D, mantendo o
// tratamento a preto-e-branco/cinzento que já reforçava o estado inativo.

class DetalheBadgeExpirado extends ConsumerWidget {
  final BadgeUtilizador badge;

  const DetalheBadgeExpirado({super.key, required this.badge});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: D.fundo,
      appBar: _buildAppBar(context, ref),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: D.e5, vertical: D.e5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIconeExpirado(),
            const SizedBox(height: D.e4),
            _buildNomeEEstado(ref),
            const SizedBox(height: D.e5),
            _buildSecaoInfo(ref),
            const SizedBox(height: D.e4),
            if (badge.descricao != null) ...[
              _buildDescricao(),
              const SizedBox(height: D.e4),
            ],
            _buildDatas(ref),
            const SizedBox(height: D.e6),
            _buildBotaoRenovar(context, ref),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, WidgetRef ref) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: AppConstants.corPrimaria, size: 20),
        onPressed: () => context.pop(),
      ),
      title: Text(ref.t('mobile_badges_titulo'), style: D.tituloPagina),
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

  // Ícone a preto e branco para reforçar o estado expirado
  Widget _buildIconeExpirado() {
    const cor = D.tinta30;
    final letra = badge.idBadgeEspecial != null
        ? '★'
        : (badge.tipoNivel?.isNotEmpty == true ? badge.tipoNivel![0].toUpperCase() : '?');

    if (badge.urlImagem != null) {
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: cor, width: 3)),
        child: ClipOval(
          child: ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0.2126, 0.7152, 0.0722, 0, 0,
              0,      0,      0,      1, 0,
            ]),
            child: Image.network(
              AppConstants.resolverUrlFicheiro(badge.urlImagem)!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => _buildIconeLetra(letra, cor, 96),
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
        child: Text(letra, style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: tamanho * 0.4)),
      ),
    );
  }

  Widget _buildNomeEEstado(WidgetRef ref) {
    return Column(
      children: [
        Text(
          badge.nomeBadge,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: D.tinta50),
          textAlign: TextAlign.center,
        ),
        if (badge.nomeNivel != null) ...[
          const SizedBox(height: D.e1 + 2),
          Text(badge.nomeNivel!, style: D.legenda.copyWith(color: D.tinta30)),
        ],
        const SizedBox(height: D.e2),
        const ChipEstadoExpirado(),
      ],
    );
  }

  Widget _buildSecaoInfo(WidgetRef ref) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(D.e4),
      decoration: BoxDecoration(color: D.fundoAlt, borderRadius: BorderRadius.circular(D.rLg)),
      child: Column(
        children: [
          if (badge.nomeServiceLine != null) _buildLinhaInfo(ref.t('mobile_badges_service_line'), badge.nomeServiceLine!),
          if (badge.nomeArea != null) ...[
            const SizedBox(height: D.e2),
            _buildLinhaInfo(ref.t('mobile_badges_area'), badge.nomeArea!),
          ],
          if (badge.pontos != null) ...[
            const SizedBox(height: D.e2),
            _buildLinhaInfo(ref.t('mobile_dash_gamification_titulo'), '${badge.pontos} ${ref.t('mobile_ranking_pontos')}'),
          ],
        ],
      ),
    );
  }

  Widget _buildLinhaInfo(String label, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: D.legenda.copyWith(color: D.tinta30)),
        Text(valor, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: D.tinta50)),
      ],
    );
  }

  Widget _buildDescricao() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(D.e4),
      decoration: BoxDecoration(color: D.fundoAlt, borderRadius: BorderRadius.circular(D.rLg)),
      child: TextoTraduzido(texto: badge.descricao, style: D.corpo.copyWith(color: D.tinta50, height: 1.5)),
    );
  }

  Widget _buildDatas(WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _buildChipData(
            label: ref.t('mobile_badges_conquistado_em'),
            data: BadgeUtils.formatarData(badge.dataAtribuicao),
            cor: D.tinta30,
          ),
        ),
        const SizedBox(width: D.e3),
        Expanded(
          child: _buildChipData(
            label: ref.t('mobile_badges_expirou_em'),
            data: BadgeUtils.formatarData(badge.dataExpiracao),
            cor: D.erro,
          ),
        ),
      ],
    );
  }

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

  Widget _buildBotaoRenovar(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // Navega para nova candidatura, o utilizador escolhe o badge
          context.push(AppConstants.routeNovaCandidatura);
        },
        icon: const Icon(Icons.refresh, size: 18),
        label: Text(ref.t('mobile_badges_renovar')),
        style: ElevatedButton.styleFrom(
          backgroundColor: D.azul600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: D.e3 + 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
        ),
      ),
    );
  }
}

// Etiqueta "Expirado" — sem borda, fundo suave, tal como o resto do design.
class ChipEstadoExpirado extends ConsumerWidget {
  const ChipEstadoExpirado({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: D.e3, vertical: 4),
      decoration: BoxDecoration(color: D.erroBg, borderRadius: BorderRadius.circular(999)),
      child: Text(ref.t('mobile_badges_expirado'), style: const TextStyle(fontSize: 12, color: D.erro, fontWeight: FontWeight.w600)),
    );
  }
}