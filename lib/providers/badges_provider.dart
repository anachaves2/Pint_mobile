import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/services/api_service.dart';
import 'package:pint_mobile/services/database_service.dart';

// BadgesNotifier gere a lista completa de badges do utilizador autenticado.
// Os ecrãs (OsMeusBadges, TodosOsBadges, BadgesEspeciais, BadgesExpirados)
// leem daqui em vez de chamarem o DatabaseService diretamente.

class BadgesNotifier extends AsyncNotifier<List<BadgeUtilizador>> {
  @override
  Future<List<BadgeUtilizador>> build() async {
    return await DatabaseService.instance.getBadges();
  }

  // Sincroniza com a API e atualiza o estado com os dados frescos do SQLite.
  // Chamado no pull-to-refresh dos ecrãs de badges.
  Future<void> atualizar() async {
    state = const AsyncValue.loading();
    try {
      await APIService.instance.sincronizarBadges();
      final badges = await DatabaseService.instance.getBadges();
      state = AsyncValue.data(badges);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  // Apaga a lista local — chamado no logout para não mostrar dados de outro utilizador.
  void limpar() {
    state = const AsyncValue.data([]);
  }
}

final badgesProvider =
    AsyncNotifierProvider<BadgesNotifier, List<BadgeUtilizador>>(
  BadgesNotifier.new,
);