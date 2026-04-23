import 'package:http/http.dart' as http;
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/services/database_service.dart';

class APIService {
  static APIService? _instance; //instância do serviço --> só pode haver uma!

  APIService._(); //construtor privado

  static APIService get instance {
    //devolve a instancia do serviço existente -> se não existir criar
    _instance ??= APIService._();
    return _instance!;
  }

  //metodo para importar serviço http e token de autenticaçao
  Future<Map<String, String>> _getHeaders() async {
    final token = await DatabaseService.instance.getToken();
    return {
    // Diz à API que estamos a enviar dados em formato JSON
      'Content-Type': 'application/json',
    // Envia o token de autenticação — a API valida se o utilizador está autenticado
    // Bearer é o tipo de autenticação padrão para tokens JWT
      'Authorization': 'Bearer $token',
    };
  }

  //MÉTODOS PARA A API COMUNICAR COM O SERVIDOR (projeto pint_web -> vai usar sequelize para comuncar com o Postgres)

}
