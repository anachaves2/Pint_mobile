// utils/traducao_texto.dart
// Tradução automática de texto vindo da base de dados (descrições de
// badges, requisitos, avisos, comentários) — equivalente ao
// traducaoTexto.js da Web. Diferente do t()/ref.t() do idioma_provider,
// que só traduz texto fixo da interface escrito por nós.
//
// Usa a MyMemory Translation API (mymemory.translated.net) — gratuita,
// sem chave nem conta, sem nada a configurar. Tem um limite por pedido
// (~500 caracteres) — texto mais longo (ex.: política de privacidade)
// pode falhar em silêncio e ficar em português.
//
// Cache em memória: a mesma frase só é traduzida uma vez por sessão da
// app (evita pedidos repetidos ao mudar de ecrã).

import 'dart:convert';
import 'package:http/http.dart' as http;

class TraducaoTexto {
  TraducaoTexto._();

  static final Map<String, String> _cache = {};

  static Future<String> traduzir(String? texto, String idiomaDestino) async {
    if (texto == null || texto.isEmpty || idiomaDestino == 'pt') return texto ?? '';

    final chave = '$idiomaDestino:$texto';
    final emCache = _cache[chave];
    if (emCache != null) return emCache;

    try {
      final url = Uri.parse(
        'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(texto)}&langpair=pt|$idiomaDestino',
      );
      final resposta = await http.get(url);
      final dados = jsonDecode(resposta.body) as Map<String, dynamic>;
      final traduzido = dados['responseData']?['translatedText'] as String?;

      // A API às vezes devolve um aviso de limite dentro de um texto
      // válido-parecido — se vier vazio ou for claramente um erro, mantém
      // o original em vez de mostrar lixo ao utilizador.
      if (traduzido != null && traduzido.isNotEmpty && !traduzido.toUpperCase().contains('MYMEMORY WARNING')) {
        _cache[chave] = traduzido;
        return traduzido;
      }
    } catch (e) {
      // Falha silenciosa: mostra o texto original em português.
    }

    return texto;
  }
}