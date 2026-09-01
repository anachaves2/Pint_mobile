// providers/idioma_provider.dart
// Estado global do idioma atual — equivalente ao IdiomaContext.jsx da Web.
// Carrega o idioma guardado localmente ao arrancar (síncrono para os
// widgets, a leitura do SharedPreferences acontece em segundo plano e
// atualiza o state assim que estiver pronta).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/services/preferencias_service.dart';
import 'package:pint_mobile/utils/traducoes.dart';

const idiomasValidos = ['pt', 'en', 'es'];

class IdiomaNotifier extends Notifier<String> {
  @override
  String build() {
    _carregarGuardado();
    return 'pt'; // idioma por omissão, até o SharedPreferences responder
  }

  Future<void> _carregarGuardado() async {
    final guardado = await PreferenciasService().lerIdioma();
    if (guardado != null && idiomasValidos.contains(guardado)) {
      state = guardado;
    }
  }

  /// Muda o idioma e persiste a escolha. Chamado a partir do dropdown nas
  /// Definições — depois disso, TODOS os ecrãs que usam ref.t(...) atualizam
  /// sozinhos, porque estão a observar (watch) este provider.
  Future<void> mudar(String codigo) async {
    if (!idiomasValidos.contains(codigo)) return;
    state = codigo;
    await PreferenciasService().guardarIdioma(codigo);
  }
}

final idiomaProvider = NotifierProvider<IdiomaNotifier, String>(IdiomaNotifier.new);

/// Atalho para usar nos ecrãs: `ref.t('chave')` em vez de
/// `Traducoes.t(ref.watch(idiomaProvider), 'chave')`. Faz watch, por isso
/// o widget que chamar isto dentro do build() volta a desenhar-se sozinho
/// quando o idioma mudar.
///
/// IMPORTANTE: só usar ref.t(...) dentro de build() (ou de métodos chamados
/// a partir dele). Dentro de callbacks (onPressed, onTap, funções async como
/// _fazerLogin) usar ref.tr(...) em vez disso — watch() fora do build()
/// dá erro em runtime.
extension TraducaoRef on WidgetRef {
  String t(String chave) => Traducoes.t(watch(idiomaProvider), chave);
  String tr(String chave) => Traducoes.t(read(idiomaProvider), chave);
}