// ficheiro para armazenamento de constantes -> todos os valores são static

class AppConstants {
  AppConstants._(); //construtor privado

  static const String baseUrl =
      'http://10.0.2.2:3001/api'; // URL base da API REST

  static const String dbName = 'pint2526.db'; //base de dados local (SQlite)
  static const int dbVersion =
      1; //versão da db -> compara e garante que o user tem a versão atual da db caso a altere

  //chaves do SharedPreferences (para aceder a informações guardadas em SharedPreferences)
  static const String keyToken =
      'auth_token'; //dados de login (email e password incriptados)
  static const String keyUserId = 'user_id'; //id do consultor
  static const String keyUserName = 'user_name'; //nome
  static const String keyUserArea = 'user_area'; //area escolhida pelo consultor

  static const int diasAlertaExpiracao =
      30; // dias restantes para alertar sobre a expiração de um badge
}
