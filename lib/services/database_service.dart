import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:pint_mobile/utils/constants.dart';

class DatabaseService {
  static DatabaseService? _instance; //instância do serviço
  static Database? _database; //conexão à base de dados

  DatabaseService._(); //construtor privado

  static DatabaseService get instance {
    //access point ao serviço. Se não existir cria e guarda
    _instance ??= DatabaseService._();
    return _instance!;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
//Getter da base de dados - assincrono
  Future<Database> _initDatabase() async {   //metodo privado para criar a base de dados local
    final dbPath = await getDatabasesPath();  //devolve a pasta onde a db está guardada
    final path = join(dbPath, AppConstants.dbName); //constroi o caminho para o ficheiro

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate, //chamado quando a db é criada pela primeira vez
      onUpgrade: _onUpgrade, //chamado quando a versão muda
    );
  }

//tabelas locais do sqflite (guarda os dados necessarios aos funcionamento offline)
// só existem 4 tipos de dados em sqflite: INTEGER TEXT REAL e BLOB 
// as três plicas ''' servem para poder ter as strings em várias linhas

  Future<void> _onCreate(Database db, int version) async { 

  // Tabela dos dados do consultor
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

    // Tabela dos badges do consultor
    await db.execute('''
      CREATE TABLE ${AppConstants.tableBadgesCache} (
        id INTEGER PRIMARY KEY,
        nome TEXT NOT NULL,
        descricao TEXT,
        pontos INTEGER,
        urlImagem TEXT,
        idNivel INTEGER NOT NULL,
        nomeNivel TEXT NOT NULL,
        idServiceLine INTEGER NOT NULL,
        nomeServiceLine TEXT NOT NULL,
        idArea INTEGER NOT NULL,
        nomeArea TEXT NOT NULL
      )
    ''');

    // Tabela das candidaturas (histórico e dados atuais das candidaturas)
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

    // Tabela das notificações
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

    // Tabela dos objetivos
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
}
