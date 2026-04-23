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

//tabelas da base de dados local (sqflite)
  static const String tableUsers = 'users';
  static const String tableBadgesCache = 'badges_cache';
  static const String tableCandidaturasCache = 'candidaturas_cache';    
  static const String tableNotificacoesCache = 'notificacoes_cache';
  static const String tableObjetivosCache = 'objetivos_cache';
  static const String tableCatalogoBadges = 'catalogo_badges';
  static const String tableCatalogoBadgesEspeciais = 'catalogo_badges_especiais';
  static const String tableTiposObjetivo = 'tipos_objetivo';
  static const String tableEstadosCandidatura = 'estados_candidatura';
  static const String tableHistoricoCandidatura = 'historico_candidatura';
  static const String tableRequisitosCache = 'requisitos_cache';
  
  static const String tableEvidenciasCache = 'evidencias_cache';
  static const int diasAlertaExpiracao = 30; // dias restantes para alertar sobre a expiração de um badge

}
