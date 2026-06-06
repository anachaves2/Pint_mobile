import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/candidatura_badge.dart';
import 'package:pint_mobile/services/database_service.dart';

class CandidaturasNotifier extends AsyncNotifier<List<CandidaturaBadge>> {
  @override
  Future<List<CandidaturaBadge>> build() async {
    return await DatabaseService.instance.getCandidaturas();
  }

  void limpar() {
    state = const AsyncValue.data([]);
  }

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

final candidaturasProvider =
    AsyncNotifierProvider<CandidaturasNotifier, List<CandidaturaBadge>>(
        CandidaturasNotifier.new);