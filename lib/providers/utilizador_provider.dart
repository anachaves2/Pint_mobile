import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/consultor.dart';
import 'package:pint_mobile/services/database_service.dart';

class UtilizadorNotifier extends AsyncNotifier<Consultor?> {
  @override
  Future<Consultor?> build() async {
    return await DatabaseService.instance.getUser();
  }
  Future<void> atualizar(Consultor consultor) async{
    state = const AsyncValue.loading();
    try{
      state = AsyncValue.data(consultor);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
  void limpar() {
    state =  const AsyncValue.data(null);
  }
}

final utilizadorProvider = 
  AsyncNotifierProvider<UtilizadorNotifier, Consultor?> (
    UtilizadorNotifier.new);
