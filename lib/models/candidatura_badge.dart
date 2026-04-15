class CandidaturaBadge {
  final int idTransacao;       // chave primária única de todas as entradas na tabela (trasações)
  final int idCandidatura;     // candidatura a que as transações se referem (permite gerar timeline)
  final int idBadgeRegular;    // badge a que se candidata
  final int idCandidato;       // consultor que se candidata ao badge
  final int? idResponsavel;         // responsável pela validação/aprovação
  final String? tipoResponsavel;    // Talent Manager ou SLL
  final String nomeBadge; 
  final String? nomeNivel;
  final DateTime? dataSubmissao;   // submissão inicial do consultor - NULL se ainda não foi submetida
  final DateTime dataAlteracao;    // data da alteração -> nunca é null: existe a partir do momento em que a candidatura é criada aberta)
  final DateTime? dataValidacao;   // data da validação - NULL se ainda nao foi aprovado/rejeitado
  final String? estadoAnterior;
  final String estadoAtual;
  final String? comentario;        //feedback do TM ou SLL

//Construtor
  CandidaturaBadge({
    required this.idTransacao,
    required this.idCandidatura,
    required this.idBadgeRegular,
    required this.idCandidato,
    this.idResponsavel,
    this.tipoResponsavel,
    required this.nomeBadge,
    this.nomeNivel,
    this.dataSubmissao,
    required this.dataAlteracao,
    this.dataValidacao,
    this.estadoAnterior,
    required this.estadoAtual,
    this.comentario,
  });

//fromJson - converto do formato json da API para o objeto
//O método factory recebe o json (convertido em map de strings pelo package http) e traduz
  factory CandidaturaBadge.fromJson(Map<String, dynamic> json) {
    return CandidaturaBadge(
      idTransacao: json['idTransacao'],
      idCandidatura: json['idCandidatura'],
      idBadgeRegular: json['idBadgeRegular'],
      idCandidato: json['idCandidato'],
      idResponsavel: json['idResponsavel'],
      tipoResponsavel: json['tipoResponsavel'],
      nomeBadge: json['nomeBadge'],
      nomeNivel: json['nomeNivel'],
      dataSubmissao: json['dataSubmissao'] != null? DateTime.parse(json['dataSubmissao']): null,   //Ternário -> verifica se é null antes de converter
      dataAlteracao: DateTime.parse(json['dataAlteracao']),
      dataValidacao: json['dataValidacao'] != null? DateTime.parse(json['dataValidacao']): null,
      estadoAnterior: json['estadoAnterior'],
      estadoAtual: json['estadoAtual'],
      comentario: json['comentario'],
    );
  }

//toJson - inverso do fromJson - converte o objecto em json (envia para a API também em map)
  Map<String, dynamic> toJson() {
    return {
      'idTransacao': idTransacao,
      'idCandidatura': idCandidatura,
      'idBadgeRegular': idBadgeRegular,
      'idCandidato': idCandidato,
      'idResponsavel': idResponsavel,
      'tipoResponsavel': tipoResponsavel,
      'nomeBadge': nomeBadge,
      'nomeNivel': nomeNivel,
      'dataSubmissao': dataSubmissao?.toIso8601String(),  // Iso 8601 - norma que define formato da data e hora
      'dataAlteracao': dataAlteracao.toIso8601String(),
      'dataValidacao': dataValidacao?.toIso8601String(),
      'estadoAnterior': estadoAnterior,
      'estadoAtual': estadoAtual,
      'comentario': comentario,
    };
  }

// Métodos auxiliares
  bool get estaEmAberto {
    return estadoAtual == 'Aberta' || estadoAtual == 'Submetida'; // saber se está aberta permite ocultar/mostrar o botão submeter candidatura
  }

  bool get estaConcluida {
    return estadoAtual == 'Aprovada' || estadoAtual == 'Rejeitada'; //saber que está concluída permite retirá-la das candidaturas pendentes
  }
}