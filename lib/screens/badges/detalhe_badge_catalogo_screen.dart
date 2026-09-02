import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/badge_regular.dart';
import 'package:pint_mobile/models/requisitos.dart';
import 'package:pint_mobile/providers/badges_provider.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/utils/badge_utils.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';
import 'package:pint_mobile/widgets/texto_traduzido.dart';
import 'package:go_router/go_router.dart';

// ECRÃ DETALHE — BADGE DO CATÁLOGO
// Mostra a descrição completa e os requisitos de um badge do catálogo
// (ainda não necessariamente obtido) e permite candidatar-se diretamente
// — salta para a fase de evidências do fluxo de Nova Candidatura já
// existente, sem obrigar a escolher o badge outra vez.

class DetalheBadgeCatalogo extends ConsumerStatefulWidget {
  final BadgeRegular badge;

  const DetalheBadgeCatalogo({super.key, required this.badge});

  @override
  ConsumerState<DetalheBadgeCatalogo> createState() => _DetalheBadgeCatalogoState();
}

class _DetalheBadgeCatalogoState extends ConsumerState<DetalheBadgeCatalogo> {
  List<Requisito>? _requisitos;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final lista = await DatabaseService.instance.getRequisitos(widget.badge.id);
    if (mounted) setState(() => _requisitos = lista);
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.badge;
    final badgesObtidos = ref.watch(badgesProvider).valueOrNull ?? [];
    final jaObtido = badgesObtidos.any((b) => b.valido && b.idBadgeRegular == badge.id);
    final cor = jaObtido ? D.ok : BadgeUtils.corDoNivel(badge.nomeNivel);

    return Scaffold(
      backgroundColor: D.fundo,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: D.e5, vertical: D.e5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildIconeBadge(cor, jaObtido),
            const SizedBox(height: D.e4),
            Text(badge.nome, style: D.tituloSeccao.copyWith(fontSize: 20), textAlign: TextAlign.center),
            const SizedBox(height: D.e2),
            Text(badge.nomeNivel, style: D.legenda),
            const SizedBox(height: D.e5),

            _buildSecaoInfo(badge),
            if (badge.descricao != null) ...[
              const SizedBox(height: D.e4),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(D.e4),
                decoration: BoxDecoration(color: D.fundoAlt, borderRadius: BorderRadius.circular(D.rLg)),
                child: TextoTraduzido(texto: badge.descricao, style: D.corpo.copyWith(height: 1.5)),
              ),
            ],

            const SizedBox(height: D.e5),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(ref.t('mobile_geral_requisitos_maiusc'), style: D.etiqueta),
            ),
            const SizedBox(height: D.e3),
            _buildRequisitos(),

            const SizedBox(height: D.e6),
            _buildBotaoAcao(context, jaObtido),
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
      title: Text(ref.t('mobile_catalogo_titulo'), style: D.tituloPagina),
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

  Widget _buildIconeBadge(Color cor, bool jaObtido) {
    final letra = widget.badge.nomeNivel.isNotEmpty ? widget.badge.nomeNivel[0].toUpperCase() : '?';

    Widget conteudo = jaObtido
        ? const Icon(Icons.check, color: D.ok, size: 38)
        : Text(letra, style: TextStyle(color: cor, fontWeight: FontWeight.bold, fontSize: 38));

    if (widget.badge.urlImagem != null) {
      return Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: cor, width: 3)),
        child: ClipOval(
          child: Image.network(
            AppConstants.resolverUrlFicheiro(widget.badge.urlImagem)!,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: cor.withValues(alpha: 0.15),
              child: Center(child: conteudo),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cor.withValues(alpha: 0.15),
        border: Border.all(color: cor, width: 3),
      ),
      child: Center(child: conteudo),
    );
  }

  Widget _buildSecaoInfo(BadgeRegular badge) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(D.e4),
      decoration: BoxDecoration(color: D.fundoAlt, borderRadius: BorderRadius.circular(D.rLg)),
      child: Column(
        children: [
          _buildLinhaInfo(ref.t('mobile_badges_service_line'), badge.nomeServiceLine),
          const SizedBox(height: D.e2),
          _buildLinhaInfo(ref.t('mobile_badges_area'), badge.nomeArea),
          const SizedBox(height: D.e2),
          _buildLinhaInfo(ref.t('mobile_dash_gamification_titulo'), '${badge.pontos ?? 0} ${ref.t('mobile_ranking_pontos')}', destaque: true),
          if (badge.validadeDias != null) ...[
            const SizedBox(height: D.e2),
            _buildLinhaInfo(ref.t('mobile_catalogo_validade'), '${badge.validadeDias} ${ref.t('mobile_catalogo_dias')}'),
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
        Text(valor, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: destaque ? D.azul600 : D.tinta)),
      ],
    );
  }

  Widget _buildRequisitos() {
    if (_requisitos == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: D.e3),
        child: Center(child: CircularProgressIndicator(color: D.azul600)),
      );
    }
    if (_requisitos!.isEmpty) {
      return CardSimples(
        child: Center(child: Text(ref.t('mobile_catalogo_sem_requisitos'), style: D.legenda)),
      );
    }
    return Column(
      children: [for (final r in _requisitos!) _buildCardRequisito(r)],
    );
  }

  Widget _buildCardRequisito(Requisito r) {
    return Padding(
      padding: const EdgeInsets.only(bottom: D.e2),
      child: CardSimples(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: D.azul100, borderRadius: BorderRadius.circular(D.rSm)),
              child: const Icon(Icons.check, size: 16, color: D.azul600),
            ),
            const SizedBox(width: D.e3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(r.nome, style: D.tituloCard),
                  if (r.descricao != null && r.descricao!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    TextoTraduzido(texto: r.descricao, style: D.corpo.copyWith(height: 1.4)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotaoAcao(BuildContext context, bool jaObtido) {
    if (jaObtido) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: D.e3),
        decoration: BoxDecoration(color: D.okBg, borderRadius: BorderRadius.circular(D.rSm)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: D.ok, size: 18),
            const SizedBox(width: D.e2),
            Text(ref.t('mobile_catalogo_ja_tens'), style: const TextStyle(color: D.ok, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => context.push(AppConstants.routeNovaCandidatura, extra: widget.badge),
        icon: const Icon(Icons.send_outlined, size: 18),
        label: Text(ref.t('mobile_catalogo_candidatar')),
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