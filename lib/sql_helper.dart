import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:external_path/external_path.dart';
import 'dart:io';

import 'helper_classes.dart';

/// General helper class that only stores static methods
class SQLHelper {
  /// Creates a table in our database
  /// Using the [database] passed in, creates a table named [table] columns based on the [questions].
  /// [onCreate] is true only when this is called as part of creating the database.
  static Future<void> createTable(Database? database, List<Question> questions,
      String table, bool onCreate) async {
    // create a copy of the passed-in list so we can modify or remove without breaking anything
    var qu = List.of(questions);

    // check to see if we have primary keys. If we don't, add Match Number and Team Number as default keys
    if (!checkQuestions(qu)) {
      qu.insert(
          0,
          const Question(
              type: QuestionType.kNumber,
              label: "Match Number",
              options: ["PRIMARY KEY"]));
      qu.insert(
          1,
          const Question(
              type: QuestionType.kNumber,
              label: "Team Number",
              options: ["PRIMARY KEY"]));
    }

    /// SQL statement used to create table
    String tableBuilder = """
      CREATE TABLE IF NOT EXISTS """ +
        table +
        """ (
        createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    """;

    // if we don't have a database yet, create one in the external directory
    if (!onCreate || database == null) {
      final externalDir = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DCIM);
      final file = File(join(externalDir, 'scouting/scout.db'));
      database = await openDatabase(file.path);
    }

    /// primary key section, kept separate to make concatenation easier.
    String pk = "\nPRIMARY KEY ( ";

    // for each question element
    for (var q in qu) {
      // add the name of the question/column to the table string
      tableBuilder += "\"" + q.label + "\" ";

      // depending on the question type, either store it as an int or as text.
      // right now checkbox is stored as text because a) sqlite does not support
      // booleans and b) it makes inserting a bit cleaner
      switch (q.type) {
        case QuestionType.kNumber:
        case QuestionType.kNumberInc:
          tableBuilder += "INTEGER, ";
          break;
        case QuestionType.kString:
        case QuestionType.kCheckbox:
        case QuestionType.kSelect:
          tableBuilder += "TEXT, ";
          break;
      }

      // if this should be a primary key, add it to the relevant string
      if (q.options.isNotEmpty && q.options[0] == "PRIMARY KEY") {
        pk += "\"" + q.label + "\", ";
      }
    }

    // after we've looped through all the columns, trim off trailing comma/space
    if (pk.trimRight().endsWith(",")) {
      pk = pk.trimRight().substring(0, pk.length - 2);
    }

    // close the primary key string
    tableBuilder += pk + "))";

    // if the database is open, execute our table creation string
    // it should always be open
    if (database.isOpen) {
      await database.execute(tableBuilder);
    }
  }

  /// Checks to see whether our list of [questions] contains a Match Number or
  /// Team Number question.
  /// This ir OR deliberately - pit scouting does not contain a match number
  static bool checkQuestions(List<Question> questions) {
    for (var q in questions) {
      if (q.label == "Match Number" || q.label == "Team Number") return true;
    }
    return false;
  }

  /// Drops a table
  static Future<void> dropTable(List<Question> questions, String table) async {
    final db = await SQLHelper.db(questions, table);
    db.execute("DROP TABLE IF EXISTS " + table);
  }

  /// Get a reference to our database
  static Future<Database> db(List<Question> questions, String table) async {
    final externalDir = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DCIM);
    final file = File(join(externalDir, 'scouting/scout.db'));

    return openDatabase(
      // Set the path to the database. Note: Using the `join` function from the
      // `path` package is best practice to ensure the path is correctly
      // constructed for each platform.
     file.path,

      // When the database is first created, create a table to store dogs.
      onCreate: (db, version) {
        // Run the CREATE TABLE statement on the database.
        return createTable(db, questions, table, true);
      },
      // Set the version. This executes the onCreate function and provides a
      // path to perform database upgrades and downgrades.
      version: 1,
    );
  }

  /// Gets all data from a given match and team number for our review page
  static Future<Map<String, dynamic>> review(int matchNo, int teamNo) async {
    final externalDir = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DCIM);
    final file = File(join(externalDir, 'scouting/scout.db'));


    // get a reference to our database
    final db = await openDatabase(file.path);

    // query each of our tables joined together
    final List<Map<String, dynamic>> answers = await db.rawQuery(
        'SELECT prematch.*, auton.*, teleop.*, endgame.* FROM prematch JOIN auton USING ("Team Number", "Match Number") join teleop USING ("Team Number", "Match Number") join endgame USING ("Team Number", "Match Number") WHERE "Match Number"=? AND "Team Number"=?',
        [matchNo, teamNo]);

    // if this is empty, return an empty map
    if (answers.isEmpty) return {};

    // otherwise return the first response, which should always be unique and the only response for a given match/team number
    return answers[0];
  }

  /// Inserts answers ([data]) to our questions into the database
  static Future<void> insertData(
      List<Question> questions, Map<String, dynamic> data, String table) async {
    // Get a reference to the database.
    final db = await SQLHelper.db(questions, table);
    var q = List.of(questions);

    // if this question set is missing a match or team number, add them
    if (!checkQuestions(q)) {
      q.insert(
          0,
          const Question(
              type: QuestionType.kNumber,
              label: "Match Number",
              options: ["PRIMARY KEY"]));
      q.insert(
          1,
          const Question(
              type: QuestionType.kNumber,
              label: "Team Number",
              options: ["PRIMARY KEY"]));
    }

    // In this case, replace any previous data.
    try {
      await db.insert(
        table,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e, stack) {
      if (kDebugMode) {
        print(e);
        print(stack);
      }

      // if our insert fails, assume it is because we are missing a table.
      // Create one and try again
      await createTable(db, questions, table, true);
      await db.insert(
        table,
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
