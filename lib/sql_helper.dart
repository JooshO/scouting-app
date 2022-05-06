import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

import 'helper_classes.dart';

class SQLHelper {
  static Future<void> createTables(Database database, List<Question> questions) async {
    String tableBuilder = """
      CREATE TABLE answers(
        matchNo INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
    """;

    for (var q in questions) {
      tableBuilder += ", \"" + q.label + "\" ";
      switch (q.type) {
        case QuestionType.kNumber:
          tableBuilder += "INTEGER ";
          break;
        case QuestionType.kString:
          tableBuilder += "TEXT";
          break;
      }
    }

    tableBuilder += ")";

    await database.execute(tableBuilder);
  }

  static Future<void> dropTable(List<Question> questions) async {
    final db = await SQLHelper.db(questions);
    db.execute("DROP TABLE IF EXISTS answers");
  }

  static Future<Database> db(List<Question> questions) async {
    final Directory? dir = await getExternalStorageDirectory();
    if (kDebugMode) {
      print(dir?.path);
    }

    return openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(dir!.path, 'scout.db'),

      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return createTables(db, questions);
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
  }


  // Define a function that inserts books into the database
  static Future<void> insertData(List<Question> questions, Map<String, dynamic> data) async {
    // Get a reference to the database.
    final db = await SQLHelper.db(questions);

    // In this case, replace any previous data.
    await db.insert(
      'answers',
      data,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}