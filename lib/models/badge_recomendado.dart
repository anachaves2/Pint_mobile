// Corresponde ao que GET /api/dashboard/badges-recomendados devolve
// (backend: dashboardConsultor.controller.js -> getBadgesRecomendados).
//
// O backend já faz o trabalho todo: exclui os badges que o consultor já tem
// e prioriza os da área dele. Antes o mobile tentava calcular isto sozinho a
// partir do catálogo em SQLite — se o catálogo ainda não estivesse
// sincronizado, a secção aparecia vazia.

class BadgeRecomendado {
  final int id;
  final String nome;
  final String? nomeNivel;
  final String? urlImagem;
  final int numRequisitos;

  BadgeRecomendado({
    required this.id,
    required this.nome,
    this.nomeNivel,
    this.urlImagem,
    required this.numRequisitos,
  });

  factory BadgeRecomendado.fromJson(Map<String, dynamic> json) {
    return BadgeRecomendado(
      id: json['id'],
      nome: json['nome'] ?? '-',
      nomeNivel: json['nomeNivel'],
      urlImagem: json['urlImagem'],
      numRequisitos: json['numRequisitos'] ?? 0,
    );
  }
}