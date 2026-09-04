// utils/assinatura_email.dart
// "Adicionar à assinatura de email" — equivalente mobile do
// ModalAssinaturaEmail.jsx da Web (bónus 12/23 do enunciado).
//
// Uma assinatura de email é HTML que se cola no Outlook/Gmail, não um PDF —
// por isso gera-se aqui o mesmo bloco HTML que a Web gera (imagem do badge
// ligada à página pública de verificação) e copia-se para a área de
// transferência, para o consultor colar diretamente no cliente de email.
// No mobile não há edição de assinatura como no desktop, por isso o fluxo é
// só "gerar + copiar", sem o preview renderizado que a Web mostra.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/design.dart';

/// Gera o bloco HTML de assinatura de email para um único badge — mesmo
/// formato usado na Web (construirHtmlAssinatura em ModalAssinaturaEmail.jsx).
String gerarHtmlAssinaturaBadge({
  required String nome,
  required String cargo,
  required BadgeUtilizador badge,
}) {
  final url = AppConstants.urlVerificacaoBadge(badge.tokenValidacao) ?? '';
  final img = AppConstants.resolverUrlFicheiro(badge.urlImagem);

  final blocoBadge = img != null
      ? '<a href="$url" target="_blank" style="text-decoration:none;">'
          '<img src="$img" alt="${badge.nomeBadge}" title="${badge.nomeBadge}" '
          'width="48" height="48" style="border:0;vertical-align:middle;" />'
          '</a>'
      : '<a href="$url" target="_blank" style="color:#39639C;font-size:12px;">'
          '${badge.nomeBadge}</a>';

  return '<table cellpadding="0" cellspacing="0" '
      'style="font-family:Arial,Helvetica,sans-serif;color:#1a1a2e;">'
      '<tr><td style="padding-bottom:6px;">'
      '<strong style="font-size:15px;color:#39639C;">$nome</strong><br/>'
      '<span style="font-size:12px;color:#6b7280;">$cargo &middot; Softinsa</span>'
      '</td></tr>'
      '<tr><td style="padding-top:8px;border-top:1px solid #e5e7eb;">'
      '$blocoBadge'
      '</td></tr>'
      '<tr><td style="padding-top:6px;">'
      '<span style="font-size:10px;color:#9ca3af;">softinsa.pt</span>'
      '</td></tr>'
      '</table>';
}

/// Mostra o diálogo com o HTML gerado e um botão "Copiar" — para o
/// consultor colar no Outlook/Gmail.
Future<void> mostrarDialogAssinaturaEmail(
  BuildContext context,
  WidgetRef ref,
  BadgeUtilizador badge,
) async {
  final utilizador = await DatabaseService.instance.getUser();
  if (!context.mounted) return;

  final html = gerarHtmlAssinaturaBadge(
    nome: utilizador?.nome ?? '',
    cargo: ref.t('mobile_badges_assinatura_cargo'),
    badge: badge,
  );

  bool copiado = false;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: D.superficie,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rLg)),
        title: Text(ref.t('mobile_badges_assinatura_titulo'), style: D.tituloSeccao),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(ref.t('mobile_badges_assinatura_desc'), style: D.legenda),
            const SizedBox(height: D.e3),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(D.e3),
              decoration: BoxDecoration(
                color: D.fundoAlt,
                borderRadius: BorderRadius.circular(D.rMd),
              ),
              child: Text(
                html,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: D.tinta50),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ref.t('mobile_badges_assinatura_fechar')),
          ),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: html));
              setState(() => copiado = true);
            },
            style: FilledButton.styleFrom(backgroundColor: D.azul600),
            icon: Icon(copiado ? Icons.check : Icons.copy, size: 18),
            label: Text(copiado
                ? ref.t('mobile_badges_assinatura_copiado')
                : ref.t('mobile_badges_assinatura_copiar')),
          ),
        ],
      ),
    ),
  );
}