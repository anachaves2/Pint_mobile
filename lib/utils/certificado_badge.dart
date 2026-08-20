import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/utils/constants.dart';

// Gera o certificado PDF de um badge obtido — equivalente ao
// utils/certificadoBadge.js da web: A4 retrato, moldura dupla, texto
// formal centrado e nº de registo + link de validação no rodapé.
//
// Requer as dependências `pdf` e `printing` no pubspec.yaml.

const _azulMarinho = PdfColor.fromInt(0xFF162642);
const _azulSoftinsa = PdfColor.fromInt(0xFF39639C);
const _azulClaro = PdfColor.fromInt(0xFF8CAAD2);
const _cinzaTexto = PdfColor.fromInt(0xFF5A5A5A);

String _formatarData(DateTime? data) {
  if (data == null) return '—';
  const meses = [
    'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
    'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro'
  ];
  return '${data.day} de ${meses[data.month - 1]} de ${data.year}';
}

Future<Uint8List> construirCertificado({
  required String nomeConsultor,
  required BadgeUtilizador badge,
  required String urlBase,
}) async {
  final doc = pw.Document();

  final detalhes = [badge.nomeServiceLine, badge.nomeArea, badge.nomeNivel]
      .where((s) => s != null && s.isNotEmpty)
      .join(' · ');

  // Construída a partir do token — o campo urlPublico da BD aponta para um
  // domínio de exemplo que não existe.
  final urlVerificacao = AppConstants.urlVerificacaoBadge(badge.tokenValidacao);

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      build: (context) {
        return pw.Stack(
          children: [
            // ── Moldura dupla ──
            pw.Positioned.fill(
              child: pw.Container(
                margin: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _azulMarinho, width: 2),
                ),
              ),
            ),
            pw.Positioned.fill(
              child: pw.Container(
                margin: const pw.EdgeInsets.all(13),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: _azulClaro, width: 1),
                ),
              ),
            ),

            // ── Conteúdo ──
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(40, 44, 40, 40),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  pw.Text('SOFTINSA',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: _azulSoftinsa,
                        letterSpacing: 1.5,
                      )),
                  pw.SizedBox(height: 44),

                  pw.Center(
                    child: pw.Text('CERTIFICADO',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: _azulMarinho,
                        )),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Center(
                    child: pw.Container(width: 60, height: 2, color: _azulSoftinsa),
                  ),
                  pw.SizedBox(height: 40),

                  pw.Center(child: pw.Text('Certifica-se que', style: pw.TextStyle(fontSize: 12, color: _cinzaTexto))),
                  pw.SizedBox(height: 14),
                  pw.Center(
                    child: pw.Text(nomeConsultor,
                        style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: _azulMarinho)),
                  ),
                  pw.SizedBox(height: 14),
                  pw.Center(child: pw.Text('obteve o badge', style: pw.TextStyle(fontSize: 12, color: _cinzaTexto))),
                  pw.SizedBox(height: 14),
                  pw.Center(
                    child: pw.Text(badge.nomeBadge,
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(fontSize: 19, fontWeight: pw.FontWeight.bold, color: _azulSoftinsa)),
                  ),

                  if (detalhes.isNotEmpty) ...[
                    pw.SizedBox(height: 12),
                    pw.Center(child: pw.Text(detalhes, style: pw.TextStyle(fontSize: 11, color: _cinzaTexto))),
                  ],

                  if (badge.descricao != null && badge.descricao!.isNotEmpty) ...[
                    pw.SizedBox(height: 12),
                    pw.Center(
                      child: pw.Text(badge.descricao!,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(fontSize: 10, color: _cinzaTexto)),
                    ),
                  ],

                  pw.SizedBox(height: 14),
                  pw.Center(
                    child: pw.Text('Atribuído em ${_formatarData(badge.dataAtribuicao)}',
                        style: pw.TextStyle(fontSize: 10, color: _cinzaTexto)),
                  ),

                  pw.Spacer(),

                  // ── "Assinatura" institucional ──
                  pw.Center(
                    child: pw.Column(children: [
                      pw.Container(width: 130, height: 1, color: PdfColors.grey500),
                      pw.SizedBox(height: 6),
                      pw.Text('Softinsa',
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _azulMarinho)),
                      pw.Text('Plataforma de Badges', style: pw.TextStyle(fontSize: 9, color: _cinzaTexto)),
                    ]),
                  ),

                  pw.SizedBox(height: 34),

                  // ── Rodapé ──
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Emitido em ${_formatarData(DateTime.now())}',
                              style: pw.TextStyle(fontSize: 9, color: _cinzaTexto)),
                          pw.Text('Válido até ${_formatarData(badge.dataExpiracao)}',
                              style: pw.TextStyle(fontSize: 9, color: _cinzaTexto)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('REGISTO N.º ${badge.id}',
                              style: pw.TextStyle(fontSize: 8, color: _cinzaTexto)),
                          if (urlVerificacao != null)
                            pw.UrlLink(
                              destination: urlVerificacao,
                              child: pw.Text('Validar certificado',
                                  style: pw.TextStyle(fontSize: 8, color: _azulSoftinsa)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ),
  );

  return doc.save();
}

/// Gera e abre a folha nativa de partilha/impressão do sistema, onde o
/// utilizador pode guardar o PDF, enviá-lo ou imprimi-lo.
Future<void> gerarEPartilharCertificado({
  required String nomeConsultor,
  required BadgeUtilizador badge,
  required String urlBase,
}) async {
  final bytes = await construirCertificado(
    nomeConsultor: nomeConsultor,
    badge: badge,
    urlBase: urlBase,
  );

  await Printing.sharePdf(
    bytes: bytes,
    filename: 'certificado_${badge.nomeBadge.replaceAll(' ', '_')}.pdf',
  );
}