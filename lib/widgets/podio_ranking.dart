import 'package:flutter/material.dart';
import 'package:pint_mobile/utils/design.dart';

/// Uma posição do pódio.
class PodioEntrada {
  const PodioEntrada({
    required this.posicao,
    required this.nome,
    required this.pontos,
    this.urlFoto,
    this.destacado = false,
  });

  final int posicao; // 1, 2 ou 3
  final String nome;
  final int pontos;
  final String? urlFoto;

  /// Marca a entrada do próprio utilizador, para se distinguir na lista.
  final bool destacado;
}

/// Pódio do ranking — mesma estrutura visual do da web
/// (serviceline/Gamification.jsx): barras com gradiente e brilho próprio,
/// círculos a flutuar por cima com anel branco, alturas diferenciadas.
///
/// A ordem visual é 2º — 1º — 3º, com o primeiro ao centro e mais alto.
class PodioRanking extends StatelessWidget {
  const PodioRanking({super.key, required this.entradas});

  /// Até 3 entradas. Se vierem menos, os lugares em falta não são desenhados.
  final List<PodioEntrada> entradas;

  PodioEntrada? _porPosicao(int p) {
    for (final e in entradas) {
      if (e.posicao == p) return e;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final primeiro = _porPosicao(1);
    final segundo = _porPosicao(2);
    final terceiro = _porPosicao(3);

    return Padding(
      // espaço em cima para os círculos que sobressaem das barras
      padding: const EdgeInsets.only(top: 32, left: D.e2, right: D.e2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: _Lugar(entrada: segundo, posicao: 2)),
          const SizedBox(width: D.e2),
          Expanded(child: _Lugar(entrada: primeiro, posicao: 1)),
          const SizedBox(width: D.e2),
          Expanded(child: _Lugar(entrada: terceiro, posicao: 3)),
        ],
      ),
    );
  }
}

class _Lugar extends StatelessWidget {
  const _Lugar({required this.entrada, required this.posicao});

  final PodioEntrada? entrada;
  final int posicao;

  @override
  Widget build(BuildContext context) {
    if (entrada == null) return const SizedBox.shrink();

    final ehPrimeiro = posicao == 1;

    final gradiente = switch (posicao) {
      1 => D.podio1Grad,
      2 => D.podio2Grad,
      _ => D.podio3Grad,
    };
    final brilho = switch (posicao) {
      1 => D.podio1Brilho,
      2 => D.podio2Brilho,
      _ => D.podio3Brilho,
    };
    final altura = switch (posicao) {
      1 => D.podio1Altura,
      2 => D.podio2Altura,
      _ => D.podio3Altura,
    };

    final tamanhoCirculo = ehPrimeiro ? 52.0 : 44.0;
    final anel = ehPrimeiro ? 4.0 : 3.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Nome e pontos por cima da barra
        Text(
          entrada!.nome,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: ehPrimeiro ? 13 : 12,
            fontWeight: FontWeight.w600,
            color: entrada!.destacado ? D.azul600 : D.tinta,
          ),
        ),
        const SizedBox(height: 2),
        Text('${entrada!.pontos} pts',
            style: D.legenda.copyWith(fontSize: 11)),
        const SizedBox(height: D.e2),

        // Barra + círculo sobreposto
        // Clip.none deixa o círculo sair para fora dos limites da Stack
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              height: altura,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: gradiente,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(D.rSm)),
                boxShadow: brilho,
              ),
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: D.e2),
              child: Text(
                '$posicaoº',
                style: TextStyle(
                  fontSize: ehPrimeiro ? 15 : 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            // Círculo a flutuar por cima do topo da barra
            Positioned(
              top: ehPrimeiro ? -24 : -20,
              child: Container(
                width: tamanhoCirculo,
                height: tamanhoCirculo,
                decoration: BoxDecoration(
                  color: D.podioCirculoBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: anel),
                  boxShadow: D.elev1,
                ),
                clipBehavior: Clip.antiAlias,
                child: entrada!.urlFoto != null &&
                        entrada!.urlFoto!.isNotEmpty
                    ? Image.network(
                        entrada!.urlFoto!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _iniciais(),
                      )
                    : _iniciais(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _iniciais() {
    final partes = entrada!.nome.trim().split(RegExp(r'\s+'));
    final txt = partes.length >= 2
        ? '${partes.first[0]}${partes.last[0]}'
        : (partes.first.isNotEmpty ? partes.first[0] : '?');

    return Center(
      child: Text(
        txt.toUpperCase(),
        style: TextStyle(
          fontSize: posicao == 1 ? 16 : 14,
          fontWeight: FontWeight.bold,
          color: D.podioCirculoTexto,
        ),
      ),
    );
  }
}