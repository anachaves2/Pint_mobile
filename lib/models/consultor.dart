class Consultor {
  //Dados da tabela utilizador
  final int id;
  final String nome;
  final String email;
  final String?
  telefone; // colocar '?' nos valores que podem ser nulos -> ver script das tabelas
  final String? urlLinkedin;
  final String? urlFoto;
  final DateTime dataMembro;
  final String? linguaPadrao;

  //Dados da tabela Consultor
  final int idArea;
  final String nomeArea;
  final int idLearningPath;
  final String nomeLearningPath;

  //Dados calculados pela API
  final int? totalPontos;
  final int? posicaoRanking;

  // Construtor
  Consultor({
    required this.id, //colocar required nos campos obrigatórios
    required this.nome,
    required this.email,
    this.telefone,
    this.urlLinkedin,
    this.urlFoto,
    required this.dataMembro,
    this.linguaPadrao,
    required this.idArea,
    required this.nomeArea,
    required this.idLearningPath,
    required this.nomeLearningPath,
    this.totalPontos,
    this.posicaoRanking,
  });

  //fromJson - converto do formato json da API para o objeto
  //O método factory recebe o json (convertido em map de strings pelo package http) e traduz
  factory Consultor.fromJson(Map<String, dynamic> json) {
    return Consultor(
      id: json['id'],
      nome: json['nome'],
      email: json['email'],
      telefone: json['telefone'],
      urlLinkedin: json['urlLinkedin'],
      urlFoto: json['urlFoto'],
      dataMembro: DateTime.parse(
        json['dataMembro'],
      ), // O DateTime.parse converte a string de data no objeto DateTime do Dart
      linguaPadrao: json['linguaPadrao'],
      idArea: json['idArea'],
      nomeArea: json['nomeArea'],
      idLearningPath: json['idLearningPath'],
      nomeLearningPath: json['nomeLearningPath'],
      totalPontos: json['totalPontos'],
      posicaoRanking: json['posicaoRanking'],
    );
  }

  //toJson - inverso do fromJson - converte o objecto em json (envia para a API também em map)
  // Não inclui totalPontos nem posicaoRanking porque serão calculados
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      'telefone': telefone,
      'urlLinkedin': urlLinkedin,
      'urlFoto': urlFoto,
      'dataMembro': dataMembro
          .toIso8601String(), // Iso 8601 - norma que define formato da data e hora
      'linguaPadrao': linguaPadrao,
      'idArea': idArea,
      'nomeArea': nomeArea,
      'idLearningPath': idLearningPath,
      'nomeLearningPath': nomeLearningPath,
    };
  }
}
