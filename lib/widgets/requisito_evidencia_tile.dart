import 'package:flutter/material.dart';
import 'package:pint_mobile/models/requisitos.dart';
import 'package:pint_mobile/utils/design.dart';
import 'package:pint_mobile/widgets/card_gradiente.dart';
import 'package:pint_mobile/widgets/texto_traduzido.dart';

// Cartão de requisito com upload de evidência (ficheiro ou câmara).
// Partilhado entre nova_candidatura_screen.dart (candidatura nova) e o
// fluxo de "Rever Candidatura" em detalhes_candidaturas_screen.dart
// (retificação de uma candidatura já submetida) — antes estava só
// implementado no primeiro, o segundo não existia.

class RequisitoEvidenciaTile extends StatelessWidget {
  final Requisito requisito;
  final bool temEvidencia;
  final bool emUpload;
  final String? nomeFicheiro;
  final VoidCallback onEscolherFicheiro;
  final VoidCallback onTirarFoto;

  const RequisitoEvidenciaTile({
    super.key,
    required this.requisito,
    required this.temEvidencia,
    required this.emUpload,
    required this.nomeFicheiro,
    required this.onEscolherFicheiro,
    required this.onTirarFoto,
  });

  @override
  Widget build(BuildContext context) {
    return CardSimples(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(requisito.nome, style: D.tituloCard),
          if (requisito.descricao != null && requisito.descricao!.isNotEmpty) ...[
            const SizedBox(height: 2),
            TextoTraduzido(texto: requisito.descricao, style: D.legenda),
          ],
          const SizedBox(height: D.e3),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: temEvidencia ? D.okBg : D.fundoAlt,
                  borderRadius: BorderRadius.circular(D.rSm),
                ),
                child: emUpload
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2, color: D.azul600),
                      )
                    : Icon(
                        temEvidencia ? Icons.check_circle : Icons.insert_drive_file_outlined,
                        color: temEvidencia ? D.ok : D.tinta30,
                        size: 24,
                      ),
              ),
              const SizedBox(width: D.e3),
              Expanded(
                child: Text(
                  nomeFicheiro ?? 'Clica para carregar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: D.legenda.copyWith(color: nomeFicheiro != null ? D.tinta50 : D.tinta30),
                ),
              ),
              GestureDetector(
                onTap: emUpload ? null : onEscolherFicheiro,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: temEvidencia ? D.fundoAlt : D.azul600,
                    borderRadius: BorderRadius.circular(D.rSm),
                  ),
                  child: Icon(
                    temEvidencia ? Icons.refresh : Icons.upload_outlined,
                    size: 18,
                    color: temEvidencia ? D.tinta50 : Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: emUpload ? null : onTirarFoto,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: D.azul100, borderRadius: BorderRadius.circular(D.rSm)),
                  child: const Icon(Icons.camera_alt_outlined, size: 18, color: D.azul600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}