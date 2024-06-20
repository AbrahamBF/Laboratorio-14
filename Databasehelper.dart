import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'team.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'teams.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE teams(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        foundingYear INTEGER,
        lastChampDate TEXT
      )
    ''');
  }

  Future<int> insertTeam(Team team) async {
    Database db = await database;
    return await db.insert('teams', team.toMap());
  }

  Future<List<Team>> getTeams() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('teams');

    return List.generate(maps.length, (i) {
      return Team(
        id: maps[i]['id'],
        name: maps[i]['name'],
        foundingYear: maps[i]['foundingYear'],
        lastChampDate: DateTime.parse(maps[i]['lastChampDate']),
      );
    });
  }

  Future<int> updateTeam(Team team) async {
    Database db = await database;
    return await db.update(
      'teams',
      team.toMap(),
      where: 'id = ?',
      whereArgs: [team.id],
    );
  }

  Future<int> deleteTeam(int id) async {
    Database db = await database;
    return await db.delete(
      'teams',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
