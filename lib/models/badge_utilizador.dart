import 'package:pint_mobile/utils/constants.dart'; //necessário para obter os dias para expiração do badge definidos nas constantes

class BadgeUtilizador {
  final int id;
  final int idUtilizador;
  final int? idBadgeRegular; //se for regular, caso contrario NULL
  final int? idBadgeEspecial; //se for especial, caso contrário NULL
  final String nomeBadge; // nome do badge regular ou especial
  final String? nomeNivel; // se for especial NULL porque nao tem nível
  final int? idNivel;
  final String? tipoNivel;
  final String? urlImagem; // imagem do badge (regular ou especial)
  final String? descricao;
  final int? pontos;
  final String? nomeServiceLine;
  final int? idServiceLine;
  final String? nomeArea;
  final int? idArea;
  final DateTime dataAtribuicao;
  final DateTime? dataExpiracao; // NULL = badge sem data de expiração (ex.: alguns especiais)
  final bool valido; //se já expirou ou não
  final String? urlPublico;
  final String? tokenValidacao;

  //Construtor
  BadgeUtilizador({
    required this.id, //required nos campos obrigatórios (NOT NULL)
    required this.idUtilizador,
    this.idBadgeRegular,
    this.idBadgeEspecial,
    required this.nomeBadge,
    this.nomeNivel,
    this.idNivel,
    this.tipoNivel,
    this.urlImagem,
    this.descricao,
    this.pontos,
    this.nomeServiceLine,
    this.idServiceLine,
    this.nomeArea,
    this.idArea,
    required this.dataAtribuicao,
    this.dataExpiracao,
    required this.valido,
    this.urlPublico,
    this.tokenValidacao,
  });

  //fromJson - converto do formato json da API para o objeto
  //O método factory recebe o json (convertido em map de strings pelo package http) e traduz
  factory BadgeUtilizador.fromJson(Map<String, dynamic> json) {
    return BadgeUtilizador(
      id: json['id'],
      idUtilizador: json['idUtilizador'],
      idBadgeRegular: json['idBadgeRegular'],
      idBadgeEspecial: json['idBadgeEspecial'],
      nomeBadge: json['nomeBadge'],
      nomeNivel: json['nomeNivel'],
      idNivel: json['idNivel'],
      tipoNivel: json['tipoNivel'],
      urlImagem: json['urlImagem'],
      descricao: json['descricao'],
      pontos: json['pontos'],
      nomeServiceLine: json['nomeServiceLine'],
      idServiceLine: json['idServiceLine'],
      nomeArea: json['nomeArea'],
      idArea: json['idArea'],
      dataAtribuicao: DateTime.parse(json['dataAtribuicao']),
      // ATENÇÃO: dataExpiracao pode vir NULL da API (badges especiais sem
      // validade definida) — DateTime.parse(null) rebentava aqui e, como o
      // .map() da lista inteira falhava de uma vez, NENHUM badge do
      // consultor chegava a ser guardado, mesmo os que tinham data válida.
      dataExpiracao: json['dataExpiracao'] != null ? DateTime.parse(json['dataExpiracao']) : null,
      valido: json['valido'] is bool
          ? json['valido']
          : json['valido'] ==
                1, //Na BD válido é 0 ou 1 mas em dart é true ou false -> O ternário converte para bool caso tenha sido passado seja passado com int
      urlPublico: json['urlPublico'],
      tokenValidacao: json['tokenValidacao'],
    );
  }

  //toJson - inverso do fromJson - converte o objecto em json (envia para a API também em map)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'idUtilizador': idUtilizador,
      'idBadgeRegular': idBadgeRegular,
      'idBadgeEspecial': idBadgeEspecial,
      'nomeBadge': nomeBadge,
      'nomeNivel': nomeNivel,
      'idNivel': idNivel,
      'tipoNivel': tipoNivel,
      'urlImagem': urlImagem,
      'descricao': descricao,
      'pontos': pontos,
      'nomeServiceLine': nomeServiceLine,
      'idServiceLine': idServiceLine,
      'nomeArea': nomeArea,
      'idArea': idArea,
      'dataAtribuicao': dataAtribuicao
          .toIso8601String(), // Iso 8601 - norma que define formato da data e hora
      'dataExpiracao': dataExpiracao?.toIso8601String(),
      'valido': valido,
      'urlPublico': urlPublico,
      'tokenValidacao': tokenValidacao,
    };
  }

  // Métodos auxiliares: badge próximo de expirar e badge expirado
  // Sem dataExpiracao = badge nunca expira, por isso ambos são false.

  bool get estaProximoDeExpirar {
    if (dataExpiracao == null) return false;
    final diasRestantes = dataExpiracao!.difference(DateTime.now()).inDays;
    return diasRestantes <= AppConstants.diasAlertaExpiracao &&
        diasRestantes >= 0;
  }

  bool get jaExpirou {
    if (dataExpiracao == null) return false;
    return dataExpiracao!.isBefore(DateTime.now());
  }
}