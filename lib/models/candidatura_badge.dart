import 'package:pint_mobile/models/evidencia.dart';
import 'package:pint_mobile/models/historico_candidatura.dart';

class CandidaturaBadge {
  final int numCandidatura; //ID
  final int idBadgeRegular; // badge a que se candidata
  final int idCandidato; // consultor que se candidata ao badge
  final int idEstadoAtual; //FK para estados
  final DateTime dataCriacao; // quando é submetida pela primeira vez

  //Vem via JOIN da API
  final String nomeBadge;
  final String? nomeNivel;
  final String nomeEstadoAtual;

  //Para carregar as listas de Historico e evidencia se for necessario
  final List<HistoricoCandidatura>? historico;
  final List<Evidencia>? evidencias;

  //Construtor
  CandidaturaBadge({
    required this.numCandidatura,
    required this.idBadgeRegular,
    required this.idCandidato,
    required this.idEstadoAtual,
    required this.dataCriacao,
    required this.nomeBadge,
    this.nomeNivel,
    required this.nomeEstadoAtual,
    this.historico,
    this.evidencias,
  });

  //fromJson - converto do formato json da API para o objeto
  //O método factory recebe o json (convertido em map de strings pelo package http) e traduz
  factory CandidaturaBadge.fromJson(Map<String, dynamic> json) {
    return CandidaturaBadge(
      numCandidatura: json['numCandidatura'],
      idBadgeRegular: json['idBadgeRegular'],
      idCandidato: json['idCandidato'],
      idEstadoAtual: json['idEstadoAtual'],
      dataCriacao: DateTime.parse(json['dataCriacao']),
      nomeBadge: json['nomeBadge'],
      nomeNivel: json['nomeNivel'],
      nomeEstadoAtual: json ['nomeEstadoAtual'],
      historico: json ['historico'] != null ? (json['historico'] as List)
        .map((h) => HistoricoCandidatura.fromJson(h)).toList() : null,
      evidencias: json['evidencias'] != null ? (json['evidencias'] as List)
        .map((e) => Evidencia.fromJson(e)).toList() : null
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'numCandidatura': numCandidatura,
      'idBadgeRegular': idBadgeRegular,
      'idCandidato': idCandidato,
      'idEstadoAtual': idEstadoAtual,
      'dataCriacao': dataCriacao.toIso8601String(),
      'nomeBadge': nomeBadge,
      'nomeNivel': nomeNivel,
      'nomeEstadoAtual': nomeEstadoAtual,
    };
  }

  // Métodos auxiliares
  bool get estaEmValidacaoTM => idEstadoAtual == 1;
  bool get estaEmRetificacaoTM => idEstadoAtual == 2;
  bool get estaEmValidacaoSLL => idEstadoAtual == 3;
  bool get estaEmRetificacaoSLL => idEstadoAtual == 4;
  bool get aprovada => idEstadoAtual == 5;
  bool get rejeitada => idEstadoAtual == 6;

  // O consultor pode agir — está à espera de retificação
  bool get aguardaAcaoConsultor =>
      estaEmRetificacaoTM || estaEmRetificacaoSLL;

  // Processo concluído
  bool get estaConcluida => aprovada || rejeitada;

  // Processo em curso (aguarda validação)
  bool get estaEmValidacao =>
      estaEmValidacaoTM || estaEmValidacaoSLL;
}
