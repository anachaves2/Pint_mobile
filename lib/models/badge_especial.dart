class BadgeEspecial {
  final int id;
  final String nome;
  final String? descricao; //colocar '?' nos valores que podem ser nulos -> ver script das tabelas
  final int? pontos;
  final int? validadeDias;
  final String? urlImagem;

//Construtor
  BadgeEspecial({
    required this.id,  //colocar required nos campos obrigatórios
    required this.nome,
    this.descricao,
    this.pontos,
    this.validadeDias,
    this.urlImagem,
  });


//fromJson - converto do formato json da API para o objeto
//O método factory recebe o json (convertido em map de strings pelo package http) e traduz
  factory BadgeEspecial.fromJson(Map<String, dynamic> json) {
    return BadgeEspecial(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
      pontos: json['pontos'],
      validadeDias: json['validadeDias'],
      urlImagem: json['urlImagem'],
    );
  }

//toJson - inverso do fromJson - converte o objecto em json (envia para a API também em map)
// Não inclui totalPontos nem posicaoRanking porque serão calculados
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'pontos': pontos,
      'validadeDias': validadeDias,
      'urlImagem': urlImagem,
    };
  }
}