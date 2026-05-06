import 'package:flutter/material.dart'; // para importar a class Color

// ficheiro para armazenamento de constantes -> todos os valores são static

class AppConstants {
  AppConstants._(); //construtor privado

  //=========================================
  //API

  static const String baseUrl =
      'http://10.0.2.2:3001/api'; // URL base da API REST
  static const int intervalSincronizacaoMinutos =
      5; // psra sincronizar dados periodicamente

  //=================================================
  //SQLite - Base de dados local

  static const String dbName = 'pint2526.db'; //base de dados local (SQlite)
  static const int dbVersion =
      1; //versão da db -> compara e garante que o user tem a versão atual da db caso a altere

  //Tabelas locais

  static const String tableUsers = 'users';
  static const String tableBadgesCache = 'badges_cache';
  static const String tableCandidaturasCache = 'candidaturas_cache';
  static const String tableNotificacoesCache = 'notificacoes_cache';
  static const String tableObjetivosCache = 'objetivos_cache';
  static const String tableCatalogoBadges = 'catalogo_badges';
  static const String tableCatalogoBadgesEspeciais =
      'catalogo_badges_especiais';
  static const String tableTiposObjetivo = 'tipos_objetivo';
  static const String tableEstadosCandidatura = 'estados_candidatura';
  static const String tableHistoricoCandidatura = 'historico_candidatura';
  static const String tableRequisitosCache = 'requisitos_cache';
  static const String tableEvidenciasCache = 'evidencias_cache';

  //====================================================
  //Alertas

  static const int diasAlertaExpiracao =
      30; // dias restantes para alertar sobre a expiração de um badge

  //=======================================================
  //Cores

  static const Color corPrimaria = Color(0xFF39639C); // azul escuro
  static const Color corSecundaria = Color(0xFF00B8E0); // azul claro
  static const Color corTexto = Color(0xFF000000); // preto
  static const Color corErro = Color(0xFFAE0003); // vermelho
  static const Color corSucesso = Color(0xFF06A120); // verde

  //================================================================
  //ROTAS

  // AUTH
  static const String routeLogin = '/login';
  static const String routeRecuperarPassword = '/recuperar-password';
  static const String routeRedefinirPassword1 = '/redefinir-password-1';
  static const String routeRedefinirPassword2 = '/redefinir-password-2';
  static const String routeConfiguracaoInicial = '/configuracao-inicial';

  // DASHBOARD
  static const String routeDashboard = '/dashboard';

  // BADGES
  static const String routeMeusBadges = '/badges';
  static const String routeTodosBadges = '/badges/todos';
  static const String routeBadgesEspeciais = '/badges/especiais';
  static const String routeBadgesExpirados = '/badges/expirados';
  // Uso com argumento: Navigator.pushNamed(context, routeDetalheBadge, arguments: badge.id)
  static const String routeDetalheBadge = '/badges/detalhe';

  // CANDIDATURAS
  static const String routeCandidaturas = '/candidaturas';
  // Uso com argumento: Navigator.pushNamed(context, routeDetalheCandidatura, arguments: numCandidatura)
  static const String routeDetalheCandidatura = '/candidaturas/detalhe';
  static const String routeNovaCandidatura = '/candidaturas/nova';

  // CATÁLOGO
  static const String routeCatalogo = '/catalogo';
  // Uso com argumento: Navigator.pushNamed(context, routeDetalheCatalogo, arguments: idBadgeRegular)
  static const String routeDetalheCatalogo = '/catalogo/detalhe';

  // OBJETIVOS
  static const String routeObjetivos = '/objetivos';

  // GAMIFICATION
  static const String routeGamification = '/gamification';
  static const String routeRanking = '/gamification/ranking';

  // NOTIFICAÇÕES
  static const String routeNotificacoes = '/notificacoes';

  // DEFINIÇÕES / PERFIL
  static const String routeDefinicoes = '/definicoes';
}
