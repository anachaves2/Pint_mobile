import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pint_mobile/models/notificacao.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:go_router/go_router.dart';

 
// ============================================================================
// DetalheNotificacaoScreen — Ecrãs 48 a 52
//
// Mostra o detalhe completo de uma notificação.
// Recebe o objeto Notificacao como argumento de navegação.
// Tem botão Eliminar que remove a notificação e volta atrás.
// ============================================================================
 
class DetalheNotificacaoScreen extends StatelessWidget {
  final Notificacao notificacao;
  const DetalheNotificacaoScreen({super.key, required this.notificacao});
 
  // ── Configuração visual por tipo ──
  static const Map<String, _TipoConfig> _configs = {
    'Badge Atribuido': _TipoConfig(
      icone: Icons.verified,
      cor: AppConstants.corSucesso,
      titulo: 'Badge Aprovado',
      tag: 'Aprovado',
    ),
    'Evidencias Aprovadas': _TipoConfig(
      icone: Icons.check_circle_outline,
      cor: AppConstants.corSucesso,
      titulo: 'Evidências Aprovadas',
      tag: 'Correto',
    ),
    'Objetivo Alcancado': _TipoConfig(
      icone: Icons.emoji_events_outlined,
      cor: AppConstants.corSucesso,
      titulo: 'Objetivo Alcançado',
      tag: 'Concluído',
    ),
    'Candidatura Devolvida': _TipoConfig(
      icone: Icons.warning_amber_outlined,
      cor: Color(0xFFF59E0B),
      titulo: 'Candidatura Devolvida',
      tag: 'Incorreto',
    ),
    'Badge a Expirar': _TipoConfig(
      icone: Icons.timer_outlined,
      cor: Color(0xFFF59E0B),
      titulo: 'Badge a Expirar',
      tag: 'Atenção',
    ),
    'Badge Rejeitado': _TipoConfig(
      icone: Icons.cancel_outlined,
      cor: AppConstants.corErro,
      titulo: 'Badge Rejeitado',
      tag: 'Rejeitado',
    ),
  };
 
  static _TipoConfig _configPara(String tipo) {
    return _configs[tipo] ??
        const _TipoConfig(
          icone: Icons.notifications_outlined,
          cor: AppConstants.corPrimaria,
          titulo: 'Notificação',
          tag: null,
        );
  }
 
  Future<void> _eliminar(BuildContext context, Notificacao n) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar notificação'),
        content: const Text('Tem a certeza que pretende eliminar esta notificação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.corErro,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
 
    if (confirmar == true) {
      final resultado = await APIService.instance.eliminarNotificacao(n.id);
      if (context.mounted) {
        if (resultado.sucesso) {
          Navigator.pop(context); // volta à lista
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(resultado.erro ?? 'Erro ao eliminar notificação.'),
              backgroundColor: AppConstants.corErro,
            ),
          );
        }
      }
    }
  }
 
  @override
  Widget build(BuildContext context) {
    // Recebe o objeto Notificacao via arguments
    final config = _configPara(notificacao.tipoNotificacao);
    final dataFmt =
        DateFormat('dd-MM-yyyy  HH:mm').format(notificacao.data);
 
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppConstants.corPrimaria),
        title: const Text(
          'Notificações',
          style: TextStyle(color: AppConstants.corPrimaria, fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cabeçalho ──
            Text(
              dataFmt,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 16),
 
            // ── Título com ícone e tag ──
            Row(
              children: [
                Icon(config.icone, color: config.cor, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    config.titulo,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                if (config.tag != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: config.cor.withValues(alpha:0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(config.icone, color: config.cor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          config.tag!,
                          style: TextStyle(
                            fontSize: 12,
                            color: config.cor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
 
            // ── Corpo da notificação ──
            Text(
              notificacao.descricao ?? '',
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
 
            // ── Ação contextual (se tiver candidatura ou badge associado) ──
            if (notificacao.numCandidatura != null)
              _buildAcao(
                context: context,
                label: 'Ver candidatura',
                icone: Icons.assignment_outlined,
                onTap: () => context.push(AppConstants.routeDetalheCandidatura, extra: notificacao.numCandidatura),
              ),
 
            if (notificacao.idBadgeUtilizador != null)
              _buildAcao(
                context: context,
                label: 'Ver badge',
                icone: Icons.workspace_premium_outlined,
                onTap: () => context.push(AppConstants.routeDetalheBadge, extra: notificacao.idBadgeUtilizador),
              ),
 
            if (notificacao.idObjetivo != null)
              _buildAcao(
                context: context,
                label: 'Ver objetivos',
                icone: Icons.track_changes_outlined,
                onTap: () => context.push(AppConstants.routeObjetivos),
              ),
 
            const SizedBox(height: 16),
 
            // ── Botão Eliminar ──
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _eliminar(context, notificacao),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppConstants.corErro),
                  foregroundColor: AppConstants.corErro,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.delete_outline),
                label: const Text(
                  'Eliminar',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  // Botão de ação contextual (ver candidatura, ver badge, etc.)
  Widget _buildAcao({
    required BuildContext context,
    required String label,
    required IconData icone,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppConstants.corPrimaria.withValues(alpha:0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppConstants.corPrimaria.withValues(alpha:0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(icone, color: AppConstants.corPrimaria, size: 20),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: AppConstants.corPrimaria,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right,
                  color: AppConstants.corPrimaria, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
 
class _TipoConfig {
  final IconData icone;
  final Color cor;
  final String titulo;
  final String? tag;
  const _TipoConfig({
    required this.icone,
    required this.cor,
    required this.titulo,
    required this.tag,
  });
}