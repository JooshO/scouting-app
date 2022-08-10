import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';

import 'helper_classes.dart';

class SQLHelper {
  static Future<void> createTables(Database? database, List<Question> questions, String table, bool onCreate) async {
    var qu = List.of(questions);

    if (!checkQuestions(qu)) {
      qu.insert(0, const Question(type: QuestionType.kNumber, label: "Match Number", options: ["PRIMARY KEY"]));
      qu.insert(1, const Question(type: QuestionType.kNumber, label: "Team Number", options: ["PRIMARY KEY"]));
    }

    String tableBuilder = """
      CREATE TABLE IF NOT EXISTS """ + table + """ (
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    """;

    if (kDebugMode) {
      print("Creating " + table);
    }


  if (!onCreate || database == null) {
    final Directory? dir = await getExternalStorageDirectory();
    database = await openDatabase(
      join(dir!.path, 'scout.db'),
    );
  }

    String pk = "\nPRIMARY KEY ( ";
    for (var q in qu) {
      tableBuilder += "\"" + q.label + "\" ";
      switch (q.type) {
        case QuestionType.kNumber:
        case QuestionType.kNumberInc:
          tableBuilder += "INTEGER, ";
          if (q.options.isNotEmpty && q.options[0] == "PRIMARY KEY") pk += "\"" + q.label + "\", ";
          break;
        case QuestionType.kString:
        case QuestionType.kCheckbox:
        case QuestionType.kSelect:
          tableBuilder += "TEXT, ";
          break;
      }
    }

    if(pk.trimRight().endsWith(",")) {
      pk = pk.trimRight().substring(0, pk.length - 2);
    }
    tableBuilder += pk + "))";
    if (kDebugMode) {
      print("Is the db open? " + database.isOpen.toString());
    }

    if(database.isOpen) {
      await database.execute(tableBuilder);
      if (!onCreate) {
        database.close();
      }
    }
  }

  static bool checkQuestions(List<Question> questions) {
    for (var q in questions) {
      if (q.label == "Match Number" || q.label == "Team Number") return true;
    }
    return false;
  }

  static Future<void> dropTable(List<Question> questions, String table) async {
    final db = await SQLHelper.db(questions, table);
    db.execute("DROP TABLE IF EXISTS " + table);
  }

  static Future<Database> db(List<Question> questions, String table) async {
    final Directory? dir = await getExternalStorageDirectory();

    return openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
      join(dir!.path, 'scout.db'),

      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return createTables(db, questions, table, true);
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
  }

  static Future<Map<String, dynamic>> review(int matchNo, int teamNo) async {
    final Directory? dir = await getExternalStorageDirectory();

    final db = await openDatabase(join(dir!.path, 'scout.db'));

    final List<Map<String, dynamic>> answers = await db.rawQuery('SELECT prematch.*, auton.*, teleop.*, endgame.* FROM prematch JOIN auton USING ("Team Number", "Match Number") join teleop USING ("Team Number", "Match Number") join endgame USING ("Team Number", "Match Number") WHERE "Match Number"=? AND "Team Number"=?',[matchNo, teamNo]);
    if (kDebugMode) {
      print(answers.toString());
    }

    if (answers.isEmpty) return {};

    return answers[0];
  }

  // Define a function that inserts books into the database
  static Future<void> insertData(List<Question> questions, Map<String, dynamic> data, String table) async {
    // Get a reference to the database.
    final db = await SQLHelper.db(questions, table);
    var q = List.of(questions);

    if (!checkQuestions(q)) {
      q.insert(0, const Question(type: QuestionType.kNumber, label: "Match Number", options: ["PRIMARY KEY"]));
      q.insert(1, const Question(type: QuestionType.kNumber, label: "Team Number", options: ["PRIMARY KEY"]));
    }


    // In this case, replace any previous data.
    try {
      await db.insert(
        table,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stack)
    {
      if (kDebugMode) {
        print(e);
        print(stack);
      }
      await createTables(db, questions, table, true);
      await db.insert(
        table,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}