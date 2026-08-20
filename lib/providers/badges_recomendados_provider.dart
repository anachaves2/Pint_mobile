import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/badge_recomendado.dart';
import 'package:pint_mobile/services/api_service.dart';

/// Badges recomendados do Dashboard.
///
/// Vai sempre à API — mesmo raciocínio do rankingProvider e do
/// objetivosResumoProvider: é um cálculo do servidor que depende dos badges
/// já obtidos e da área do consultor, por isso muda com frequência.
class BadgesRecomendadosNotifier extends AsyncNotifier<List<BadgeRecomendado>> {
  @override
  Future<List<BadgeRecomendado>> build() async {
    return await APIService.instance.obterBadgesRecomendados();
  }

  Future<void> atualizar() async {
    state = const AsyncValue.loading();
    try {
      final lista = await APIService.instance.obterBadgesRecomendados();
      state = AsyncValue.data(lista);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  void limpar() {
    state = const AsyncValue.data([]);
  }
}

final badgesRecomendadosProvider =
    AsyncNotifierProvider<BadgesRecomendadosNotifier, List<BadgeRecomendado>>(
        BadgesRecomendadosNotifier.new);