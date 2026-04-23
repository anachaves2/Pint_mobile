class Requisito {
  final int id;
  final int? idBadgeRegular;  // '?' nos campos que podem ser NULL
  final String nome;
  final String? descricao;

//Construtor
  Requisito({
    required this.id, // required nos campos que não podem ser NULL
    this.idBadgeRegular,
    required this.nome,
    this.descricao,
  });

//fromJson - converto do formato json da API para o objeto
//O método factory recebe o json (convertido em map de strings pelo package http) e traduz
  factory Requisito.fromJson(Map<String, dynamic> json) {
    return Requisito(
      id: json['id'],
      idBadgeRegular: json['idBadgeRegular'],
      nome: json['nome'],
      descricao: json['descricao'],
    );
  }

//toJson - inverso do fromJson - converte o objecto em json (envia para a API também em map)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idBadgeRegular': idBadgeRegular,
      'nome': nome,
      'descricao': descricao,
    };
  }
}