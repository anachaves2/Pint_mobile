class Evidencia {
  final int id;
  final int numCandidatura;
  final int idRequisito;
  final int? idResponsavel;    // TM que avaliou — null se ainda pendente
  final String pathFicheiro;
  final String estado;          // 'Pendente', 'Aprovada', 'Rejeitada'

  Evidencia({
    required this.id,
    required this.numCandidatura,
    required this.idRequisito,
    this.idResponsavel,
    required this.pathFicheiro,
    required this.estado,
  });

  factory Evidencia.fromJson(Map<String, dynamic> json) {
    return Evidencia(
      id: json['id'],
      numCandidatura: json['numCandidatura'],
      idRequisito: json['idRequisito'],
      idResponsavel: json['idResponsavel'],
      pathFicheiro: json['pathFicheiro'],
      estado: json['estado'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numCandidatura': numCandidatura,
      'idRequisito': idRequisito,
      'idResponsavel': idResponsavel,
      'pathFicheiro': pathFicheiro,
      'estado': estado,
    };
  }

  bool get pendente => estado == 'Pendente';
  bool get aprovada => estado == 'Aprovada';
  bool get rejeitada => estado == 'Rejeitada';
}