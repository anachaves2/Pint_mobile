class EstadoCandidatura {
  final int id;
  final String nomeEstado;
  final String? descricao;

  EstadoCandidatura({
    required this.id,
    required this.nomeEstado,
    this.descricao,
  });

  factory EstadoCandidatura.fromJson(Map<String, dynamic> json) {
    return EstadoCandidatura(
      id: json['id'],
      nomeEstado: json['nomeEstado'],
      descricao: json['descricao'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nomeEstado': nomeEstado,
      'descricao': descricao,
    };
  }
}