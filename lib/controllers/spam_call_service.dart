import 'package:path/path.dart';
import 'package:secureconnect/models/caller_info.dart';
import 'package:sqflite/sqflite.dart';

class ScamCallsService {
  late Database database;

  Future<void> initialize() async {
    database = await openDatabase(
      join(await getDatabasesPath(), 'spam_calls.db'),
      version: 1,
    );
  }

  Future<List<SpamCall>> getSpamCalls({String? searchQuery}) async {
    final List<Map<String, dynamic>> maps;
    
    if (searchQuery != null && searchQuery.isNotEmpty) {
      maps = await database.query(
        'spam_calls',
        where: 'phoneNumber LIKE ? OR callerName LIKE ?',
        whereArgs: ['%$searchQuery%', '%$searchQuery%'],
        orderBy: 'timestamp DESC',
      );
    } else {
      maps = await database.query(
        'spam_calls',
        orderBy: 'timestamp DESC',
      );
    }

    return List.generate(maps.length, (i) => SpamCall.fromMap(maps[i]));
  }

  Future<void> deleteSpamCall(int id) async {
    await database.delete(
      'spam_calls',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}