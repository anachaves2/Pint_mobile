import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:pint_mobile/utils/constants.dart';
import 'package:pint_mobile/services/database_service.dart';

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

// APIService -> Camada de comunicação com o servidor (PintWeb/backend)

// OFFLINE FIRST:
//   Os métodos de sincronização fazem GET à API e guardam no SQLite
//   A UI lê sempre do SQLite, nunca directamente da API
//Os nomes dos campos JSON que a API deve devolver estão definidos nos fromJson de cada modelo

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

  // Headers HTTP:
  // OS pedidos autenticados precisam do token JWT guardado no SQLite
  // O header 'Authorization: Bearer <token>' é validado no servidor

  Future<Map<String, String>> _getHeaders() async {
    final token = await DatabaseService.instance.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
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

  Future<({bool sucesso, bool configuracaoCompleta, String? erro})> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: _publicHeaders,
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final token = json['token'] as String;
        final consultor = Consultor.fromJson(json['consultor']);
        final configuracaoCompleta =
            json['consultor']['configuracaoCompleta'] as bool? ?? true;

        // Guarda o consultor e o token no SQLite
        await DatabaseService.instance.saveUser(consultor, token);

        return (
          sucesso: true,
          configuracaoCompleta: configuracaoCompleta,
          erro: null,
        );
      }

      // Erros nas credenciais
      final json = jsonDecode(response.body);
      return (
        sucesso: false,
        configuracaoCompleta: false,
        erro: json['error'] as String? ?? 'Erro ao fazer login',
      );
    } catch (e) {
      // Sem internet ou servidor inacessível
      return (
        sucesso: false,
        configuracaoCompleta: false,
        erro: 'Sem ligação ao servidor. Verifica a tua internet.',
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
  }

  //===========================================================
  // MÉTODOS DE SINCRONIZAÇÃO
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
        final badges = jsonList
            .map((j) => BadgeUtilizador.fromJson(j))
            .toList();
        await DatabaseService.instance.saveBadges(badges);
      }
    } catch (e) {
      // Sem internet — mantém os dados locais, a UI continua a funcionar
      print('[APIService] sincronizarBadges: sem ligação ($e)');
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

        final badgesRegulares = (json['regulares'] as List)
            .map((j) => BadgeRegular.fromJson(j))
            .toList();

        final badgesEspeciais = (json['especiais'] as List)
            .map((j) => BadgeEspecial.fromJson(j))
            .toList();

        final requisitos = (json['requisitos'] as List)
            .map((j) => Requisito.fromJson(j))
            .toList();

        // Guarda tudo no SQLite
        await DatabaseService.instance.saveCatalogoBadges(badgesRegulares);
        await DatabaseService.instance.saveCatalogoBadgesEspeciais(
          badgesEspeciais,
        );
        await DatabaseService.instance.saveRequisitos(requisitos);
      }
    } catch (e) {
      print('[APIService] sincronizarCatalogo: sem ligação ($e)');
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
        final candidaturas = jsonList
            .map((j) => CandidaturaBadge.fromJson(j))
            .toList();
        await DatabaseService.instance.saveCandidaturas(candidaturas);
      }
    } catch (e) {
      print('[APIService] sincronizarCandidaturas: sem ligação ($e)');
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
        final historico = (json['historico'] as List)
            .map((j) => HistoricoCandidatura.fromJson(j))
            .toList();
        await DatabaseService.instance.saveHistorico(historico);

        // Adiciona isto após saveHistorico
        final evidencias = (json['evidencias'] as List)
            .map((j) => Evidencia.fromJson(j))
            .toList();
        await DatabaseService.instance.saveEvidencias(evidencias);
      }
    } catch (e) {
      print('[APIService] sincronizarDetalhesCandidatura: sem ligação ($e)');
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
        final estados = jsonList
            .map((j) => EstadoCandidatura.fromJson(j))
            .toList();
        await DatabaseService.instance.saveEstados(estados);
      }
    } catch (e) {
      print('[APIService] sincronizarEstados: sem ligação ($e)');
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
        final objetivos = jsonList.map((j) => Objetivo.fromJson(j)).toList();
        await DatabaseService.instance.saveObjetivos(objetivos);
      }
    } catch (e) {
      print('[APIService] sincronizarObjetivos: sem ligação ($e)');
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
        final tipos = jsonList.map((j) => TipoObjetivo.fromJson(j)).toList();
        await DatabaseService.instance.saveTiposObjetivo(tipos);
      }
    } catch (e) {
      print('[APIService] sincronizarTiposObjetivo: sem ligação ($e)');
    }
  }

  //===================================================
  //NOTIFICAÇÕES: Ecrãs 47-52
  //sincroniza as notificações

  Future<void> sincronizarNotificacoes() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/notificacoes'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        final notificacoes = jsonList
            .map((j) => Notificacao.fromJson(j))
            .toList();
        await DatabaseService.instance.saveNotificacoes(notificacoes);
      }
    } catch (e) {
      print('[APIService] sincronizarNotificacoes: sem ligação ($e)');
    }
  }

  //================================================================
  //SINCRONIZAR TUDO
  // Chama todos os métodos de sincronização

  Future<void> sincronizarTodos() async {
    await Future.wait([
      sincronizarBadges(),
      sincronizarCatalogo(),
      sincronizarCandidaturas(),
      sincronizarObjetivos(),
      sincronizarNotificacoes(),
      sincronizarTiposObjetivo(),
      sincronizarEstados(),
    ]);
  }

  //=======================================================
  //SINCRONIZAÇÃO PERIÓDICA
  //corre continuamente em backgroug no intervalo de tempo definido nas constantes

  void iniciarSincronizacaoPeriodica(Duration intervalo) async {
    _sincronizacaoAtiva = true;
    while (_sincronizacaoAtiva) {
      await sincronizarTodos();
      await Future.delayed(intervalo);
    }
  }

  void pararSincronizacao() {
    _sincronizacaoAtiva = false;
  }
}
