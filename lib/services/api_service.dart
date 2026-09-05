import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/utils/navigator_key.dart';
import 'package:pint_mobile/services/database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:pint_mobile/services/preferencias_service.dart';
import 'package:http_parser/http_parser.dart'; //para enviar evidências (imagens) para a API

// Modelos
import 'package:pint_mobile/models/consultor.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/models/badge_regular.dart';
import 'package:pint_mobile/models/badge_especial.dart';
import 'package:pint_mobile/models/candidatura_badge.dart';
import 'package:pint_mobile/models/historico_candidatura.dart';
import 'package:pint_mobile/models/notificacao.dart';
import 'package:pint_mobile/models/objetivo.dart';
import 'package:pint_mobile/models/requisitos.dart';
import 'package:pint_mobile/models/evidencia.dart';
import 'package:pint_mobile/models/tipo_objetivo.dart';
import 'package:pint_mobile/models/estados_candidatura.dart';
import 'package:pint_mobile/models/ranking_entrada.dart';
import 'package:pint_mobile/models/objetivos_resumo.dart';
import 'package:pint_mobile/models/badge_recomendado.dart';

// APIService -> Camada de comunicação com o servidor (PintWeb/backend)

// OFFLINE FIRST:
//   Os métodos de sincronização fazem GET à API e guardam no SQLite
//   A UI lê sempre do SQLite, nunca directamente da API
//Os nomes dos campos JSON que a API deve devolver estão definidos nos fromJson de cada modelo
//um Stream Controller global, acessível de qualquer menu
final StreamController<void> atualizadorDados = StreamController<void>.broadcast();

// Emitido quando uma sincronização em fundo deteta que a sessão expirou
// (401 do backend). O LoginScreen ouve isto para mostrar o aviso, depois
// da navegação automática já ter acontecido.
final StreamController<void> sessaoExpirouEvento = StreamController<void>.broadcast();

// Converte uma lista JSON para uma lista de objetos, item a item, em vez de
// um único .map().toList() que rebenta todo de uma vez ao primeiro item
// problemático (foi exatamente isto que apagou os badges e notificações da
// Ines Dias: um único registo com data_expiracao/data nulas deitava fora a
// lista inteira, e o erro era depois mascarado como "sem ligação").
//
// Com isto, um item malformado é ignorado (e fica registado no debugPrint
// para se conseguir investigar), mas os restantes continuam a ser
// guardados normalmente — a sincronização deixa de ser tudo-ou-nada.
List<T> parseListaSegura<T>(
  List<dynamic> jsonList,
  T Function(Map<String, dynamic>) fromJson,
  String nomeLista,
) {
  final resultado = <T>[];
  for (final item in jsonList) {
    try {
      resultado.add(fromJson(item as Map<String, dynamic>));
    } catch (e) {
      debugPrint('[APIService] $nomeLista: item ignorado por erro de parsing ($e) — item: $item');
    }
  }
  return resultado;
}

//SINGLETON - > garante que só há uma instancia da API
class APIService {
  static APIService? _instance;

  APIService._();

  static APIService get instance {
    _instance ??= APIService._();
    return _instance!;
  }

  // Controla se a sincronização periódica está activa
  bool _sincronizacaoAtiva = false;

  // Evita tratar a sessão expirada mais do que uma vez seguida — o
  // sincronizarTodos() dispara vários pedidos em paralelo (Future.wait),
  // e se o token estiver morto, todos falham com 401 quase ao mesmo tempo.
  // Sem esta flag, isso significaria vários logout()/navegações em
  // simultâneo. É reposta a false assim que um login tem sucesso.
  bool _sessaoExpiradaTratada = false;

  // Chamado por qualquer sincronização em fundo que receba 401 do backend.
  // Faz logout local (limpa tudo, incluindo o token) e manda a app para o
  // login — sem isto, uma sessão morta ficava a martelar o servidor de 5
  // em 5 minutos para sempre, sem ninguém dar por isso.
  Future<void> _tratarSessaoExpirada() async {
    if (_sessaoExpiradaTratada) return;
    _sessaoExpiradaTratada = true;

    debugPrint('[APIService] Sessão expirada — a terminar sessão e a voltar ao login.');
    await logout(); // já chama pararSincronizacao() e limpa o token

    final ctx = navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      GoRouter.of(ctx).go(AppConstants.routeLogin);
    }
    sessaoExpirouEvento.add(null);
  }

  // Headers HTTP:
  // OS pedidos autenticados precisam do token JWT guardado no SQLite
  // O header 'Authorization: Bearer <token>' é validado no servidor

  Future<Map<String, String>> _getHeaders() async {
    final token = await DatabaseService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      // Sem isto, um token nulo (ex.: sincronização em fundo ainda a meio
      // quando o logout já apagou a sessão) interpolava para a string
      // literal "Bearer null" — o backend via isso como um JWT malformado
      // em vez de simplesmente "sem autenticação".
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Headers sem token para os pedidos de autenticação (o token ainda nao existe)
  Map<String, String> get _publicHeaders => {
    'Content-Type': 'application/json',
  };

  //================================================================
  // AUTENTICAÇÃO

  //LOGIN - Ecrã 02
  //envia email + password, recebe o token JWT e os dados do consultor
  // Guarda tudo no SQLite para que a app funcione offline após o primeiro login
  // Devolve true se o login foi bem sucedido, false caso contrário
  // Devolve também se a configuração inicial está completa (ecra 06)para que o main.dart saiba para que ecrã navegar

  Future<({bool sucesso, bool configuracaoCompleta, bool primeiroAcesso, bool aceitouRgpd, String? erro})> login(
    String email,
    String password, {
    bool manterSessao = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: _publicHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        _sessaoExpiradaTratada = false; // nova sessão válida — pode voltar a detetar expiração no futuro
        final json = jsonDecode(response.body);
        final token = json['token'] as String;

        // primeiroAcesso só vem no objeto "utilizador" (o "consultor" não o
        // traz) — juntamos os dois antes de construir o modelo, para o
        // Consultor ficar com as duas flags de estado da conta.
        final dadosConsultor = Map<String, dynamic>.from(json['consultor']);
        final dadosUtilizador = json['utilizador'] as Map<String, dynamic>?;
        if (dadosUtilizador != null) {
          dadosConsultor['primeiroAcesso'] = dadosUtilizador['primeiroAcesso'];
          dadosConsultor['ultimoLoginAnterior'] = dadosUtilizador['ultimoLoginAnterior'];
          dadosConsultor['aceitouRgpd'] ??= dadosUtilizador['aceitouRgpd'];
        }

        final consultor = Consultor.fromJson(dadosConsultor);
        final configuracaoCompleta =
            json['consultor']['configuracaoCompleta'] as bool? ?? true;

        // Guarda o consultor e o token no SQLite
        await DatabaseService.instance.saveUser(consultor, token);

        // Guarda o contexto da saudação (bónus): é agora que sabemos se é o
        // primeiro acesso e há quanto tempo não entrava.
        await PreferenciasService().guardarDadosSaudacao(
          primeiroAcesso: consultor.primeiroAcesso,
          ultimoLoginAnterior: consultor.ultimoLoginAnterior,
        );

        // Guarda o token e email também nas preferências para acesso fácil e rápido
        if (manterSessao) {
          final prefs = PreferenciasService();
          await prefs.guardarSessao(token, consultor.email);
          await prefs.guardarUltimaSync();
        }

        return (
          sucesso: true,
          configuracaoCompleta: configuracaoCompleta,
          primeiroAcesso: consultor.primeiroAcesso,
          aceitouRgpd: consultor.aceitouRgpd,
          erro: null,
        );
      }

      // Erros nas credenciais
      final json = jsonDecode(response.body);
      return (
        sucesso: false,
        configuracaoCompleta: false,
        primeiroAcesso: false,
        aceitouRgpd: true,
        erro: json['error'] as String? ?? 'Erro ao fazer login',
      );
    } catch (e) {
      // ATENÇÃO: aqui cai TUDO o que corra mal — não só falta de internet,
      // mas também erros da base de dados local (ex.: coluna em falta por
      // migração não aplicada) e erros a converter a resposta.
      // Antes mostrava-se sempre "sem ligação", o que mandava investigar
      // a rede quando o problema era outro. Agora a mensagem distingue.
      debugPrint('[APIService] login falhou: $e');

      final texto = e.toString();
      final ehErroBaseDados = texto.contains('DatabaseException') ||
          texto.contains('no such column') ||
          texto.contains('no such table') ||
          texto.contains('SqfliteFfiException');

      return (
        sucesso: false,
        configuracaoCompleta: false,
        primeiroAcesso: false,
        aceitouRgpd: true,
        erro: ehErroBaseDados
            ? 'Erro na base de dados local. Desinstala a app e volta a instalar.'
            : 'Não foi possível entrar: $texto',
      );
    }
  }

  //============================================================
  //RECUPERAR PASSWORD - Ecrã 03
  // envia o email e pede ao servidor para enviar o código de 6 dígitos

  Future<({bool sucesso, String? erro})> recuperarPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/recuperar-password'),
        headers: _publicHeaders,
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return (sucesso: true, erro: null);
      }

      final json = jsonDecode(response.body);
      return (
        sucesso: false,
        erro: json['error'] as String? ?? 'Erro ao enviar código',
      );
    } catch (e) {
      return (sucesso: false, erro: 'Sem ligação ao servidor.');
    }
  }

  //=============================================================================
  //VERIFICAR CÓDIGO - Ecrã 04
  //verifica o código de 6 dígitos recebido por email.
  // Se válido, o servidor devolve um token temporário (token_reset) que será usado no ecrã seguinte para redefinir a password
  // Devolve o token_reset se válido, null se inválido ou expirado

  Future<({String? tokenReset, String? erro})> verificarCodigo(
    String email,
    String codigo,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/verificar-codigo'),
        headers: _publicHeaders,
        body: jsonEncode({'email': email, 'codigo': codigo}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return (tokenReset: json['token_reset'] as String, erro: null);
      }

      final json = jsonDecode(response.body);
      return (
        tokenReset: null,
        erro: json['error'] as String? ?? 'Código inválido',
      );
    } catch (e) {
      return (tokenReset: null, erro: 'Sem ligação ao servidor.');
    }
  }

  //REDEFINIR PASSWORD - Ecrã 05
  //usa o tokenReset do ecrã anterior para definir a nova password

  Future<({bool sucesso, String? erro})> redefinirPassword(
    String tokenReset,
    String novaPassword,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/auth/redefinir-password'),
        headers: _publicHeaders,
        body: jsonEncode({
          'token_reset': tokenReset,
          'nova_password': novaPassword,
        }),
      );

      if (response.statusCode == 200) {
        return (sucesso: true, erro: null);
      }

      final json = jsonDecode(response.body);
      return (
        sucesso: false,
        erro: json['error'] as String? ?? 'Erro ao redefinir password',
      );
    } catch (e) {
      return (sucesso: false, erro: 'Sem ligação ao servidor.');
    }
  }

  //CONFIGURAÇÃO INICIAL - Ecrã 06
  //chamado apenas no primeiro login quando o consultor ainda não tem área
  // guarda a área  no SQLite — o consultor só voltam a mudar se o fizer nas definições

  Future<bool> configuracaoInicial({
    required int idArea,
    required String nomeArea,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/auth/configuracao-inicial'),
        headers: headers,
        body: jsonEncode({'idArea': idArea}),
      );

      if (response.statusCode == 200) {
        //200 é a resposta HTTP quando está ok
        await DatabaseService.instance.updateAreaConsultor(
          idArea: idArea,
          nomeArea: nomeArea,
        );
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  //===============================================================
  //LOGOUT
  // Apaga todos os dados locais do SQLite - o utilizador volta ao ecrã de login
  Future<void> logout() async {
    pararSincronizacao();
    await DatabaseService.instance.deleteUser();
    await DatabaseService.instance.deleteBadge();
    await DatabaseService.instance.deleteCandidaturas();
    await DatabaseService.instance.deleteHistorico();
    await DatabaseService.instance.deleteEvidencias();
    await DatabaseService.instance.deleteNotificacoes();
    await DatabaseService.instance.deleteObjetivos();
    await DatabaseService.instance.deleteCatalogoBadges();
    await DatabaseService.instance.deleteCatalogoBadgesEspeciais();
    await PreferenciasService().limpar();
  }

  //===========================================================
  // MÉTODOS DE SINCRONIZAÇÃO (GET)
  //são chamados em background
  //lê da API e guarda no SQLite (a UI lê sempre do SQLite via métodos do DatabaseService)
  // Se não houver internetmostra o que já esta guardado localmente
  //===========================================================

  //===========================================================
  // BADGES CONQUISTADOS - Ecrãs 10-16
  //sincroniza todos os badges do consultor

  Future<void> sincronizarBadges() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/badges/todos'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final badges = parseListaSegura(jsonList, BadgeUtilizador.fromJson, 'sincronizarBadges');
        await DatabaseService.instance.saveBadges(badges);
      } else if (response.statusCode == 401) {
        await _tratarSessaoExpirada();
      }
    } catch (e) {
      // Sem internet — mantém os dados locais, a UI continua a funcionar
      debugPrint('[APIService] sincronizarBadges: sem ligação ($e)');
    }
  }

  //==================================================
  // CATÁLOGO DE BADGES - Ecrãs 33-39
  //sincroniza o catálogo (badges regulares, especiais e requisitos)

  Future<void> sincronizarCatalogo() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/catalogo/todos'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final badgesRegulares = parseListaSegura(
          json['regulares'] as List, BadgeRegular.fromJson, 'sincronizarCatalogo:regulares',
        );

        final badgesEspeciais = parseListaSegura(
          json['especiais'] as List, BadgeEspecial.fromJson, 'sincronizarCatalogo:especiais',
        );

        final requisitos = parseListaSegura(
          json['requisitos'] as List, Requisito.fromJson, 'sincronizarCatalogo:requisitos',
        );

        // Guarda tudo no SQLite
        await DatabaseService.instance.saveCatalogoBadges(badgesRegulares);
        await DatabaseService.instance.saveCatalogoBadgesEspeciais(
          badgesEspeciais,
        );
        await DatabaseService.instance.saveRequisitos(requisitos);
      } else if (response.statusCode == 401) {
        await _tratarSessaoExpirada();
      }
    } catch (e) {
      debugPrint('[APIService] sincronizarCatalogo: sem ligação ($e)');
    }
  }

  //===================================================================
  //CANDIDATURAS - Ecrã 27-29
  //sincroniza a lista de candidaturas do consultor

  Future<void> sincronizarCandidaturas() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/candidaturas'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final candidaturas = parseListaSegura(jsonList, CandidaturaBadge.fromJson, 'sincronizarCandidaturas');
        await DatabaseService.instance.saveCandidaturas(candidaturas);
      } else if (response.statusCode == 401) {
        await _tratarSessaoExpirada();
      }
    } catch (e) {
      debugPrint('[APIService] sincronizarCandidaturas: sem ligação ($e)');
    }
  }
  //=======================================================================
  //DETALHE DE CANDIDATURA - Ecrã 30
  //sincroniza com o historico para o utilizador ver os detalhes da candidatura

  Future<void> sincronizarDetalhesCandidatura(int numCandidatura) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(
          '${AppConstants.baseUrl}/candidaturas/$numCandidatura/detalhes',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final historico = parseListaSegura(
          json['historico'] as List, HistoricoCandidatura.fromJson, 'sincronizarDetalhesCandidatura:historico',
        );
        await DatabaseService.instance.saveHistorico(historico);

        // Adiciona isto após saveHistorico
        final evidencias = parseListaSegura(
          json['evidencias'] as List, Evidencia.fromJson, 'sincronizarDetalhesCandidatura:evidencias',
        );
        await DatabaseService.instance.saveEvidencias(evidencias);
      } else if (response.statusCode == 401) {
        await _tratarSessaoExpirada();
      }
    } catch (e) {
      debugPrint('[APIService] sincronizarDetalhesCandidatura: sem ligação ($e)');
    }
  }

  //============================================
  // ESTADOS DE CANDIDATURA - Ecrãs 27 -30
  //para colocar a etiqueta de estado da candidatura correta

  Future<void> sincronizarEstados() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/candidaturas/estados'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final estados = parseListaSegura(jsonList, EstadoCandidatura.fromJson, 'sincronizarEstados');
        await DatabaseService.instance.saveEstados(estados);
      } else if (response.statusCode == 401) {
        await _tratarSessaoExpirada();
      }
    } catch (e) {
      debugPrint('[APIService] sincronizarEstados: sem ligação ($e)');
    }
  }
  //==============================================================
  //OBJETIVOS - ecrãs 18-20
  //sincroniza os objetivos

  Future<void> sincronizarObjetivos() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/objetivos'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final objetivos = parseListaSegura(jsonList, Objetivo.fromJson, 'sincronizarObjetivos');
        await DatabaseService.instance.saveObjetivos(objetivos);
      } else if (response.statusCode == 401) {
        await _tratarSessaoExpirada();
      }
    } catch (e) {
      debugPrint('[APIService] sincronizarObjetivos: sem ligação ($e)');
    }
  }

  //=====================================================
  // TIPOS DE OBJETIVO - ecrã 22-23
  //sincroniza com os 5 tipos definidos

  Future<void> sincronizarTiposObjetivo() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/objetivos/tipos'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final tipos = parseListaSegura(jsonList, TipoObjetivo.fromJson, 'sincronizarTiposObjetivo');
        await DatabaseService.instance.saveTiposObjetivo(tipos);
      } else if (response.statusCode == 401) {
        await _tratarSessaoExpirada();
      }
    } catch (e) {
      debugPrint('[APIService] sincronizarTiposObjetivo: sem ligação ($e)');
    }
  }

  //===================================================
  //NOTIFICAÇÕES: Ecrãs 47-52
  //sincroniza as notificações

  Future<void> sincronizarNotificacoes() async {
    try {
      final headers = await _getHeaders();

      // 1. Sincronizar pendentes de lida (lidas offline)
      final pendentes = await DatabaseService.instance.getNotificacoesPendentes();
      for (final id in pendentes) {
        try {
          final r = await http.put(
            Uri.parse('${AppConstants.baseUrl}/notificacoes/$id/lida'),
            headers: headers,
          );
          if (r.statusCode == 200) {
            await DatabaseService.instance.removerNotificacaoPendente(id);
          }
        } catch (_) {}
      }

      // 2. Buscar notificações atualizadas do servidor
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/notificacoes'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final notificacoes = parseListaSegura(jsonList, Notificacao.fromJson, 'sincronizarNotificacoes');
        await DatabaseService.instance.saveNotificacoes(notificacoes);
      } else if (response.statusCode == 401) {
        await _tratarSessaoExpirada();
      }
    } catch (e) {
      debugPrint('[APIService] sincronizarNotificacoes: sem ligação ($e)');
    }
  }

  //================================================================
  //SINCRONIZAR TUDO
  // Chama todos os métodos de sincronização

  // Vai buscar o perfil completo a GET /perfil/me e actualiza o utilizador
  // local. É preciso porque a resposta do LOGIN não traz totalPontos,
  // posicaoRanking nem nomeServiceLine — sem isto, o Perfil e as Definições
  // mostravam sempre esses campos vazios.
  Future<void> sincronizarPerfil() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/perfil/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final atual = await DatabaseService.instance.getUser();
        if (atual == null) return;

        final atualizado = Consultor(
          id: atual.id,
          nome: json['nome'] ?? atual.nome,
          email: json['email'] ?? atual.email,
          telefone: json['telefone'] ?? atual.telefone,
          urlLinkedin: json['urlLinkedin'] ?? atual.urlLinkedin,
          urlFoto: json['urlFoto'] ?? atual.urlFoto,
          dataMembro: atual.dataMembro,
          linguaPadrao: json['linguaPadrao'] ?? atual.linguaPadrao,
          idArea: json['idArea'] ?? atual.idArea,
          nomeArea: json['nomeArea'] ?? atual.nomeArea,
          nomeServiceLine: json['nomeServiceLine'] ?? atual.nomeServiceLine,
          idLearningPath: atual.idLearningPath,
          nomeLearningPath: json['nomeLearningPath'] ?? atual.nomeLearningPath,
          totalPontos: json['totalPontos'] ?? atual.totalPontos,
          posicaoRanking: json['posicaoRanking'] ?? atual.posicaoRanking,
          aceitouRgpd: json['aceitouRgpd'] as bool? ?? atual.aceitouRgpd,
          primeiroAcesso: atual.primeiroAcesso,
        );

        final token = await DatabaseService.instance.getToken();
        if (token != null) {
          await DatabaseService.instance.saveUser(atualizado, token);
        }
      } else if (response.statusCode == 401) {
        await _tratarSessaoExpirada();
      }
    } catch (e) {
      debugPrint('[APIService] sincronizarPerfil: sem ligação ($e)');
    }
  }

  Future<void> sincronizarTodos() async {
    await Future.wait([
      sincronizarPerfil(),
      sincronizarBadges(),
      sincronizarCatalogo(),
      sincronizarCandidaturas(),
      sincronizarObjetivos(),
      sincronizarNotificacoes(),
      sincronizarTiposObjetivo(),
      sincronizarEstados(),
    ]);
    atualizadorDados.add(null); // Notifica a UI para actualizar os dados
  }

  //=======================================================
  //SINCRONIZAÇÃO PERIÓDICA
  //corre continuamente em backgroug no intervalo de tempo definido nas constantes

  void iniciarSincronizacaoPeriodica(Duration intervalo) async {
    if(_sincronizacaoAtiva) return; // Impede múltiplas sincronizações simultâneas
    _sincronizacaoAtiva = true;
    while (_sincronizacaoAtiva) {
      await sincronizarTodos();
      await Future.delayed(intervalo);
    }
  }

  void pararSincronizacao() {
    _sincronizacaoAtiva = false;
  }

  //=======================================================
  // ACÇÕES DO CONSULTOR (POST / PUT / DELETE)
  //chamados directamente por eventos da UI
  // Aguardam a resposta do servidor antes de actualizar o SQLite - Se não houver internet devolve msg de erro
  //============================================================

  //===================================================
  //CRIAR CANDIDATURA - Ecrã 31
  // Devolve o numCandidatura se criado com sucesso, null se houve erro
  // Depois de criar sincroniza as candidaturas para actualizar o SQLite

  Future<({int? numCandidatura, String? erro})> criarCandidatura(
    int idBadgeRegular,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/candidaturas'),
        headers: headers,
        body: jsonEncode({'idBadgeRegular': idBadgeRegular}),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        final num = json['numCandidatura'] as int;
        await sincronizarCandidaturas();
        return (numCandidatura: num, erro: null);
      }

      if (response.statusCode == 409) {
        //para impedir de criar duas candidaturas ao mesmo badge
        return (
          numCandidatura: null,
          erro: 'Já tens uma candidatura em curso para este badge.',
        );
      }

      return (
        numCandidatura: null,
        erro: 'Erro ao criar candidatura. Tenta novamente.',
      );
    } catch (e) {
      return (
        numCandidatura: null,
        erro: 'Sem ligação ao servidor. Verifica a tua internet.',
      );
    }
  }

  //==================================================================
  //UPLOAD DE EVIDÊNCIA - Ecrã 31
  //envia um ficheiro (PDF, ZIP, imagem) como evidência de um requisito
  //Usa multipart/form-data porque estamos a enviar um ficheiro
  // O [filePath] é o caminho local do ficheiro escolhido pelo file_picker

  Future<({bool sucesso, String? erro})> uploadEvidencia({
    required int numCandidatura,
    required int idRequisito,
    required String filePath,
  }) async {
    try {
      final token = await DatabaseService.instance.getToken();
      final ficheiro = File(filePath);

      // MultipartRequest é necessário para enviar ficheiros
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '${AppConstants.baseUrl}/candidaturas/$numCandidatura/evidencias',
        ),
      );

      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      // Adiciona o campo idRequisito como campo de texto
      request.fields['idRequisito'] = idRequisito.toString();
      // Adiciona o ficheiro como campo 'ficheiro' (nome esperado pelo multer no backend)
      // Deteta o contentType pela extensão para o backend aceitar o ficheiro
      final ext = ficheiro.path.toLowerCase();
      MediaType? tipo;
      if (ext.endsWith('.pdf')) {
        tipo = MediaType('application', 'pdf');
      } else if (ext.endsWith('.zip')) {
        tipo = MediaType('application', 'zip');
      } else if (ext.endsWith('.png')) {
        tipo = MediaType('image', 'png');
      } else if (ext.endsWith('.jpg') || ext.endsWith('.jpeg')) {
        tipo = MediaType('image', 'jpeg');
      }
      request.files.add(
        await http.MultipartFile.fromPath('ficheiro', ficheiro.path, contentType: tipo),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        // Actualiza o SQLite com a evidência submetida
        await sincronizarDetalhesCandidatura(numCandidatura);
        return (sucesso: true, erro: null);
      }

      final json = jsonDecode(response.body);
      return (
        sucesso: false,
        erro: json['error'] as String? ?? 'Erro ao enviar evidência',
      );
    } catch (e) {
      return (sucesso: false, erro: 'Sem ligação ao servidor.');
    }
  }

  //====================================================
  //SUBMETER CANDIDATURA - Ecrã 31 e 32
  //submete a candidatura para validação muda o estado
  //O servidor valida que todos os requisitos têm evidências antes de aceitar

  Future<({bool sucesso, String? erro})> submeterCandidatura(
    int numCandidatura,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(
          '${AppConstants.baseUrl}/candidaturas/$numCandidatura/submeter',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Actualiza o estado da candidatura no SQLite
        await sincronizarCandidaturas();
        await sincronizarDetalhesCandidatura(numCandidatura);
        return (sucesso: true, erro: null);
      }

      final json = jsonDecode(response.body);
      return (
        sucesso: false,
        erro: json['error'] as String? ?? 'Erro ao submeter candidatura',
      );
    } catch (e) {
      return (sucesso: false, erro: 'Sem ligação ao servidor.');
    }
  }

  //==========================================================
  //CRIAR OBJETIVO - Ecrã 22 e 23de criar objetivo:
  //A API deve devolve o id do objetivo

  Future<({bool sucesso, String? erro})> criarObjetivo({
    required int idTipoObjetivo,
    required DateTime dataInicio,
    required DateTime dataFim,
    int? idLearningPath,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/objetivos'),
        headers: headers,
        body: jsonEncode({
          'idTipoObjetivo': idTipoObjetivo,
          'dataInicio': dataInicio.toIso8601String(),
          'dataFim': dataFim.toIso8601String(),
          'idLearningPath': idLearningPath,
        }),
      );

      if (response.statusCode == 201) {
        await sincronizarObjetivos();
        // Avisa a UI (Dashboard incluído) — sem isto, o resumo de objetivos
        // do Dashboard ficava desactualizado até à próxima sincronização.
        atualizadorDados.add(null);
        return (sucesso: true, erro: null);
      }

      final json = jsonDecode(response.body);
      return (
        sucesso: false,
        erro: json['error'] as String? ?? 'Erro ao criar objetivo',
      );
    } catch (e) {
      return (sucesso: false, erro: 'Sem ligação ao servidor.');
    }
  }
  
  //============================================================
  // EDITAR OBJETIVO Ecrã 20: o consultor altera as datas de um objetivo em curso.

  Future<({bool sucesso, String? erro})> editarObjetivo({
    required int idObjetivo,
    required DateTime dataInicio,
    required DateTime dataFim,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/objetivos/$idObjetivo'),
        headers: headers,
        body: jsonEncode({
          'dataInicio': dataInicio.toIso8601String(),
          'dataFim': dataFim.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        await sincronizarObjetivos();
        atualizadorDados.add(null);
        return (sucesso: true, erro: null);
      }

      final json = jsonDecode(response.body);
      return (
        sucesso: false,
        erro: json['error'] as String? ?? 'Erro ao editar objetivo',
      );
    } catch (e) {
      return (sucesso: false, erro: 'Sem ligação ao servidor.');
    }
  }

  //=============================================================
  //REMOVER OBJETIVO - Ecrã 20 botão

  Future<({bool sucesso, String? erro})> removerObjetivo(int idObjetivo) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/objetivos/$idObjetivo'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Apaga também do SQLite local imediatamente (sem esperar sync)
        await DatabaseService.instance.deleteObjetivo(idObjetivo);
        atualizadorDados.add(null);
        return (sucesso: true, erro: null);
      }

      final json = jsonDecode(response.body);
      return (
        sucesso: false,
        erro: json['error'] as String? ?? 'Erro ao remover objetivo',
      );
    } catch (e) {
      return (sucesso: false, erro: 'Sem ligação ao servidor.');
    }
  }

  //=========================================================
  //ELIMINAR NOTIFICAÇÃO/MARCAR COMO LIDA - Escrãs 48 - 52

  Future<({bool sucesso, String? erro})> eliminarNotificacao(
    int idNotificacao,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/notificacoes/$idNotificacao'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Apaga imediatamente do SQLite local (a UI actualiza sem reload)
        await DatabaseService.instance.deleteNotificacao(idNotificacao);
        return (sucesso: true, erro: null);
      }

      final json = jsonDecode(response.body);
      return (
        sucesso: false,
        erro: json['error'] as String? ?? 'Erro ao eliminar notificação',
      );
    } catch (e) {
      return (sucesso: false, erro: 'Sem ligação ao servidor.');
    }
  }

  Future<void> marcarNotificacaoLida(int idNotificacao) async {
  await DatabaseService.instance.marcarLidaLocal(idNotificacao);

  try {
    final headers = await _getHeaders();
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}/notificacoes/$idNotificacao/lida'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      await DatabaseService.instance.removerNotificacaoPendente(idNotificacao);
    } else {
      await DatabaseService.instance.adicionarNotificacaoPendente(idNotificacao);
    }
  } catch (_) {
    await DatabaseService.instance.adicionarNotificacaoPendente(idNotificacao);
  }
}

  // Marca como não lida — usado quando o consultor quer voltar a ver a
  // notificação como nova. Atualiza local primeiro, depois tenta a API;
  // se falhar, fica só localmente (não há fila de pendentes para isto,
  // ao contrário de "marcar lida" — a próxima sincronização completa
  // acaba por repor o valor real do servidor).
  Future<void> marcarNotificacaoNaoLida(int idNotificacao) async {
    await DatabaseService.instance.marcarNaoLidaLocal(idNotificacao);
    try {
      final headers = await _getHeaders();
      await http.put(
        Uri.parse('${AppConstants.baseUrl}/notificacoes/$idNotificacao/nao-lida'),
        headers: headers,
      );
    } catch (_) {}
  }

  // Marca todas como lidas de uma vez — igual ao botão da web.
  Future<void> marcarTodasNotificacoesLidas() async {
    await DatabaseService.instance.marcarTodasLidasLocal();
    try {
      final headers = await _getHeaders();
      await http.put(
        Uri.parse('${AppConstants.baseUrl}/notificacoes/marcar-todas-lidas'),
        headers: headers,
      );
    } catch (_) {}
  }

  //==============================================================
  //ACTUALIZAR PERFIL - Ecrã 54

  Future<({bool sucesso, String? erro})> atualizarPerfil(
    Consultor consultor,
  ) async {
    try {
      final headers = await _getHeaders();
      // A rota correcta é /perfil/me — estava a apontar para /perfil, que não
      // existe no backend, por isso as alterações de perfil nunca eram
      // guardadas no servidor (falhava em silêncio).
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/perfil/me'),
        headers: headers,
        body: jsonEncode({
          'telefone': consultor.telefone,
          'urlLinkedin': consultor.urlLinkedin,
          'idArea': consultor.idArea,
        }),
      );

      if (response.statusCode == 200) {
        // Actualiza os dados locais no SQLite
        await DatabaseService.instance.updateUser(consultor);
        return (sucesso: true, erro: null);
      }

      final json = jsonDecode(response.body);
      return (
        sucesso: false,
        erro: json['error'] as String? ?? 'Erro ao actualizar perfil',
      );
    } catch (e) {
      return (sucesso: false, erro: 'Sem ligação ao servidor.');
    }
  }

  // UPLOAD DA FOTO DE PERFIL — Definições
  // POST /api/perfil/foto (multipart). Antes, o ecrã de Definições abria a
  // câmara mas nunca enviava nada — a foto era tirada e descartada.
  Future<({bool sucesso, String? urlFoto, String? erro})> uploadFotoPerfil(String caminhoFicheiro) async {
    try {
      final token = await DatabaseService.instance.getToken();
      final pedido = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/perfil/foto'),
      );
      if (token != null) pedido.headers['Authorization'] = 'Bearer $token';
      pedido.files.add(await http.MultipartFile.fromPath('foto', caminhoFicheiro));

      final streamed = await pedido.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return (sucesso: true, urlFoto: json['urlFoto'] as String?, erro: null);
      }

      final json = jsonDecode(response.body);
      return (sucesso: false, urlFoto: null, erro: json['error'] as String? ?? 'Erro ao enviar a foto.');
    } catch (e) {
      return (sucesso: false, urlFoto: null, erro: 'Sem ligação ao servidor.');
    }
  }

  // LISTAR ÁREAS DISPONÍVEIS — Definições (ecrã 54)

  Future<List<Map<String, dynamic>>> getAreas() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/areas'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList
            .map((j) => {'id': j['id'] as int, 'nome': j['nome'] as String})
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[APIService] getAreas: sem ligação ($e)');
      return [];
    }
  }
  
  // ALTERAR PASSWORD — Definições (ecrã 54)

  Future<({bool sucesso, String? erro})> alterarPassword({
    required String passwordAtual,
    required String novaPassword,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/perfil/password'),
        headers: headers,
        body: jsonEncode({
          'passwordAtual': passwordAtual,
          'novaPassword': novaPassword,
        }),
      );
      if (response.statusCode == 200) {
        return (sucesso: true, erro: null);
      }
      if (response.statusCode == 401) {
        return (sucesso: false, erro: 'Password atual incorreta.');
      }
      final json = jsonDecode(response.body);
      return (
        sucesso: false,
        erro: json['error'] as String? ?? 'Erro ao alterar password',
      );
    } catch (e) {
      return (sucesso: false, erro: 'Sem ligação ao servidor.');
    }
  }

  //=============================================================
  // ENVIAR TOKEN FCM — chamado após o login e sempre que o Firebase gerar
  // um token novo (onTokenRefresh), para o backend saber para onde mandar
  // as push notifications deste utilizador (bónus SLA ultrapassado).
  // "Best effort": nunca deve bloquear nem mostrar erro ao utilizador —
  // se falhar, a app continua a funcionar normalmente, só sem push.

  Future<void> enviarTokenFcm(String fcmToken) async {
    try {
      final headers = await _getHeaders();
      await http.put(
        Uri.parse('${AppConstants.baseUrl}/perfil/fcm-token'),
        headers: headers,
        body: jsonEncode({'fcmToken': fcmToken}),
      );
    } catch (e) {
      // Silencioso de propósito — ver nota acima.
    }
  }
  //=============================================================
  // OBTER POLÍTICA DE PRIVACIDAD - Para ecrã login_screen

  Future<String?> getPoliticaPrivacidade() async {
  try {
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/auth/politica-privacidade'),
    );
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      return json['conteudo'] as String?;
    }
    return null;
  } catch (e) {
    return null;
    }
  }

//==========================================================
// CANCELAR RASCUNHO - apaga uma candidatura em estado 0 (rascunho)
// Só funciona se a candidatura ainda não foi submetida
// Apaga também todas as evidências associadas (BD + disco)

  Future<({bool sucesso, String? erro})> cancelarRascunho(
    int numCandidatura,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/candidaturas/$numCandidatura'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Atualiza o SQLite para remover a candidatura da lista local
        await sincronizarCandidaturas();
        return (sucesso: true, erro: null);
      }

      final json = jsonDecode(response.body);
      return (
        sucesso: false,
        erro: json['error'] as String? ?? 'Erro ao cancelar candidatura',
      );
    } catch (e) {
      return (sucesso: false, erro: 'Sem ligação ao servidor.');
    }
  }

//==========================================================
// GET RASCUNHOS - lista os rascunhos do consultor autenticado
// Devolve uma lista de mapas com info de cada rascunho

  Future<({List<Map<String, dynamic>>? rascunhos, String? erro})> getRascunhos() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/candidaturas/rascunhos'),
        headers: headers,
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        final rascunhos = json.cast<Map<String, dynamic>>();
        return (rascunhos: rascunhos, erro: null);
      }

      final json = jsonDecode(response.body);
      return (
        rascunhos: null,
        erro: json['error'] as String? ?? 'Erro ao obter rascunhos',
      );
    } catch (e) {
      return (rascunhos: null, erro: 'Sem ligação ao servidor.');
    }
  }

  // RANKING DE GAMIFICATION — ecrãs 44, 45 e 46
// GET /api/gamification/ranking
  // O endpoint já existe no backend e serve qualquer utilizador autenticado.
  // Devolve array ordenado por pontos, com a evolução face a há 7 dias.
 
  Future<List<RankingEntrada>> obterRanking() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/ranking'),
      headers: headers,
    );
 
    if (response.statusCode == 200) {
      final List<dynamic> jsonList = jsonDecode(response.body);
      return jsonList.map((j) => RankingEntrada.fromJson(j)).toList();
    }
 
    throw Exception('Não foi possível carregar o ranking.');
  }

  // RESUMO DE OBJETIVOS DO DASHBOARD — ecrã 1 (Dashboard)
  // GET /api/dashboard/objetivos-resumo
  // Tal como o ranking, é dado volátil calculado no servidor (progresso de
  // learning path, áreas/service lines completas, objetivos em curso) —
  // não faz sentido guardar em SQLite, pede-se sempre à API.

  // TROCAR PASSWORD NO PRIMEIRO ACESSO
  // PUT /api/auth/trocar-password-primeiro-acesso
  // Obrigatório para contas criadas pelo Admin que ainda nunca fizeram login.
  Future<({bool sucesso, String? erro})> trocarPasswordPrimeiroAcesso(String novaPassword) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/auth/trocar-password-primeiro-acesso'),
        headers: headers,
        body: jsonEncode({'novaPassword': novaPassword}),
      );

      if (response.statusCode == 200) {
        // Actualiza a flag local para não voltar a pedir
        final utilizador = await DatabaseService.instance.getUser();
        final token = await DatabaseService.instance.getToken();
        if (utilizador != null && token != null) {
          await DatabaseService.instance.saveUser(
            Consultor(
              id: utilizador.id,
              nome: utilizador.nome,
              email: utilizador.email,
              telefone: utilizador.telefone,
              urlLinkedin: utilizador.urlLinkedin,
              urlFoto: utilizador.urlFoto,
              dataMembro: utilizador.dataMembro,
              linguaPadrao: utilizador.linguaPadrao,
              idArea: utilizador.idArea,
              nomeArea: utilizador.nomeArea,
              nomeServiceLine: utilizador.nomeServiceLine,
              idLearningPath: utilizador.idLearningPath,
              nomeLearningPath: utilizador.nomeLearningPath,
              totalPontos: utilizador.totalPontos,
              posicaoRanking: utilizador.posicaoRanking,
              aceitouRgpd: utilizador.aceitouRgpd,
              primeiroAcesso: false,
            ),
            token,
          );
        }
        return (sucesso: true, erro: null);
      }

      final json = jsonDecode(response.body);
      return (sucesso: false, erro: json['error'] as String? ?? 'Erro ao trocar a password.');
    } catch (e) {
      return (sucesso: false, erro: 'Sem ligação ao servidor.');
    }
  }

  // ACEITAR / REVOGAR O CONSENTIMENTO RGPD
  // PUT /api/perfil/rgpd
  Future<({bool sucesso, String? erro})> atualizarConsentimentoRgpd(bool aceitar) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${AppConstants.baseUrl}/perfil/rgpd'),
        headers: headers,
        body: jsonEncode({'aceitar': aceitar}),
      );

      if (response.statusCode == 200) {
        final utilizador = await DatabaseService.instance.getUser();
        final token = await DatabaseService.instance.getToken();
        if (utilizador != null && token != null) {
          await DatabaseService.instance.saveUser(
            Consultor(
              id: utilizador.id,
              nome: utilizador.nome,
              email: utilizador.email,
              telefone: utilizador.telefone,
              urlLinkedin: utilizador.urlLinkedin,
              urlFoto: utilizador.urlFoto,
              dataMembro: utilizador.dataMembro,
              linguaPadrao: utilizador.linguaPadrao,
              idArea: utilizador.idArea,
              nomeArea: utilizador.nomeArea,
              nomeServiceLine: utilizador.nomeServiceLine,
              idLearningPath: utilizador.idLearningPath,
              nomeLearningPath: utilizador.nomeLearningPath,
              totalPontos: utilizador.totalPontos,
              posicaoRanking: utilizador.posicaoRanking,
              aceitouRgpd: aceitar,
              primeiroAcesso: utilizador.primeiroAcesso,
            ),
            token,
          );
        }
        return (sucesso: true, erro: null);
      }

      final json = jsonDecode(response.body);
      return (sucesso: false, erro: json['error'] as String? ?? 'Erro ao registar o consentimento.');
    } catch (e) {
      return (sucesso: false, erro: 'Sem ligação ao servidor.');
    }
  }

  // BADGES RECOMENDADOS DO DASHBOARD
  // GET /api/dashboard/badges-recomendados
  // Até 4 badges que o consultor ainda não tem, já priorizados pela área
  // dele — cálculo feito no servidor.
  Future<List<BadgeRecomendado>> obterBadgesRecomendados() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/dashboard/badges-recomendados'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> lista = jsonDecode(response.body);
      return lista.map((j) => BadgeRecomendado.fromJson(j)).toList();
    }

    throw Exception('Não foi possível carregar os badges recomendados.');
  }

  Future<ObjetivosResumo> obterObjetivosResumo() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${AppConstants.baseUrl}/dashboard/objetivos-resumo'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return ObjetivosResumo.fromJson(jsonDecode(response.body));
    }

    throw Exception('Não foi possível carregar o resumo de objetivos.');
  }

}