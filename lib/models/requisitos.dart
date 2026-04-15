class Requisito {
  final int id;
  final int idNivel;
  final int? idBadgeRegular;  // '?' nos campos que podem ser NULL
  final String nome;
  final String codigo;
  final String? descricao;
  final String? urlImagem;

//Construtor
  Requisito({
    required this.id, // required nos campos que não podem ser NULL
    required this.idNivel,
    this.idBadgeRegular,
    required this.nome,
    required this.codigo,
    this.descricao,
    this.urlImagem,
  });

//fromJson - converto do formato json da API para o objeto
//O método factory recebe o json (convertido em map de strings pelo package http) e traduz
  factory Requisito.fromJson(Map<String, dynamic> json) {
    return Requisito(
      id: json['id'],
      idNivel: json['idNivel'],
      idBadgeRegular: json['idBadgeRegular'],
      nome: json['nome'],
      codigo: json['codigo'],
      descricao: json['descricao'],
      urlImagem: json['urlImagem'],
    );
  }

//toJson - inverso do fromJson - converte o objecto em json (envia para a API também em map)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idNivel': idNivel,
      'idBadgeRegular': idBadgeRegular,
      'nome': nome,
      'codigo': codigo,
      'descricao': descricao,
      'urlImagem': urlImagem,
    };
  }
}