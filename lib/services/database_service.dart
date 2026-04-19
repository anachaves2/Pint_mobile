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
    final dbPath =
        await getDatabasesPath(); // funçao do sqflite que devolve a pasta onde a db está guardada
    final path = join(
      dbPath,
      AppConstants.dbName,
    ); // função do package 'path' que devolve o caminho completo do ficheiro

    return await openDatabase(
      //abre a base de dados
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate, //chamado quando a db é criada pela primeira vez
      onUpgrade: _onUpgrade, //chamado quando a versão muda
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
        idArea INTEGER NOT NULL,
        nomeArea TEXT NOT NULL,
        idLearningPath INTEGER NOT NULL,
        nomeLearningPath TEXT NOT NULL,
        totalPontos INTEGER,
        posicaoRanking INTEGER,
        token TEXT NOT NULL
      )
    ''');

    // Tabela dos BADGES
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

    // Tabela das CANDIDATURAS (histórico e dados atuais das candidaturas)
    await db.execute('''
      CREATE TABLE ${AppConstants.tableCandidaturasCache} (
        idTransacao INTEGER PRIMARY KEY,
        idCandidatura INTEGER NOT NULL,
        idBadgeRegular INTEGER NOT NULL,
        nomeBadge TEXT NOT NULL,
        nomeNivel TEXT,
        estadoAtual TEXT NOT NULL,
        estadoAnterior TEXT,
        dataAlteracao TEXT NOT NULL,
        dataSubmissao TEXT,
        dataValidacao TEXT,
        comentario TEXT
      )
    ''');

    // Tabela das NOTIFICACOES
    await db.execute('''
      CREATE TABLE ${AppConstants.tableNotificacoesCache} (
        id INTEGER PRIMARY KEY,
        tipoNotificacao TEXT NOT NULL,
        titulo TEXT,
        descricao TEXT,
        data TEXT NOT NULL,
        lida INTEGER NOT NULL
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

    // Tabela dos TIPOS DE OBJETIVOS
    await db.execute('''
      CREATE TABLE ${AppConstants.tableTiposObjetivo} (
        id INTEGER PRIMARY KEY,
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

  //Métodos CRUD para BADGES

  //Inserir dados
  Future<void> saveBadge(List<BadgeUtilizador> badges) async {
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

  //Métodos CRUD para CANDIDATURAS --> implementar

  //Métodos CRUD para NOTIFICACÕES --> implementar

  //Métodos CRUD para OBJETIVOS --> implementar

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
          'urlImagem': badge.urlImage,
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
    return maps.map((map) => BadgeRegular(
      id: map['id'] as int,
      nome: map['nome'] as String,
      descricao: map['descricao'] as String?,
      pontos: map['pontos'] as int?,
      urlImage: map['urlImagem'] as String?,
      validadeDias: map['validadeDias'] as int?,
      idNivel: map['idNivel'] as int,
      nomeNivel: map['nomeNivel'] as String,
      idServiceLine: map['idServiceLine'] as int,
      nomeServiceLine: map['nomeServiceLine'] as String,
      idArea: map['idArea'] as int,
      nomeArea: map['nomeArea'] as String,
    )).toList();
  }
    //Eliminar
  Future<void> deleteCatalogoBadges() async {
    final db = await database;
    await db.delete(AppConstants.tableCatalogoBadges);
  }

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
    return maps.map((map) => BadgeEspecial(
      id: map['id'] as int,
      nome: map['nome'] as String,
      descricao: map['descricao'] as String?,
      pontos: map['pontos'] as int?,
      validadeDias: map['validadeDias'] as int?,
      urlImagem: map['urlImagem'] as String?,
    )).toList();
  }

  //Eliminar
  Future<void> deleteCatalogoBadgesEspeciais() async {
    final db = await database;
    await db.delete(AppConstants.tableCatalogoBadgesEspeciais);
  }

    //Métodos CRUD para TIPO OBJETIVOS

  Future<void> saveTiposObjetivo(List<TipoObjetivo> tipos) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(AppConstants.tableTiposObjetivo);
      for (final tipo in tipos) {
        await txn.insert(
          AppConstants.tableTiposObjetivo,
          {
            'id': tipo.id,
            'nome': tipo.nome,
            'descricao': tipo.descricao,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<List<TipoObjetivo>> getTiposObjetivo() async {
    final db = await database;
    final maps = await db.query(AppConstants.tableTiposObjetivo);
    return maps.map((map) => TipoObjetivo(
      id: map['id'] as int,
      nome: map['nome'] as String,
      descricao: map['descricao'] as String?,
    )).toList();
  }

  Future<void> deleteTipoObjetivos() async {
    final db = await database;
    await db.delete(AppConstants.tableCatalogoBadgesEspeciais);
  }
}