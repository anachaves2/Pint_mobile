import 'package:flutter/material.dart'; // para importar a class Color

// ficheiro para armazenamento de constantes -> todos os valores são static

class AppConstants {
  AppConstants._(); //construtor privado

  //=========================================
  //API

  static const String baseUrl = 'https://backend-4b6l.onrender.com/api'; // URL base da API REST
  static const int intervalSincronizacaoMinutos =
      5; // psra sincronizar dados periodicamente

  // URL base para ficheiros (fotos, imagens de badges) — a API devolve
  // caminhos relativos (ex.: "uploads/fotos/x.jpg"), não URLs completos.
  // Mesma lógica do FILES_URL da web (services/api.js): tira o "/api" do
  // fim do baseUrl.
  static String get filesUrl => baseUrl.replaceFirst(RegExp(r'/api/?$'), '');

  // URL do frontend web — usada para abrir a página pública de verificação
  // de um badge. NÃO usar o campo url_publico da base de dados: os dados de
  // exemplo têm lá 'https://badges.softinsa.pt/...', um domínio que não
  // existe, e por isso a página nunca abria.
  static const String frontendUrl = 'https://frontend-6mpw.onrender.com';

  /// Página pública de verificação de um badge, a partir do token.
  static String? urlVerificacaoBadge(String? tokenValidacao) {
    if (tokenValidacao == null || tokenValidacao.isEmpty) return null;
    return '$frontendUrl/badges/verify/$tokenValidacao';
  }

  // Resolve um caminho de ficheiro vindo da API para uma URL completa.
  // Se já vier completo (começa por http) ou for nulo/vazio, devolve como está.
  static String? resolverUrlFicheiro(String? caminho) {
    if (caminho == null || caminho.isEmpty) return null;
    if (caminho.startsWith('http')) return caminho;
    return '$filesUrl/$caminho';
  }

  //=================================================
  //SQLite - Base de dados local

  static const String dbName = 'pint2526.db'; //base de dados local (SQlite)
  static const int dbVersion =
      4; //versão da db -> compara e garante que o user tem a versão atual da db caso a altere

  //Tabelas locais

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
  static const String routeLanding = '/landing';
  static const String routeLogin = '/login';
  static const String routeRecuperarPassword = '/recuperar-password';
  static const String routeRedefinirPassword1 = '/redefinir-password-1';
  static const String routeRedefinirPassword2 = '/redefinir-password-2';
  static const String routeConfiguracaoInicial = '/configuracao-inicial';
  // Fluxo pós-login (mesma ordem da web): trocar password no 1º acesso,
  // depois aceitar RGPD, depois configuração inicial / dashboard.
  static const String routeTrocarPasswordPrimeiroAcesso = '/trocar-password-primeiro-acesso';
  static const String routeAceitarRgpd = '/aceitar-rgpd';

  // DASHBOARD
  static const String routeDashboard = '/dashboard';

  // BADGES
  static const String routeMeusBadges = '/badges';
  static const String routeTodosBadges = '/badges/todos';
  static const String routeBadgesEspeciais = '/badges/especiais';
  static const String routeBadgesExpirados = '/badges/expirados';
  // Uso com argumento: Navigator.pushNamed(context, routeDetalheBadge, arguments: badge.id)
  static const String routeDetalheBadge = '/badges/detalhe';
  static const String routeDetalheBadgePremium = '/badges/detalhe-premium';
  static const String routeDetalheBadgeExpirado = '/badges/detalhe-expirado';
  static const String routeDetalheBadgeRequisitos = '/badges/requisitos';

  // CANDIDATURAS
  static const String routeCandidaturas = '/candidaturas';
  static const String routeCandidaturasDecorrentes = '/candidaturas/decorrentes';
  static const String routeHistoricoCandidaturas = '/candidaturas/historico';
  static const String routeCandidaturaSubmetida = '/candidaturas/submetida';
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
  static const String routeDetalheNotificacao = '/notificacoes/detalhe';
  static const String tableNotificacoesPendentes = 'notificacoes_pendentes_lidas';
  
  // DEFINIÇÕES / PERFIL
  static const String routePerfil = '/perfil';
  static const String routeDefinicoes = '/definicoes';
  static const String routeAlterarPassword = '/alterar-password';
}