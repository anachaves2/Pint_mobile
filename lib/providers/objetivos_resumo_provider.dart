import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/objetivos_resumo.dart';
import 'package:pint_mobile/services/api_service.dart';

/// Resumo de objetivos do Dashboard (progresso de learning path, áreas e
/// service lines completas, objetivos em curso).
///
/// Vai sempre à API, sem cache em SQLite — mesmo raciocínio do
/// ranking_provider.dart: é um cálculo do servidor que muda com frequência
/// (progride sempre que se ganham badges ou se conclui um objetivo), por
/// isso mostrar um valor desatualizado seria pior do que pedir de novo.
class ObjetivosResumoNotifier extends AsyncNotifier<ObjetivosResumo> {
  @override
  Future<ObjetivosResumo> build() async {
    return await APIService.instance.obterObjetivosResumo();
  }

  Future<void> atualizar() async {
    state = const AsyncValue.loading();
    try {
      final resumo = await APIService.instance.obterObjetivosResumo();
      state = AsyncValue.data(resumo);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  void limpar() {
    state = AsyncValue.data(ObjetivosResumo.vazio());
  }
}

final objetivosResumoProvider =
    AsyncNotifierProvider<ObjetivosResumoNotifier, ObjetivosResumo>(
        ObjetivosResumoNotifier.new);