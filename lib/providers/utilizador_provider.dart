import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pint_mobile/models/consultor.dart';
import 'package:pint_mobile/services/database_service.dart';

//Gere o estado do consultor autenticado, partilhado por toda a app
class UtilizadorNotifier extends AsyncNotifier<Consultor?> {
  @override
  //Carrefa o consultor do SQLite quando o provider é criado
  Future<Consultor?> build() async {
    return await DatabaseService.instance.getUser();
  }
  // Atualiza o estado com um novo consultor
  Future<void> atualizar(Consultor consultor) async{
    state = const AsyncValue.loading();
    try{
      state = AsyncValue.data(consultor);
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }
  //Limpa o estado no logout
  void limpar() {
    state =  const AsyncValue.data(null);
  }
}
//Provider global, usado nos ecrãs com ref.watch(utilizadorProvider)
final utilizadorProvider = 
  AsyncNotifierProvider<UtilizadorNotifier, Consultor?> (
    UtilizadorNotifier.new);

// Porquê AsyncNotifier e não StateNotifier?
// O build() precisa de ser async para ir buscar dados ao SQLite.
// O AsyncNotifier gere automaticamente os estados loading/data/error. 
