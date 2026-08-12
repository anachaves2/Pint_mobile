import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/ranking_entrada.dart';
import 'package:pint_mobile/services/api_service.dart';

/// Ranking de gamification.
///
/// Ao contrário dos objetivos e badges, este provider vai diretamente à API —
/// o ranking é volátil (muda sempre que alguém ganha pontos) e não faz sentido
/// guardá-lo em SQLite: mostrar um ranking desatualizado é pior do que mostrar
/// um aviso de que não há ligação.
class RankingNotifier extends AsyncNotifier<List<RankingEntrada>> {
  @override
  Future<List<RankingEntrada>> build() async {
    return await APIService.instance.obterRanking();
  }

  Future<void> atualizar() async {
    state = const AsyncValue.loading();
    try {
      final lista = await APIService.instance.obterRanking();
      state = AsyncValue.data(lista);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  void limpar() {
    state = const AsyncValue.data([]);
  }
}

final rankingProvider =
    AsyncNotifierProvider<RankingNotifier, List<RankingEntrada>>(
        RankingNotifier.new);

/// As três primeiras posições — para o pódio.
final podioProvider = Provider<List<RankingEntrada>>((ref) {
  final ranking = ref.watch(rankingProvider).valueOrNull ?? [];
  return ranking.take(3).toList();
});