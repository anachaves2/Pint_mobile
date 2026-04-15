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
  });

  //fromJson - converto do formato json da API para o objeto
  //O método factory recebe o json (convertido em map de strings pelo package http) e traduz
  factory Objetivo.fromJson(Map<String, dynamic> json) {
    return Objetivo(
      id: json['id'],
      idUtilizador: json['idUtilizador'],
      idLearningPath: json['idLearningPath'],
      idTipoObjetivo: json['idTipoObjetivo'],
      nomeTipoObjetivo: json['nomeTipoObjetivo'],
      dataInicio: DateTime.parse(json['dataInicio']),
      dataFim: DateTime.parse(json['dataFim']),
      dataConclusao: json['dataConclusao'] != null? DateTime.parse(json['dataConclusao']): null, //verifica se é null antes de converter
      alcancado: json['alcancado'] is bool? json['alcancado']: json['alcancado'] == 1, //converte para bool caso 0 ou 1 tenha sido passado com int
      estado: json['estado'],
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
