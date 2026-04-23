class HistoricoCandidatura {
  final int idTransacao;
  final int numCandidatura;
  final int? idResponsavel;
  final String? tipoResponsavel;  // 'Talent Manager' ou 'Service Line Leader'
  final DateTime dataAlteracao;
  final int idEstadoAtual;
  final String? comentario;

  // Estes campos vêm via JOIN da API — nomes dos estados para mostrar na timeline
  final String nomeEstadoAtual;

  HistoricoCandidatura({
    required this.idTransacao,
    required this.numCandidatura,
    this.idResponsavel,
    this.tipoResponsavel,
    required this.dataAlteracao,
    required this.idEstadoAtual,
    this.comentario,
    required this.nomeEstadoAtual,
  });

  factory HistoricoCandidatura.fromJson(Map<String, dynamic> json) {
    return HistoricoCandidatura(
      idTransacao: json['idTransacao'],
      numCandidatura: json['numCandidatura'],
      idResponsavel: json['idResponsavel'],
      tipoResponsavel: json['tipoResponsavel'],
      dataAlteracao: DateTime.parse(json['dataAlteracao']),
      idEstadoAtual: json['idEstadoAtual'],
      nomeEstadoAtual: json['nomeEstadoAtual'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idTransacao': idTransacao,
      'numCandidatura': numCandidatura,
      'idResponsavel': idResponsavel,
      'tipoResponsavel': tipoResponsavel,
      'dataAlteracao': dataAlteracao.toIso8601String(),
      'idEstadoAtual': idEstadoAtual,
      'comentario': comentario,
      'nomeEstadoAtual': nomeEstadoAtual,
    };
  }

  // Verificar que tomou a ação - > do consultor (submissão) ou o responsável (TM/SLL)
  bool get acaoDoConsultor => idResponsavel == null;
  bool get acaoDoTM => tipoResponsavel == 'Talent Manager';
  bool get acaoDoSLL => tipoResponsavel == 'Service Line Leader';
}