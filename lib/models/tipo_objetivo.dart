class TipoObjetivo {
  final int id;
  final String nome;
  final String? descricao;

//Construtor
  TipoObjetivo({
    required this.id,
    required this.nome,
    this.descricao,
  });

//fromJson - converto do formato json da API para o objeto
//O método factory recebe o json (convertido em map de strings pelo package http) e traduz
  factory TipoObjetivo.fromJson(Map<String, dynamic> json) {
    return TipoObjetivo(
      id: json['id'],
      nome: json['nome'],
      descricao: json['descricao'],
    );
  }

//toJson - inverso do fromJson - converte o objecto em json (envia para a API também em map)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
    };
  }
}