// widgets/texto_traduzido.dart
// Substituto direto do Text() para texto vindo da base de dados — traduz
// automaticamente para o idioma atual da app (ver traducao_texto.dart).
//
// Uso: em vez de
//   Text(badge.descricao, style: D.corpo)
// usa
//   TextoTraduzido(texto: badge.descricao, style: D.corpo)
//
// Enquanto a tradução não chega, mostra o texto original em português
// (nunca fica em branco). Atualiza-se sozinho quando o idioma muda.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/providers/idioma_provider.dart';
import 'package:pint_mobile/utils/traducao_texto.dart';

class TextoTraduzido extends ConsumerWidget {
  final String? texto;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const TextoTraduzido({
    super.key,
    required this.texto,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idioma = ref.watch(idiomaProvider);

    if (texto == null || texto!.isEmpty) {
      return Text('', style: style, textAlign: textAlign);
    }

    return FutureBuilder<String>(
      key: ValueKey('$idioma:$texto'),
      future: TraducaoTexto.traduzir(texto, idioma),
      initialData: texto,
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? texto!,
          style: style,
          textAlign: textAlign,
          maxLines: maxLines,
          overflow: overflow,
        );
      },
    );
  }
}