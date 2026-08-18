import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/models/requisitos.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';
import 'package:go_router/go_router.dart';

// ECRÃ DETALHE — REQUISITOS DO BADGE
// Faltava por completo: a rota (AppConstants.routeDetalheBadgeRequisitos)
// já existia mas nunca tinha sido registada nem tinha ecrã nenhum a
// apontar para ela. Os dados já estavam prontos (Requisito, getRequisitos()
// já sincronizado do catálogo) — só faltava esta página.

class DetalheBadgeRequisitos extends StatefulWidget {
  final BadgeUtilizador badge;

  const DetalheBadgeRequisitos({super.key, required this.badge});

  @override
  State<DetalheBadgeRequisitos> createState() => _DetalheBadgeRequisitosState();
}

class _DetalheBadgeRequisitosState extends State<DetalheBadgeRequisitos> {
  List<Requisito>? _requisitos;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (widget.badge.idBadgeRegular == null) {
      setState(() => _requisitos = []);
      return;
    }
    final lista = await DatabaseService.instance.getRequisitos(widget.badge.idBadgeRegular!);
    if (mounted) setState(() => _requisitos = lista);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: D.fundo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppConstants.corPrimaria, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text('REQUISITOS', style: D.tituloPagina),
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
      ),
      body: _requisitos == null
          ? const Center(child: CircularProgressIndicator(color: D.azul600))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(D.e4, D.e2, D.e4, D.e5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.badge.nomeBadge, style: D.tituloSeccao),
                  if (widget.badge.nomeNivel != null) ...[
                    const SizedBox(height: 2),
                    Text(widget.badge.nomeNivel!, style: D.legenda),
                  ],
                  const SizedBox(height: D.e5),
                  if (_requisitos!.isEmpty)
                    CardSimples(
                      child: Center(child: Text('Sem requisitos definidos para este badge.', style: D.legenda)),
                    )
                  else
                    for (final r in _requisitos!) _buildCardRequisito(r),
                ],
              ),
            ),
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
                    Text(r.descricao!, style: D.corpo.copyWith(height: 1.4)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}