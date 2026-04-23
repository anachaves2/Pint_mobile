class Notificacao {
  final int id;
  final String tipoNotificacao;
  final String? descricao;
  final DateTime data; // data quando foi gerada
  final bool lida; // se o consultor já a leu
  final int? numCandidatura; // se for sobre uma candidatura
  final int? idObjetivo; // se for sobre um objetivo
  final int? idBadgeUtilizador; // se for sobre um badge conquistado
  final int? idBadgeEspecial; // se for sobre um badge especial

  //Construtor
  Notificacao({
    required this.id,
    required this.tipoNotificacao,
    this.descricao,
    required this.data,
    required this.lida,
    this.numCandidatura,
    this.idObjetivo,
    this.idBadgeUtilizador,
    this.idBadgeEspecial,
  });

  //fromJson - converto do formato json da API para o objeto
  //O método factory recebe o json (convertido em map de strings pelo package http) e traduz
  factory Notificacao.fromJson(Map<String, dynamic> json) {
    return Notificacao(
      id: json['id'],
      tipoNotificacao: json['tipoNotificacao'],
      descricao: json['descricao'],
      data: DateTime.parse(json['data']),
      lida: json['lida'] is bool
          ? json['lida']
          : json['lida'] ==
                1, //converte para bool caso 0 ou 1 tenha sido passado com int
      numCandidatura: json['idCandidatura'],
      idObjetivo: json['idObjetivo'],
      idBadgeUtilizador: json['idBadgeUtilizador'],
      idBadgeEspecial: json['idBadgeEspecial'],
    );
  }

  //toJson - inverso do fromJson - converte o objecto em json (envia para a API também em map)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tipoNotificacao': tipoNotificacao,
      'descricao': descricao,
      'data': data.toIso8601String(),
      'lida': lida,
      'idCandidatura': numCandidatura,
      'idObjetivo': idObjetivo,
      'idBadgeUtilizador': idBadgeUtilizador,
      'idBadgeEspecial': idBadgeEspecial,
    };
  }
}
