import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/notificacao.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/utils/notificacao_utils.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';
import 'package:pint_mobile/providers/badges_provider.dart';
import 'package:go_router/go_router.dart';

// ============================================================================
// DetalheNotificacaoScreen
//
// Mostra o detalhe completo de uma notificação. Recebe o objeto Notificacao
// como argumento de navegação. Tem "Marcar como não lida" (só se já estiver
// lida — igual à web) e "Eliminar". Segue os tokens D.
// ============================================================================

class DetalheNotificacaoScreen extends ConsumerStatefulWidget {
  final Notificacao notificacao;
  const DetalheNotificacaoScreen({super.key, required this.notificacao});

  @override
  ConsumerState<DetalheNotificacaoScreen> createState() => _DetalheNotificacaoScreenState();
}

class _DetalheNotificacaoScreenState extends ConsumerState<DetalheNotificacaoScreen> {
  late bool _lida;

  @override
  void initState() {
    super.initState();
    _lida = widget.notificacao.lida;
  }

  Future<void> _eliminar() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar notificação'),
        content: const Text('Tem a certeza que pretende eliminar esta notificação?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: D.erro),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      final resultado = await APIService.instance.eliminarNotificacao(widget.notificacao.id);
      if (context.mounted) {
        if (resultado.sucesso) {
          Navigator.pop(context);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado.erro ?? 'Erro ao eliminar notificação.'),
              backgroundColor: D.erro,
            ),
          );
        }
      }
    }
  }

  Future<void> _marcarComoNaoLida() async {
    await APIService.instance.marcarNotificacaoNaoLida(widget.notificacao.id);
    if (mounted) setState(() => _lida = false);
  }

  @override
  Widget build(BuildContext context) {
    final notificacao = widget.notificacao;
    final config = NotificacaoUtils.configPara(notificacao.tipoNotificacao);
    final dataFmt =
        '${notificacao.data.day.toString().padLeft(2, '0')}-${notificacao.data.month.toString().padLeft(2, '0')}-${notificacao.data.year}  '
        '${notificacao.data.hour.toString().padLeft(2, '0')}:${notificacao.data.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: D.fundo,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppConstants.corPrimaria),
        title: const Text('NOTIFICAÇÃO', style: D.tituloPagina),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(D.e5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(dataFmt, style: D.legenda),
            const SizedBox(height: D.e4),

            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: config.corFundo, borderRadius: BorderRadius.circular(D.rMd)),
                  child: Icon(config.icone, color: config.cor, size: 22),
                ),
                const SizedBox(width: D.e3),
                Expanded(child: Text(config.titulo, style: D.tituloSeccao)),
              ],
            ),
            const SizedBox(height: D.e5),

            Text(
              notificacao.descricao ?? '',
              style: D.corpo.copyWith(fontSize: 15, color: D.tinta, height: 1.6),
            ),
            const SizedBox(height: D.e6),

            if (notificacao.numCandidatura != null)
              _buildAcao(
                label: 'Ver candidatura',
                icone: Icons.assignment_outlined,
                onTap: () => context.push(AppConstants.routeDetalheCandidatura, extra: notificacao.numCandidatura),
              ),

            if (notificacao.idBadgeUtilizador != null)
              _buildAcao(
                label: 'Ver badge',
                icone: Icons.workspace_premium_outlined,
                onTap: () {
                  final badges = ref.read(badgesProvider).valueOrNull ?? [];
                  final badge = badges.where((b) => b.id == notificacao.idBadgeUtilizador).firstOrNull;
                  if (badge != null) {
                    context.push(AppConstants.routeDetalheBadge, extra: badge);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Badge não encontrado.')),
                    );
                  }
                },
              ),

            if (notificacao.idObjetivo != null)
              _buildAcao(
                label: 'Ver objetivos',
                icone: Icons.track_changes_outlined,
                onTap: () => context.push(AppConstants.routeObjetivos),
              ),

            const SizedBox(height: D.e3),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _eliminar,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: D.erro),
                      foregroundColor: D.erro,
                      padding: const EdgeInsets.symmetric(vertical: D.e3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Eliminar', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                if (_lida) ...[
                  const SizedBox(width: D.e2),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _marcarComoNaoLida,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: D.azul600),
                        foregroundColor: D.azul600,
                        padding: const EdgeInsets.symmetric(vertical: D.e3),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
                      ),
                      icon: const Icon(Icons.markunread_outlined, size: 18),
                      label: const Text('Não lida', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcao({required String label, required IconData icone, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: D.e2),
      child: CardSimples(
        onTap: onTap,
        child: Row(
          children: [
            Icon(icone, color: D.azul600, size: 20),
            const SizedBox(width: D.e3),
            Text(label, style: const TextStyle(color: D.azul600, fontWeight: FontWeight.w600, fontSize: 14)),
            const Spacer(),
            const Icon(Icons.chevron_right, color: D.azul600, size: 20),
          ],
        ),
      ),
    );
  }
}