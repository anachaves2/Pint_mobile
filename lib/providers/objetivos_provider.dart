import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/objetivo.dart';
import 'package:pint_mobile/models/tipo_objetivo.dart';
import 'package:pint_mobile/services/database_service.dart';

/// Gere a lista de objetivos do consultor.
/// Segue o mesmo padrão do candidaturasProvider: lê do SQLite no build(),
/// e o ecrã sincroniza com a API antes de invalidar quando precisa de dados frescos.
class ObjetivosNotifier extends AsyncNotifier<List<Objetivo>> {
  @override
  Future<List<Objetivo>> build() async {
    return await DatabaseService.instance.getObjetivos();
  }

  /// Recarrega do SQLite — todos os ecrãs que observam este provider atualizam.
  Future<void> atualizar() async {
    state = const AsyncValue.loading();
    try {
      final lista = await DatabaseService.instance.getObjetivos();
      state = AsyncValue.data(lista);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  /// Limpa a lista no logout, para não mostrar dados de outro utilizador.
  void limpar() {
    state = const AsyncValue.data([]);
  }
}

final objetivosProvider =
    AsyncNotifierProvider<ObjetivosNotifier, List<Objetivo>>(
        ObjetivosNotifier.new);

/// Tipos de objetivo — lista pequena e estável, por isso basta um FutureProvider.
final tiposObjetivoProvider = FutureProvider<List<TipoObjetivo>>((ref) async {
  return await DatabaseService.instance.getTiposObjetivo();
});

// ── Seletores derivados ─────────────────────────────────
// Evitam repetir a mesma filtragem em cada ecrã.

/// Objetivos ainda a decorrer.
final objetivosEmProgressoProvider = Provider<List<Objetivo>>((ref) {
  final objetivos = ref.watch(objetivosProvider).valueOrNull ?? [];
  return objetivos.where((o) => o.estado == 'Em Curso').toList();
});

/// Objetivos já terminados — alcançados ou não.
final objetivosFinalizadosProvider = Provider<List<Objetivo>>((ref) {
  final objetivos = ref.watch(objetivosProvider).valueOrNull ?? [];
  return objetivos.where((o) => o.estado != 'Em Curso').toList();
});
