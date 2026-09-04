import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/utils/badge_utils.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pint_mobile/utils/certificado_badge.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/widgets/texto_traduzido.dart';
import 'package:pint_mobile/providers/utilizador_provider.dart';
import 'package:pint_mobile/utils/assinatura_email.dart';

// ECRÃ DETALHE BADGE REGULAR
// Mostra os detalhes completos de um badge regular válido.
// Segue os tokens D — blocos de informação em D.fundoAlt, sem bordas.

class DetalheBadgeRegular extends ConsumerWidget {
  final BadgeUtilizador badge;

  const DetalheBadgeRegular({super.key, required this.badge});

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
            _buildIconeBadge(),
            const SizedBox(height: D.e4),
            _buildNomeENivel(),
            const SizedBox(height: D.e5),
            _buildSecaoInfo(ref),
            const SizedBox(height: D.e4),
            if (badge.descricao != null) ...[
              _buildDescricao(),
              const SizedBox(height: D.e4),
            ],
            _buildDatas(ref),
            const SizedBox(height: D.e6),
            _buildBotoesPartilha(context, ref),
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

  // Ícone grande do badge centrado no topo do ecrã
  Widget _buildIconeBadge() {
    final cor = BadgeUtils.corDoNivel(badge.tipoNivel);
    final letra = badge.tipoNivel?.isNotEmpty == true ? badge.tipoNivel![0].toUpperCase() : '?';

    if (badge.urlImagem != null) {
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: cor, width: 3)),
        child: ClipOval(
          child: Image.network(
            AppConstants.resolverUrlFicheiro(badge.urlImagem)!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _buildIconeLetra(letra, cor, 96),
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

  Widget _buildNomeENivel() {
    return Column(
      children: [
        Text(badge.nomeBadge, style: D.tituloSeccao.copyWith(fontSize: 20), textAlign: TextAlign.center),
        if (badge.nomeNivel != null) ...[
          const SizedBox(height: D.e2),
          Text(badge.nomeNivel!, style: D.legenda),
        ],
      ],
    );
  }

  // Secção com Service Line, Área e Pontos de Gamification
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
            _buildLinhaInfo(ref.t('mobile_dash_gamification_titulo'), '${badge.pontos} ${ref.t('mobile_ranking_pontos')}', destaque: true),
          ],
        ],
      ),
    );
  }

  Widget _buildLinhaInfo(String label, String valor, {bool destaque = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: D.legenda),
        Text(
          valor,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: destaque ? D.azul600 : D.tinta),
        ),
      ],
    );
  }

  Widget _buildDescricao() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(D.e4),
      decoration: BoxDecoration(color: D.fundoAlt, borderRadius: BorderRadius.circular(D.rLg)),
      child: TextoTraduzido(texto: badge.descricao, style: D.corpo.copyWith(height: 1.5)),
    );
  }

  // Datas de conquista e validade com alerta visual se próximo de expirar
  Widget _buildDatas(WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: _buildChipData(
            label: ref.t('mobile_badges_conquistado_em'),
            data: BadgeUtils.formatarData(badge.dataAtribuicao),
            cor: D.azul600,
          ),
        ),
        const SizedBox(width: D.e3),
        Expanded(
          child: _buildChipData(
            label: ref.t('mobile_badges_valido_ate'),
            data: BadgeUtils.formatarData(badge.dataExpiracao),
            cor: badge.estaProximoDeExpirar ? D.aviso : D.tinta50,
          ),
        ),
      ],
    );
  }

  Widget _buildChipData({required String label, required String data, required Color cor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: D.e3, vertical: D.e2 + 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(D.rMd),
        color: cor.withValues(alpha: 0.08),
      ),
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

  // Botões de partilha: LinkedIn e página pública do badge
  Widget _buildBotoesPartilha(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _partilharLinkedIn(context, ref),
            icon: const Icon(Icons.share, size: 18),
            label: Text(ref.t('mobile_badges_partilhar_linkedin')),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF0077B5),
              side: const BorderSide(color: Color(0xFF0077B5)),
              padding: const EdgeInsets.symmetric(vertical: D.e3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
            ),
          ),
        ),
        const SizedBox(height: D.e2 + 2),
        if (badge.tokenValidacao != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _abrirPaginaPublica(context, ref),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(ref.t('mobile_badges_ver_pagina_publica')),
              style: OutlinedButton.styleFrom(
                foregroundColor: D.azul600,
                side: const BorderSide(color: D.azul600),
                padding: const EdgeInsets.symmetric(vertical: D.e3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
              ),
            ),
          ),
        const SizedBox(height: D.e2 + 2),
        if (badge.tokenValidacao != null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => mostrarDialogAssinaturaEmail(context, ref, badge),
              icon: const Icon(Icons.badge_outlined, size: 18),
              label: Text(ref.t('mobile_badges_assinatura_email')),
              style: OutlinedButton.styleFrom(
                foregroundColor: D.azul600,
                side: const BorderSide(color: D.azul600),
                padding: const EdgeInsets.symmetric(vertical: D.e3),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
              ),
            ),
          ),
        const SizedBox(height: D.e2 + 2),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _descarregarCertificado(context, ref),
            icon: const Icon(Icons.download_outlined, size: 18),
            label: Text(ref.t('mobile_badges_descarregar_certificado')),
            style: OutlinedButton.styleFrom(
              foregroundColor: D.azul600,
              side: const BorderSide(color: D.azul600),
              padding: const EdgeInsets.symmetric(vertical: D.e3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
            ),
          ),
        ),
        const SizedBox(height: D.e2 + 2),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push(AppConstants.routeDetalheBadgeRequisitos, extra: badge),
            icon: const Icon(Icons.checklist, size: 18),
            label: Text(ref.t('mobile_badges_ver_requisitos')),
            style: OutlinedButton.styleFrom(
              foregroundColor: D.azul600,
              side: const BorderSide(color: D.azul600),
              padding: const EdgeInsets.symmetric(vertical: D.e3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
            ),
          ),
        ),
      ],
    );
  }

  // Gera o certificado PDF e abre a folha de partilha do sistema
  Future<void> _descarregarCertificado(BuildContext context, WidgetRef ref) async {
    final utilizador = await DatabaseService.instance.getUser();
    if (!context.mounted) return;
    try {
      await gerarEPartilharCertificado(
        nomeConsultor: utilizador?.nome ?? '',
        badge: badge,
        urlBase: AppConstants.filesUrl,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.tr('mobile_badges_erro_certificado'))),
        );
      }
    }
  }

  Future<void> _partilharLinkedIn(BuildContext context, WidgetRef ref) async {
    if (ref.read(utilizadorProvider).value?.aceitouRgpd != true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.tr('mobile_badges_sem_rgpd'))),
        );
      }
      return;
    }
    final urlPublica = AppConstants.urlVerificacaoBadge(badge.tokenValidacao);
    final url = urlPublica != null
        ? 'https://www.linkedin.com/sharing/share-offsite/?url=${Uri.encodeComponent(urlPublica)}'
        : 'https://www.linkedin.com';
    // O canLaunchUrl() pode dar falso negativo em Android/iOS quando a app
    // não declara a query de intents/schemes correspondente, mesmo que o
    // launchUrl() em si funcione perfeitamente — e era exatamente isso que
    // fazia o botão parecer sempre avariado. Tenta abrir diretamente e só
    // mostra o erro se o launchUrl() realmente falhar.
    try {
      final abriu = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!abriu && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.tr('mobile_badges_erro_linkedin'))),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.tr('mobile_badges_erro_linkedin'))),
        );
      }
    }
  }

  Future<void> _abrirPaginaPublica(BuildContext context, WidgetRef ref) async {
    if (ref.read(utilizadorProvider).value?.aceitouRgpd != true) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.tr('mobile_badges_sem_rgpd'))),
        );
      }
      return;
    }
    final urlPublica = AppConstants.urlVerificacaoBadge(badge.tokenValidacao);
    if (urlPublica == null) return;
    // Mesma correção do LinkedIn acima: não confiar no canLaunchUrl().
    try {
      final abriu = await launchUrl(Uri.parse(urlPublica), mode: LaunchMode.externalApplication);
      if (!abriu && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.tr('mobile_badges_erro_pagina'))),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ref.tr('mobile_badges_erro_pagina'))),
        );
      }
    }
  }
}