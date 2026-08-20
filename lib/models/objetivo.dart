import 'package:pint_mobile/utils/constants.dart'; //necessário para obter do alerta da próximidade de expiração

class Objetivo {
  final int id;
  final int idUtilizador;
  final int? idLearningPath;
  final int idTipoObjetivo;
  final String nomeTipoObjetivo;
  final DateTime dataInicio;
  final DateTime dataFim;
  final DateTime? dataConclusao;
  final bool alcancado; // true se atingido
  final String estado; //"Em Curso" ou "Concluido"
  // Progresso calculado pelo servidor (vem no GET /objetivos)
  final int? atual;
  final int? meta;
  final int? percentagem;
  final String? formato; // 'contagem' ou 'posicao'

  //Construtor
  Objetivo({
    required this.id,
    required this.idUtilizador,
    this.idLearningPath,
    required this.idTipoObjetivo,
    required this.nomeTipoObjetivo,
    required this.dataInicio,
    required this.dataFim,
    this.dataConclusao,
    required this.alcancado,
    required this.estado,
    this.atual,
    this.meta,
    this.percentagem,
    this.formato,
  });

  //fromJson - converto do formato json da API para o objeto
  //O método factory recebe o json (convertido em map de strings pelo package http) e traduz
  // ATENÇÃO: os nomes têm de bater certo com o que a API devolve.
  // GET /api/objetivos devolve: id, idTipoObjetivo, nomeTipo, descricaoTipo,
  // dataInicio, dataFim, atual, meta, percentagem, formato — NÃO devolve
  // idUtilizador, nomeTipoObjetivo, alcancado nem estado.
  // Antes, estes 4 campos eram lidos com nomes que nunca existiam no JSON,
  // o que atirava um erro de tipo em TODOS os objetivos. Como o erro era
  // apanhado em silêncio no sincronizarObjetivos(), a lista ficava sempre
  // vazia — mesmo com objetivos criados no servidor.
  factory Objetivo.fromJson(Map<String, dynamic> json) {
    return Objetivo(
      id: json['id'],
      idUtilizador: json['idUtilizador'] ?? 0,
      idLearningPath: json['idLearningPath'],
      idTipoObjetivo: json['idTipoObjetivo'],
      nomeTipoObjetivo: json['nomeTipo'] ?? json['nomeTipoObjetivo'] ?? 'Objetivo',
      dataInicio: DateTime.parse(json['dataInicio']),
      dataFim: DateTime.parse(json['dataFim']),
      dataConclusao: json['dataConclusao'] != null ? DateTime.parse(json['dataConclusao']) : null,
      alcancado: json['alcancado'] is bool
          ? json['alcancado']
          : (json['alcancado'] ?? 0) == 1,
      // A rota de "em curso" não manda estado — se não vier, é "Em Curso".
      // Na rota de histórico vem em 'resultado'.
      estado: json['estado'] ?? json['resultado'] ?? 'Em Curso',
      atual: json['atual'],
      meta: json['meta'],
      percentagem: json['percentagem'] is int
          ? json['percentagem']
          : (json['percentagem'] as num?)?.round(),
      formato: json['formato'],
    );
  }

  //toJson - inverso do fromJson - converte o objecto em json (envia para a API também em map)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idUtilizador': idUtilizador,
      'idLearningPath': idLearningPath,
      'idTipoObjetivo': idTipoObjetivo,
      'nomeTipoObjetivo': nomeTipoObjetivo,
      'dataInicio': dataInicio.toIso8601String(),  // Iso 8601 - norma que define formato da data e hora
      'dataFim': dataFim.toIso8601String(),
      'dataConclusao': dataConclusao?.toIso8601String(),
      'alcancado': alcancado,
      'estado': estado,
    };
  }

//Métodos auxiliares
  int get diasRestantes {
    return dataFim.difference(DateTime.now()).inDays; //dias até terminar o prazo definido
  }

  bool get ultrapassado {
    return !alcancado && DateTime.now().isAfter(dataFim); //verificar se já passou o prazo
  }

  bool get proximoDoPrazo {
    return !alcancado &&
        diasRestantes <= AppConstants.diasAlertaExpiracao && //verificar se envia alerta
        diasRestantes >= 0;
  }
}