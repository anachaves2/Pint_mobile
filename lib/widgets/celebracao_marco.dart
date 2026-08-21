import 'package:flutter/material.dart';
import 'package:pint_mobile/utils/design.dart';

// REQUISITO 16 — "Celebração de marcos alcançados"
//
// Deteta o que mudou desde a última vez que a app foi aberta (badges novos,
// badges especiais novos, objetivos alcançados, patamares de pontos) e
// celebra num diálogo.
//
// A comparação é feita contra valores guardados nas preferências
// (PreferenciasService.guardarMarcosVistos). Na primeira utilização não há
// nada guardado — nesse caso apenas se grava a linha de base, sem celebrar,
// para não festejar badges antigos como se fossem novos.

class Marco {
  final IconData icone;
  final String titulo;
  final String mensagem;

  const Marco({required this.icone, required this.titulo, required this.mensagem});
}

class CelebracaoMarco {
  CelebracaoMarco._();

  // Patamares de pontos que valem celebração própria
  static const _patamaresPontos = [100, 250, 500, 1000, 2500];
  // Patamares de nº de badges
  static const _patamaresBadges = [1, 5, 10, 25, 50];

  // Só um diálogo por sessão, para não incomodar a cada regresso ao dashboard
  static bool _jaMostrou = false;
  static void limpar() => _jaMostrou = false;

  /// Compara o estado atual com o anterior e devolve os marcos a celebrar.
  /// Devolve lista vazia quando não há nada de novo.
  static List<Marco> calcular({
    required int badgesAgora,
    required int especiaisAgora,
    required int objetivosAgora,
    required int pontosAgora,
    required int? badgesAntes,
    required int? especiaisAntes,
    required int? objetivosAntes,
    required int? pontosAntes,
  }) {
    // Primeira utilização: sem linha de base, não há nada a comparar
    if (badgesAntes == null || especiaisAntes == null || objetivosAntes == null || pontosAntes == null) {
      return [];
    }

    final marcos = <Marco>[];

    final novosBadges = badgesAgora - badgesAntes;
    if (novosBadges > 0) {
      marcos.add(Marco(
        icone: Icons.military_tech,
        titulo: novosBadges == 1 ? 'Novo badge conquistado!' : '$novosBadges novos badges!',
        mensagem: novosBadges == 1
            ? 'Ganhaste mais um badge. Continua assim!'
            : 'Conquistaste $novosBadges badges desde a última visita.',
      ));
    }

    final novosEspeciais = especiaisAgora - especiaisAntes;
    if (novosEspeciais > 0) {
      marcos.add(Marco(
        icone: Icons.star,
        titulo: 'Conquista especial!',
        mensagem: novosEspeciais == 1
            ? 'Desbloqueaste um badge especial pelo teu percurso.'
            : 'Desbloqueaste $novosEspeciais badges especiais.',
      ));
    }

    final novosObjetivos = objetivosAgora - objetivosAntes;
    if (novosObjetivos > 0) {
      marcos.add(Marco(
        icone: Icons.flag,
        titulo: novosObjetivos == 1 ? 'Objetivo alcançado!' : '$novosObjetivos objetivos alcançados!',
        mensagem: 'Cumpriste o que tinhas proposto. Define o próximo!',
      ));
    }

    // Patamar de badges ultrapassado
    for (final p in _patamaresBadges) {
      if (badgesAntes < p && badgesAgora >= p) {
        marcos.add(Marco(
          icone: Icons.workspace_premium,
          titulo: 'Marco: $p badge${p == 1 ? '' : 's'}!',
          mensagem: p == 1
              ? 'Este é o teu primeiro badge na plataforma.'
              : 'Já somas $p badges conquistados.',
        ));
      }
    }

    // Patamar de pontos ultrapassado
    for (final p in _patamaresPontos) {
      if (pontosAntes < p && pontosAgora >= p) {
        marcos.add(Marco(
          icone: Icons.emoji_events,
          titulo: 'Marco: $p pontos!',
          mensagem: 'Atingiste $p pontos de gamification.',
        ));
      }
    }

    return marcos;
  }

  /// Mostra o diálogo de celebração, se houver marcos e ainda não tiver
  /// sido mostrado nesta sessão.
  static Future<void> mostrar(BuildContext context, List<Marco> marcos) async {
    if (_jaMostrou || marcos.isEmpty || !context.mounted) return;
    _jaMostrou = true;

    await showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rLg)),
        child: Padding(
          padding: const EdgeInsets.all(D.e5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(color: D.avisoBg, shape: BoxShape.circle),
                child: const Icon(Icons.celebration, size: 36, color: D.aviso),
              ),
              const SizedBox(height: D.e4),
              Text('Parabéns!',
                  style: D.tituloSeccao.copyWith(fontSize: 22, color: D.azul600)),
              const SizedBox(height: D.e4),

              // Um cartão por marco alcançado
              for (final m in marcos)
                Padding(
                  padding: const EdgeInsets.only(bottom: D.e2),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(D.e3),
                    decoration: BoxDecoration(
                      color: D.fundoAlt,
                      borderRadius: BorderRadius.circular(D.rMd),
                    ),
                    child: Row(
                      children: [
                        Icon(m.icone, color: D.azul600, size: 22),
                        const SizedBox(width: D.e3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.titulo, style: D.tituloCard),
                              const SizedBox(height: 2),
                              Text(m.mensagem, style: D.legenda),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: D.e4),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: D.azul600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: D.e3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(D.rSm)),
                  ),
                  child: const Text('Boa!', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}