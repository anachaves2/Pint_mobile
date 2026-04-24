import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pint_mobile/utils/constants.dart';

//Modelos
import 'package:pint_mobile/models/consultor.dart';
import 'package:pint_mobile/models/badge_utilizador.dart';
import 'package:pint_mobile/models/badge_regular.dart';
import 'package:pint_mobile/models/badge_especial.dart';
import 'package:pint_mobile/models/tipo_objetivo.dart';
import 'package:pint_mobile/models/candidatura_badge.dart';
import 'package:pint_mobile/models/notificacao.dart';
import 'package:pint_mobile/models/objetivo.dart';
import 'package:pint_mobile/models/estados_candidatura.dart';
import 'package:pint_mobile/models/historico_candidatura.dart';
import 'package:pint_mobile/models/evidencia.dart';
import 'package:pint_mobile/models/requisitos.dart';

class DatabaseService {
  static DatabaseService?
  _instance; //instância do serviço --> só pode haver uma!
  static Database?
  _database; //conexão à base de dados (tipo Database vem do package sgflite)

  DatabaseService._(); //construtor privado

  static DatabaseService get instance {
    //devolve a instancia do serviço existente -> se não existir criar
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<Database> get database async {
    // getter da base de dados -> método para poder 'mexer' na db
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    //metodo privado para criar a base de dados local
    final dbPath = await getDatabasesPath(); // funçao do sqflite que devolve a pasta onde a db está guardada
    final path = join(dbPath, AppConstants.dbName,); // função do package 'path' que devolve o caminho completo do ficheiro.

    return await openDatabase(
      //abre a base de dados
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate, //chamado quando a db é criada pela primeira vez
      onUpgrade: _onUpgrade, //chamado quando a versão muda
    );
  }

    Future<void> updateAreaConsultor({ //Para atualizar a Área do consultor quando vai às defições ou abre a app pela primeira vez
    required int idArea,
    required String nomeArea,
  }) async {
    final db = await database;
    await db.update(
      AppConstants.tableUsers,
      {
        'idArea': idArea,
        'nomeArea': nomeArea,
      },
    );
  }

  //criaçao tabelas locais do sqflite (guarda os dados necessarios aos funcionamento offline)
  // só existem 4 tipos de dados em sqflite: INTEGER TEXT REAL e BLOB
  // as três plicas ''' servem para poder ter as strings em várias linhas

  Future<void> _onCreate(Database db, int version) async {
    // Tabela dos dados do CONSULTOR
    await db.execute('''
      CREATE TABLE ${AppConstants.tableUsers} (
        id INTEGER PRIMARY KEY,
        nome TEXT NOT NULL,
        email TEXT NOT NULL,
        telefone TEXT,
        urlLinkedin TEXT,
        urlFoto TEXT,
        dataMembro TEXT NOT NULL,
        linguaPadrao TEXT,
        idArea INTEGER NOT NULL,
        nomeArea TEXT NOT NULL,
        idLearningPath INTEGER NOT NULL,
        nomeLearningPath TEXT NOT NULL,
        totalPontos INTEGER,
        posicaoRanking INTEGER,
        token TEXT NOT NULL
      )
    ''');

    // Tabela dos BADGES conquistados
    await db.execute('''
      CREATE TABLE ${AppConstants.tableBadgesCache} (
        id INTEGER PRIMARY KEY,
        idBadgeRegular INTEGER,
        idBadgeEspecial INTEGER,
        nomeBadge TEXT NOT NULL,
        nomeNivel TEXT,
        idNivel INTEGER,
        tipoNivel TEXT,
        descricao TEXT,
        pontos INTEGER,
        urlImagem TEXT,
        nomeServiceLine TEXT,
        idServiceLine INTEGER,
        nomeArea TEXT,
        idArea INTEGER,
        dataAtribuicao TEXT NOT NULL,
        dataExpiracao TEXT NOT NULL,
        valido INTEGER NOT NULL,
        urlPublico TEXT,
        tokenValidacao TEXT
      )
    ''');

      // Tabela do catálogo de BADGES REGULARES
    await db.execute('''
      CREATE TABLE ${AppConstants.tableCatalogoBadges} (
        id INTEGER PRIMARY KEY,
        nome TEXT NOT NULL,
        descricao TEXT,
        pontos INTEGER,
        urlImagem TEXT,
        validadeDias INTEGER,
        idNivel INTEGER NOT NULL,
        nomeNivel TEXT NOT NULL,
        idServiceLine INTEGER NOT NULL,
        nomeServiceLine TEXT NOT NULL,
        idArea INTEGER NOT NULL,
        nomeArea TEXT NOT NULL
      )
    ''');

    // Tabela do catálogo de BADGES ESPECIAIS
    await db.execute('''
      CREATE TABLE ${AppConstants.tableCatalogoBadgesEspeciais} (
        id INTEGER PRIMARY KEY,
        nome TEXT NOT NULL,
        descricao TEXT,
        pontos INTEGER,
        validadeDias INTEGER,
        urlImagem TEXT
      )
    ''');

    // Tabela dos ESTADOS DE CANDIDATURA
    await db.execute('''
      CREATE TABLE ${AppConstants.tableEstadosCandidatura} (
        id INTEGER PRIMARY KEY,
        nomeEstado TEXT NOT NULL,
        descricao TEXT
      )
    ''');

    // Tabela das CANDIDATURAS
    await db.execute('''
      CREATE TABLE ${AppConstants.tableCandidaturasCache} (
        numCandidatura INTEGER PRIMARY KEY,
        idBadgeRegular INTEGER NOT NULL,
        idCandidato INTEGER NOT NULL,
        idEstadoAtual INTEGER NOT NULL,
        dataCriacao TEXT NOT NULL,
        nomeBadge TEXT NOT NULL,
        nomeNivel TEXT,
        nomeEstadoAtual TEXT NOT NULL
      )
    ''');

    // Tabela do HISTÓRICO de candidaturas
    await db.execute('''
      CREATE TABLE ${AppConstants.tableHistoricoCandidatura} (
        idTransacao INTEGER PRIMARY KEY,
        numCandidatura INTEGER NOT NULL,
        idResponsavel INTEGER,
        tipoResponsavel TEXT,
        dataAlteracao TEXT NOT NULL,
        idEstadoAtual INTEGER NOT NULL,
        nomeEstadoAtual TEXT NOT NULL,
        comentario TEXT
      )
    ''');

    // Tabela das EVIDÊNCIAS
    await db.execute('''
      CREATE TABLE ${AppConstants.tableEvidenciasCache} (
        id INTEGER PRIMARY KEY,
        numCandidatura INTEGER NOT NULL,
        idRequisito INTEGER NOT NULL,
        idResponsavel INTEGER,
        pathFicheiro TEXT NOT NULL,
        estado TEXT NOT NULL
      )
    ''');

    // Tabela das NOTIFICACOES
    await db.execute('''
      CREATE TABLE ${AppConstants.tableNotificacoesCache} (
        id INTEGER PRIMARY KEY,
        tipoNotificacao TEXT NOT NULL,
        descricao TEXT,
        data TEXT NOT NULL,
        lida INTEGER NOT NULL,
        numCandidatura INTEGER,
        idObjetivo INTEGER,
        idBadgeUtilizador INTEGER,
        idBadgeEspecial INTEGER
      )
    ''');

    // Tabela dos OBJETIVOS
    await db.execute('''
      CREATE TABLE ${AppConstants.tableObjetivosCache} (
        id INTEGER PRIMARY KEY,
        idTipoObjetivo INTEGER NOT NULL,
        nomeTipoObjetivo TEXT NOT NULL,
        dataInicio TEXT NOT NULL,
        dataFim TEXT NOT NULL,
        dataConclusao TEXT,
        alcancado INTEGER NOT NULL,
        estado TEXT NOT NULL
      )
    ''');

    // Tabela dos TIPOS DE OBJETIVOS
    await db.execute('''
      CREATE TABLE ${AppConstants.tableTiposObjetivo} (
        id INTEGER PRIMARY KEY,
        nome TEXT NOT NULL,
        descricao TEXT
      )
    ''');

    // Tabela dos REQUISITOS
    await db.execute('''
      CREATE TABLE ${AppConstants.tableRequisitosCache} (
        id INTEGER PRIMARY KEY,
        idBadgeRegular INTEGER,
        nome TEXT NOT NULL,
        descricao TEXT
      )
    ''');
  }

  // função chamada para atualizar a versão da base de dados caso sejam feitas alterações
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    //ESCREVER AQUI CÓDIGO A IMPLEMENTAR A ALTERAÇÃO.
    //Exemplo -> adicionei uma coluna com a foto do utilizador:
    // if (oldVersion < 2) {
    //await db.execute(
    //'ALTER TABLE ${AppConstants.tableUsers} ADD COLUMN foto TEXT'
    //);
    // }
  }
  //==============================================================
  //Métodos CRUD para o CONSULTOR

  //Inserir dados (login)
  Future<void> saveUser(Consultor consultor, String token) async {
    final db = await database;
    await db.insert(
      AppConstants.tableUsers,
      {
        'id': consultor.id,
        'nome': consultor.nome,
        'email': consultor.email,
        'telefone': consultor.telefone,
        'urlLinkedin': consultor.urlLinkedin,
        'urlFoto': consultor.urlFoto,
        'dataMembro': consultor.dataMembro.toIso8601String(),
        'linguaPadrao': consultor.linguaPadrao,
        'idArea': consultor.idArea,
        'nomeArea': consultor.nomeArea,
        'idLearningPath': consultor.idLearningPath,
        'nomeLearningPath': consultor.nomeLearningPath,
        'totalPontos': consultor.totalPontos,
        'posicaoRanking': consultor.posicaoRanking,
        'token': token,
      },
      conflictAlgorithm:
          ConflictAlgorithm.replace, // substitui o registo se já existir
    );
  }

  //Ler dados
  Future<Consultor?> getUser() async {
    final db = await database;
    final maps = await db.query(AppConstants.tableUsers, limit: 1);

    if (maps.isEmpty) return null; //devolve null se nao houver dados guardados.

    final map = maps.first;
    return Consultor(
      id: map['id'] as int,
      nome: map['nome'] as String,
      email: map['email'] as String,
      telefone: map['telefone'] as String?,
      urlLinkedin: map['urlLinkedin'] as String?,
      urlFoto: map['urlFoto'] as String?,
      dataMembro: DateTime.parse(map['dataMembro'] as String),
      linguaPadrao: map['linguaPadrao'] as String?,
      idArea: map['idArea'] as int,
      nomeArea: map['nomeArea'] as String,
      idLearningPath: map['idLearningPath'] as int,
      nomeLearningPath: map['nomeLearningPath'] as String,
      totalPontos: map['totalPontos'] as int?,
      posicaoRanking: map['posicaoRanking'] as int?,
    );
  }

  //Ler token -> token de autenticaçao das chamadas à API
  Future<String?> getToken() async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableUsers,
      columns: ['token'],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return maps.first['token'] as String?;
  }

  // Actualizar dados - > alterações do consultor aos dados de perfil
  Future<void> updateUser(Consultor consultor) async {
    final db = await database;
    await db.update(
      AppConstants.tableUsers,
      {
        'nome': consultor.nome,
        'telefone': consultor.telefone,
        'urlLinkedin': consultor.urlLinkedin,
        'urlFoto': consultor.urlFoto,
      },
      // O WHERE garante que só actualiza o registo do consultor correcto
      where: 'id = ?',
      whereArgs: [consultor.id],
    );
  }

  //Apagar dados (logout)
  Future<void> deleteUser() async {
    final db = await database;
    await db.delete(AppConstants.tableUsers);
  }

  //=================================================================
  //Métodos CRUD para BADGES

  //Inserir dados
  Future<void> saveBadges(List<BadgeUtilizador> badges) async {
    final db = await database;
    await db.transaction((tnx) async {
      await tnx.delete(
        AppConstants.tableBadgesCache,
      ); // transaçao tnx para garantir que sao copiados os badges todos
      for (final badge in badges) {
        await tnx.insert(
          AppConstants.tableBadgesCache,
          {
            'id': badge.id,
            'idBadgeRegular': badge.idBadgeRegular,
            'idBadgeEspecial': badge.idBadgeEspecial,
            'nomeBadge': badge.nomeBadge,
            'nomeNivel': badge.nomeNivel,
            'idNivel': badge.idNivel,
            'tipoNivel': badge.tipoNivel,
            'descricao': badge.descricao,
            'pontos': badge.pontos,
            'urlImagem': badge.urlImagem,
            'nomeServiceLine': badge.nomeServiceLine,
            'idServiceLine': badge.idServiceLine,
            'nomeArea': badge.nomeArea,
            'idArea': badge.idArea,
            'dataAtribuicao': badge.dataAtribuicao.toIso8601String(),
            'dataExpiracao': badge.dataExpiracao.toIso8601String(),
            'valido': badge.valido ? 1 : 0,
            'urlPublico': badge.urlPublico,
            'tokenValidacao': badge.tokenValidacao,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  //Ler dados
  Future<List<BadgeUtilizador>> getBadges() async {
    final db = await database;
    final maps = await db.query(AppConstants.tableBadgesCache);
    return maps
        .map(
          (map) => BadgeUtilizador(
            id: map['id'] as int,
            idUtilizador: 0,
            idBadgeRegular: map['idBadgeRegular'] as int?,
            idBadgeEspecial: map['idBadgeEspecial'] as int?,
            nomeBadge: map['nomeBadge'] as String,
            nomeNivel: map['nomeNivel'] as String?,
            idNivel: map['idNivel'] as int?,
            tipoNivel: map['tipoNivel'] as String?,
            urlImagem: map['urlImagem'] as String?,
            descricao: map['descricao'] as String?,
            pontos: map['pontos'] as int?,
            nomeServiceLine: map['nomeServiceLine'] as String?,
            idServiceLine: map['idServiceLine'] as int?,
            nomeArea: map['nomeArea'] as String?,
            idArea: map['idArea'] as int?,
            dataAtribuicao: DateTime.parse(map['dataAtribuicao'] as String),
            dataExpiracao: DateTime.parse(map['dataExpiracao'] as String),
            valido: map['valido'] == 1,
            urlPublico: map['urlPublico'] as String?,
            tokenValidacao: map['tokenValidacao'] as String?,
          ),
        )
        .toList();
  }

  //Apagar dados
  Future<void> deleteBadge() async {
    final db = await database;
    await db.delete(AppConstants.tableBadgesCache);
  }

  //===================================================================
  //Métodos CRUD para ESTADOS_CANDIDATURAS

  Future<void> saveEstados(List<EstadoCandidatura> estados) async {
  final db = await database;
  await db.transaction((txn) async {
    await txn.delete(AppConstants.tableEstadosCandidatura);
    for (final estado in estados) {
      await txn.insert(
        AppConstants.tableEstadosCandidatura,
        {
          'id': estado.id,
          'nomeEstado': estado.nomeEstado,
          'descricao': estado.descricao,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  });
}

Future<List<EstadoCandidatura>> getEstados() async {
  final db = await database;
  final maps = await db.query(AppConstants.tableEstadosCandidatura);
  return maps.map((map) => EstadoCandidatura(
    id: map['id'] as int,
    nomeEstado: map['nomeEstado'] as String,
    descricao: map['descricao'] as String?,
  )).toList();
}

Future<void> deleteEstados() async {
  final db = await database;
  await db.delete(AppConstants.tableEstadosCandidatura);
}

//=================================================================
  //Métodos CRUD para CANDIDATURAS

Future<void> saveCandidaturas(List<CandidaturaBadge> candidaturas) async {
  final db = await database;
  await db.transaction((txn) async {
    await txn.delete(AppConstants.tableCandidaturasCache);
    for (final c in candidaturas) {
      await txn.insert(
        AppConstants.tableCandidaturasCache,
        {
          'numCandidatura': c.numCandidatura,
          'idBadgeRegular': c.idBadgeRegular,
          'idCandidato': c.idCandidato,
          'idEstadoAtual': c.idEstadoAtual,
          'dataCriacao': c.dataCriacao.toIso8601String(),
          'nomeBadge': c.nomeBadge,
          'nomeNivel': c.nomeNivel,
          'nomeEstadoAtual': c.nomeEstadoAtual,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  });
}

Future<void> saveOneCandidatura(CandidaturaBadge candidatura) async {
  final db = await database;
  await db.insert(
    AppConstants.tableCandidaturasCache,
    {
      'numCandidatura': candidatura.numCandidatura,
      'idBadgeRegular': candidatura.idBadgeRegular,
      'idCandidato': candidatura.idCandidato,
      'idEstadoAtual': candidatura.idEstadoAtual,
      'dataCriacao': candidatura.dataCriacao.toIso8601String(),
      'nomeBadge': candidatura.nomeBadge,
      'nomeNivel': candidatura.nomeNivel,
      'nomeEstadoAtual': candidatura.nomeEstadoAtual,
    },
    conflictAlgorithm: ConflictAlgorithm.replace,
  );
}

Future<List<CandidaturaBadge>> getCandidaturas() async {
  final db = await database;
  final maps = await db.query(
    AppConstants.tableCandidaturasCache,
    orderBy: 'dataCriacao DESC',
  );
  return maps.map((map) => CandidaturaBadge(
    numCandidatura: map['numCandidatura'] as int,
    idBadgeRegular: map['idBadgeRegular'] as int,
    idCandidato: map['idCandidato'] as int,
    idEstadoAtual: map['idEstadoAtual'] as int,
    dataCriacao: DateTime.parse(map['dataCriacao'] as String),
    nomeBadge: map['nomeBadge'] as String,
    nomeNivel: map['nomeNivel'] as String?,
    nomeEstadoAtual: map['nomeEstadoAtual'] as String,
  )).toList();
}

Future<void> updateCandidatura(CandidaturaBadge candidatura) async {
  final db = await database;
  await db.update(
    AppConstants.tableCandidaturasCache,
    {
      'idEstadoAtual': candidatura.idEstadoAtual,
      'nomeEstadoAtual': candidatura.nomeEstadoAtual,
    },
    where: 'numCandidatura = ?',
    whereArgs: [candidatura.numCandidatura],
  );
}

Future<void> deleteCandidaturas() async {
  final db = await database;
  await db.delete(AppConstants.tableCandidaturasCache);
}


//==============================================================
//Métodos CRUD para HISTORICO_CANDIDATURAS

  Future<void> saveHistorico(List<HistoricoCandidatura> historico) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(AppConstants.tableHistoricoCandidatura);
      for (final h in historico) {
        await txn.insert(
          AppConstants.tableHistoricoCandidatura,
          {
            'idTransacao': h.idTransacao,
            'numCandidatura': h.numCandidatura,
            'idResponsavel': h.idResponsavel,
            'tipoResponsavel': h.tipoResponsavel,
            'dataAlteracao': h.dataAlteracao.toIso8601String(),
            'idEstadoAtual': h.idEstadoAtual,
            'nomeEstadoAtual': h.nomeEstadoAtual,
            'comentario': h.comentario,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<HistoricoCandidatura>> getHistorico(int numCandidatura) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableHistoricoCandidatura,
      where: 'numCandidatura = ?',
      whereArgs: [numCandidatura],
      orderBy: 'dataAlteracao ASC',
    );
    return maps.map((map) => HistoricoCandidatura(
      idTransacao: map['idTransacao'] as int,
      numCandidatura: map['numCandidatura'] as int,
      idResponsavel: map['idResponsavel'] as int?,
      tipoResponsavel: map['tipoResponsavel'] as String?,
      dataAlteracao: DateTime.parse(map['dataAlteracao'] as String),
      idEstadoAtual: map['idEstadoAtual'] as int,
      nomeEstadoAtual: map['nomeEstadoAtual'] as String,
      comentario: map['comentario'] as String?,
    )).toList();
  }

  Future<void> deleteHistorico() async {
    final db = await database;
    await db.delete(AppConstants.tableHistoricoCandidatura);
  }

  //=============================================================
  //Métodos CRUD para EVIDENCIAS

  Future<void> saveEvidencias(List<Evidencia> evidencias) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(AppConstants.tableEvidenciasCache);
      for (final e in evidencias) {
        await txn.insert(
          AppConstants.tableEvidenciasCache,
          {
            'id': e.id,
            'numCandidatura': e.numCandidatura,
            'idRequisito': e.idRequisito,
            'idResponsavel': e.idResponsavel,
            'pathFicheiro': e.pathFicheiro,
            'estado': e.estado,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Evidencia>> getEvidencias(int numCandidatura) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableEvidenciasCache,
      where: 'numCandidatura = ?',
      whereArgs: [numCandidatura],
    );
    return maps.map((map) => Evidencia(
      id: map['id'] as int,
      numCandidatura: map['numCandidatura'] as int,
      idRequisito: map['idRequisito'] as int,
      idResponsavel: map['idResponsavel'] as int?,
      pathFicheiro: map['pathFicheiro'] as String,
      estado: map['estado'] as String,
    )).toList();
  }

  Future<void> deleteEvidencias() async {
    final db = await database;
    await db.delete(AppConstants.tableEvidenciasCache);
  }

    //=======================================================================
    //Métodos CRUD para NOTIFICACÕES


  Future<void> saveNotificacoes(List<Notificacao> notificacoes) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(AppConstants.tableNotificacoesCache);
      for (final n in notificacoes) {
        await txn.insert(
          AppConstants.tableNotificacoesCache,
          {
            'id': n.id,
            'tipoNotificacao': n.tipoNotificacao,
            'descricao': n.descricao,
            'data': n.data.toIso8601String(),
            'lida': n.lida ? 1 : 0,
            'numCandidatura': n.numCandidatura,
            'idObjetivo': n.idObjetivo,
            'idBadgeUtilizador': n.idBadgeUtilizador,
            'idBadgeEspecial': n.idBadgeEspecial,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<Notificacao>> getNotificacoes() async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableNotificacoesCache,
      orderBy: 'data DESC',
    );
    return maps.map((map) => Notificacao(
      id: map['id'] as int,
      tipoNotificacao: map['tipoNotificacao'] as String,
      descricao: map['descricao'] as String?,
      data: DateTime.parse(map['data'] as String),
      lida: map['lida'] == 1,
      numCandidatura: map['numCandidatura'] as int?,
      idObjetivo: map['idObjetivo'] as int?,
      idBadgeUtilizador: map['idBadgeUtilizador'] as int?,
      idBadgeEspecial: map['idBadgeEspecial'] as int?,
    )).toList();
  }

  Future<void> markAsRead(int idNotificacao) async {
    final db = await database;
    await db.update(
      AppConstants.tableNotificacoesCache,
      {'lida': 1},
      where: 'id = ?',
      whereArgs: [idNotificacao],
    );
  }

  Future<void> deleteNotificacao(int idNotificacao) async {
    final db = await database;
    await db.delete(
      AppConstants.tableNotificacoesCache,
      where: 'id = ?',
      whereArgs: [idNotificacao],
    );
  }

  Future<void> deleteNotificacoes() async {
    final db = await database;
    await db.delete(AppConstants.tableNotificacoesCache);
  }

  //===================================================================
  //Métodos CRUD para OBJETIVOS

  //Inserir
  Future<void> saveObjetivos(List<Objetivo> objetivos) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(AppConstants.tableObjetivosCache);
      for (final objetivo in objetivos) {
        await txn.insert(
          AppConstants.tableObjetivosCache,
          {
            'id': objetivo.id,
            'idTipoObjetivo': objetivo.idTipoObjetivo,
            'nomeTipoObjetivo': objetivo.nomeTipoObjetivo,
            'dataInicio': objetivo.dataInicio.toIso8601String(),
            'dataFim': objetivo.dataFim.toIso8601String(),
            'dataConclusao': objetivo.dataConclusao?.toIso8601String(),
            'alcancado': objetivo.alcancado ? 1 : 0,
            'estado': objetivo.estado,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  //Ler
  Future<List<Objetivo>> getObjetivos() async {
    final db = await database;
    final maps = await db.query(AppConstants.tableObjetivosCache);
    return maps
        .map(
          (map) => Objetivo(
            id: map['id'] as int,
            idUtilizador: 0,
            idTipoObjetivo: map['idTipoObjetivo'] as int,
            nomeTipoObjetivo: map['nomeTipoObjetivo'] as String,
            dataInicio: DateTime.parse(map['dataInicio'] as String),
            dataFim: DateTime.parse(map['dataFim'] as String),
            dataConclusao: map['dataConclusao'] != null
                ? DateTime.parse(map['dataConclusao'] as String)
                : null,
            alcancado: map['alcancado'] == 1,
            estado: map['estado'] as String,
          ),
        )
        .toList();
  }

  //Atualizar
  Future<void> updateObjetivo(Objetivo objetivo) async {
    final db = await database;
    await db.update(
      AppConstants.tableObjetivosCache,
      {
        'idTipoObjetivo': objetivo.idTipoObjetivo,
        'nomeTipoObjetivo': objetivo.nomeTipoObjetivo,
        'dataInicio': objetivo.dataInicio.toIso8601String(),
        'dataFim': objetivo.dataFim.toIso8601String(),
        'dataConclusao': objetivo.dataConclusao?.toIso8601String(),
        'alcancado': objetivo.alcancado ? 1 : 0,
        'estado': objetivo.estado,
      },
      where: 'id = ?',
      whereArgs: [objetivo.id],
    );
  }

  // Apaga um objetivo específico
  Future<void> deleteObjetivo(int idObjetivo) async {
    final db = await database;
    await db.delete(
      AppConstants.tableObjetivosCache,
      where: 'id = ?',
      whereArgs: [idObjetivo],
    );
  }

  // Apaga todos os objetivos
  Future<void> deleteObjetivos() async {
    final db = await database;
    await db.delete(AppConstants.tableObjetivosCache);
  }

  //====================================================================
  //Métodos CRUD para BADGE REGULAR

  //Inserir
  Future<void> saveCatalogoBadges(List<BadgeRegular> badges) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(AppConstants.tableCatalogoBadges);
      for (final badge in badges) {
        await txn.insert(
          AppConstants.tableCatalogoBadges,
          {
            'id': badge.id,
            'nome': badge.nome,
            'descricao': badge.descricao,
            'pontos': badge.pontos,
            'urlImagem': badge.urlImagem,
            'validadeDias': badge.validadeDias,
            'idNivel': badge.idNivel,
            'nomeNivel': badge.nomeNivel,
            'idServiceLine': badge.idServiceLine,
            'nomeServiceLine': badge.nomeServiceLine,
            'idArea': badge.idArea,
            'nomeArea': badge.nomeArea,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  //Ler
  Future<List<BadgeRegular>> getCatalogoBadges() async {
    final db = await database;
    final maps = await db.query(AppConstants.tableCatalogoBadges);
    return maps
        .map(
          (map) => BadgeRegular(
            id: map['id'] as int,
            nome: map['nome'] as String,
            descricao: map['descricao'] as String?,
            pontos: map['pontos'] as int?,
            urlImagem: map['urlImagem'] as String?,
            validadeDias: map['validadeDias'] as int?,
            idNivel: map['idNivel'] as int,
            nomeNivel: map['nomeNivel'] as String,
            idServiceLine: map['idServiceLine'] as int,
            nomeServiceLine: map['nomeServiceLine'] as String,
            idArea: map['idArea'] as int,
            nomeArea: map['nomeArea'] as String,
          ),
        )
        .toList();
  }

  //Eliminar
  Future<void> deleteCatalogoBadges() async {
    final db = await database;
    await db.delete(AppConstants.tableCatalogoBadges);
  }

  //========================================================================
  //Métodos CRUD para BADGE ESPECIAL

  Future<void> saveCatalogoBadgesEspeciais(List<BadgeEspecial> badges) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(AppConstants.tableCatalogoBadgesEspeciais);
      for (final badge in badges) {
        await txn.insert(
          AppConstants.tableCatalogoBadgesEspeciais,
          {
            'id': badge.id,
            'nome': badge.nome,
            'descricao': badge.descricao,
            'pontos': badge.pontos,
            'validadeDias': badge.validadeDias,
            'urlImagem': badge.urlImagem,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<BadgeEspecial>> getCatalogoBadgesEspeciais() async {
    final db = await database;
    final maps = await db.query(AppConstants.tableCatalogoBadgesEspeciais);
    return maps
        .map(
          (map) => BadgeEspecial(
            id: map['id'] as int,
            nome: map['nome'] as String,
            descricao: map['descricao'] as String?,
            pontos: map['pontos'] as int?,
            validadeDias: map['validadeDias'] as int?,
            urlImagem: map['urlImagem'] as String?,
          ),
        )
        .toList();
  }

  //Eliminar
  Future<void> deleteCatalogoBadgesEspeciais() async {
    final db = await database;
    await db.delete(AppConstants.tableCatalogoBadgesEspeciais);
  }


  //=========================================================================
  //Métodos CRUD para TIPO OBJETIVOS

  Future<void> saveTiposObjetivo(List<TipoObjetivo> tipos) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(AppConstants.tableTiposObjetivo);
      for (final tipo in tipos) {
        await txn.insert(
          AppConstants.tableTiposObjetivo,
          {'id': tipo.id, 'nome': tipo.nome, 'descricao': tipo.descricao},
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<TipoObjetivo>> getTiposObjetivo() async {
    final db = await database;
    final maps = await db.query(AppConstants.tableTiposObjetivo);
    return maps
        .map(
          (map) => TipoObjetivo(
            id: map['id'] as int,
            nome: map['nome'] as String,
            descricao: map['descricao'] as String?,
          ),
        )
        .toList();
  }

  Future<void> deleteTipoObjetivos() async {
    final db = await database;
    await db.delete(AppConstants.tableTiposObjetivo);
  }

  Future<void> saveRequisitos(List<Requisito> requisitos) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(AppConstants.tableRequisitosCache);
      for (final r in requisitos) {
        await txn.insert(
          AppConstants.tableRequisitosCache,
          {
            'id': r.id,
            'idBadgeRegular': r.idBadgeRegular,
            'nome': r.nome,
            'descricao': r.descricao,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
}

//=============================================================
//Métodos CRUD dos REQUISITOS

  Future<List<Requisito>> getRequisitos(int idBadgeRegular) async {
    final db = await database;
    final maps = await db.query(
      AppConstants.tableRequisitosCache,
      where: 'idBadgeRegular = ?',
      whereArgs: [idBadgeRegular],
    );
    return maps.map((map) => Requisito(
      id: map['id'] as int,
      idBadgeRegular: map['idBadgeRegular'] as int?,
      nome: map['nome'] as String,
      descricao: map['descricao'] as String?,
    )).toList();
  }

  Future<void> deleteRequisitos() async {
    final db = await database;
    await db.delete(AppConstants.tableRequisitosCache);
  }
}
