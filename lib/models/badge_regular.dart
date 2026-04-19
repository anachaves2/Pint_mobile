class BadgeRegular {
  final int id;
  final String nome;
  final String?
  descricao; // colocar '?' nos valores que podem ser nulos -> ver script das tabelas
  final int? pontos;
  final String? urlImagem;
  final int idNivel;
  final String nomeNivel;
  final int idServiceLine;
  final String nomeServiceLine;
  final int idArea;
  final String nomeArea;
  final int? validadeDias;

  //construtor
  BadgeRegular({
    required this.id, //colocar required nos campos obrigatórios
    required this.nome,
    this.descricao,
    this.pontos,
    this.urlImagem,
    required this.idNivel,
    required this.nomeNivel,
    required this.idServiceLine,
    required this.nomeServiceLine,
    required this.idArea,
    required this.nomeArea,
    this.validadeDias,
  });

  //fromJson - converto do formato json da API para o objeto
  //O método factory recebe o json (convertido em map de strings pelo package http) e traduz
  factory BadgeRegular.fromJson(Map<String, dynamic> json) {
    return BadgeRegular(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      pontos: json['pontos'],
      urlImagem: json['urlImagem'],
      idNivel: json['idNivel'],
      nomeNivel: json['nomeNivel'],
      idServiceLine: json['idServiceLine'],
      nomeServiceLine: json['nomeServiceLine'],
      idArea: json['idArea'],
      nomeArea: json['nomeArea'],
      validadeDias: json['validadeDias'],
    );
  }

  //toJson - inverso do fromJson - converte o objecto em json (envia para a API também em map)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'pontos': pontos,
      'urlImagem': urlImagem,
      'idNivel': idNivel,
      'nomeNivel': nomeNivel,
      'idServiceLine': idServiceLine,
      'nomeServiceLine': nomeServiceLine,
      'idArea': idArea,
      'nomeArea': nomeArea,
      'validadeDias': validadeDias,
    };
  }
}
