/// Uma linha do ranking de gamification.
/// Corresponde ao que `GET /api/gamification/ranking` devolve
/// (backend: gamification.controller.js → calcularRanking).
class RankingEntrada {
  final int posicao;
  final int idUtilizador;
  final String nome;
  final String? urlFoto;
  final int totalPontos;

  /// Diferença de posições face a há 7 dias.
  /// Positivo = subiu, negativo = desceu, 0 = manteve.
  final int evolucao;

  RankingEntrada({
    required this.posicao,
    required this.idUtilizador,
    required this.nome,
    this.urlFoto,
    required this.totalPontos,
    required this.evolucao,
  });

  factory RankingEntrada.fromJson(Map<String, dynamic> json) {
    return RankingEntrada(
      posicao: json['posicao'] ?? 0,
      idUtilizador: json['idUtilizador'],
      nome: json['nome'] ?? 'Sem nome',
      urlFoto: json['urlFoto'],
      totalPontos: json['totalPontos'] ?? 0,
      evolucao: json['evolucao'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'posicao': posicao,
        'idUtilizador': idUtilizador,
        'nome': nome,
        'urlFoto': urlFoto,
        'totalPontos': totalPontos,
        'evolucao': evolucao,
      };

  bool get subiu => evolucao > 0;
  bool get desceu => evolucao < 0;
  bool get manteve => evolucao == 0;
}