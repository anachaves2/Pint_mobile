import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/candidatura_badge.dart';
import 'package:pint_mobile/services/database_service.dart';


//Gere a lista de candidaturas, partilhado entre todos os ecrãs de candidaturas
class CandidaturasNotifier extends AsyncNotifier<List<CandidaturaBadge>> {
  @override
  //Carrega as candidaturas do SQLite quando o provider é criado
  Future<List<CandidaturaBadge>> build() async {
    return await DatabaseService.instance.getCandidaturas();
  }
  //Limpa a lista no logout
  void limpar() {
    state = const AsyncValue.data([]);
  }
  //Recarrega as candidaturas do SQLite e atualiza todos os ecrãs automaticamente
  Future<void> atualizar() async {
    state = const AsyncValue.loading();
    try {
      final lista = await DatabaseService.instance.getCandidaturas();
      state = AsyncValue.data(lista);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
}

//Provider global, usado em candidaturas, decorrentes, histórico e detalhes
final candidaturasProvider =
    AsyncNotifierProvider<CandidaturasNotifier, List<CandidaturaBadge>>(
        CandidaturasNotifier.new);

// Porquê AsyncNotifier e não StateNotifier?
// O build() precisa de ser async para ir buscar dados ao SQLite.
// O AsyncNotifier gere automaticamente os estados loading/data/error,
// eliminando o padrão repetitivo de _isLoading + setState + _carregar().