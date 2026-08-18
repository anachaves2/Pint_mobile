// Corresponde ao que GET /api/dashboard/objetivos-resumo devolve
// (backend: dashboardConsultor.controller.js -> getObjetivosResumo).
// Dado volátil, calculado no servidor — não é guardado em SQLite,
// tal como o ranking (ver providers/ranking_provider.dart).

class ObjetivoProgresso {
  final int id;
  final String titulo;
  final int percentagem; // 0-100
  final int? atual;
  final int? meta;
  final String formato; // 'contagem' ou 'posicao'
  final DateTime dataFim;

  ObjetivoProgresso({
    required this.id,
    required this.titulo,
    required this.percentagem,
    this.atual,
    this.meta,
    required this.formato,
    required this.dataFim,
  });

  factory ObjetivoProgresso.fromJson(Map<String, dynamic> json) {
    return ObjetivoProgresso(
      id: json['id'],
      titulo: json['titulo'] ?? '-',
      percentagem: (json['percentagem'] ?? 0) is int
          ? json['percentagem']
          : (json['percentagem'] as num).round(),
      atual: json['atual'],
      meta: json['meta'],
      formato: json['formato'] ?? 'contagem',
      dataFim: DateTime.parse(json['dataFim']),
    );
  }

  /// Texto do rodapé do item: "3/5" ou "2º · meta Top 3", conforme o formato.
  String get textoProgresso => formato == 'posicao'
      ? '${atual ?? '—'}º · meta Top $meta'
      : '$atual/$meta';
}

class ObjetivosResumo {
  final int progressoLearningPath; // 0-100
  final int areasCompletas;
  final int serviceLinesConcluidas;
  final List<ObjetivoProgresso> objetivosEmProgresso;

  ObjetivosResumo({
    required this.progressoLearningPath,
    required this.areasCompletas,
    required this.serviceLinesConcluidas,
    required this.objetivosEmProgresso,
  });

  factory ObjetivosResumo.fromJson(Map<String, dynamic> json) {
    return ObjetivosResumo(
      progressoLearningPath: json['progressoLearningPath'] ?? 0,
      areasCompletas: json['areasCompletas'] ?? 0,
      serviceLinesConcluidas: json['serviceLinesConcluidas'] ?? 0,
      objetivosEmProgresso: (json['objetivosEmProgresso'] as List<dynamic>? ?? [])
          .map((j) => ObjetivoProgresso.fromJson(j))
          .toList(),
    );
  }

  factory ObjetivosResumo.vazio() => ObjetivosResumo(
        progressoLearningPath: 0,
        areasCompletas: 0,
        serviceLinesConcluidas: 0,
        objetivosEmProgresso: [],
      );
}