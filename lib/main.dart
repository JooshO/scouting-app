import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:scouter/sql_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'elements.dart';
import 'helper_classes.dart';

///
/// Below are the lists of questions to be displayed on each page, in the order
/// that they are displayed.
List<Question> generalQuestions = [];

List<Question> autonQuestions = [];

List<Question> teleopQuestions = [];

List<Question> endgameQuestions = [];

List<Question> pitQuestions = [];

int matchNo = 1;
int teamNo = -1;
List<GlobalKey<FormState>> keys = [];

void main() async {
  // Avoid errors caused by flutter upgrade.
  // Importing 'package:flutter/widgets.dart' is required.
  WidgetsFlutterBinding.ensureInitialized();

  // check our last saved json string for questions
  final prefs = await SharedPreferences.getInstance();
  final questionJson = prefs.getString("questions") ?? "";

  Future<String> readData() async {
    try {
      final Directory? dir = await getExternalStorageDirectory();
      final file = File(join(dir!.path, 'questions.json'));

      // Read the file
      return await file.readAsString();
    } catch (e) {
      // If encountering an error, return 0
      if (kDebugMode) {
        print(e.toString());
      }
      return "";
    }
  }

  final newQuestions = await readData();
  Map<String, dynamic> questions;
  bool dropOldTables = false;
  if (newQuestions.compareTo(questionJson) != 0) {
    await prefs.setString("questions", newQuestions);
    dropOldTables = true;
    questions = jsonDecode(newQuestions);
  } else {
    questions = jsonDecode(questionJson);
  }

  for (dynamic question in questions["prematch"]) {
    generalQuestions.add(Question.fromJson(question));
  }

  for (dynamic question in questions["auton"]) {
    autonQuestions.add(Question.fromJson(question));
  }

  for (dynamic question in questions["teleop"]) {
    teleopQuestions.add(Question.fromJson(question));
  }

  for (dynamic question in questions["endgame"]) {
    endgameQuestions.add(Question.fromJson(question));
  }

  for (dynamic question in questions["pit"]) {
    pitQuestions.add(Question.fromJson(question));
  }

  if (dropOldTables) {
    SQLHelper.dropTable(generalQuestions, "prematch");
    SQLHelper.dropTable(autonQuestions, "auton");
    SQLHelper.dropTable(teleopQuestions, "teleop");
    SQLHelper.dropTable(endgameQuestions, "endgame");
    SQLHelper.dropTable(pitQuestions, "pit");
    await SQLHelper.createTables(null, generalQuestions, "prematch", false);
    await SQLHelper.createTables(null, autonQuestions, "auton", false);
    await SQLHelper.createTables(null, teleopQuestions, "teleop", false);
    await SQLHelper.createTables(null, endgameQuestions, "endgame", false);
    await SQLHelper.createTables(null, pitQuestions, "pit", false);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scouting App',
      theme: ThemeData(
        // This is the theme of your application.
        primarySwatch: Colors.red,
      ),
      home: const MyHomePage(title: 'Scouting Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    const scalar = 0.05;
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scouting App'),
      ),
      body: Center(
          child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                      margin: const EdgeInsets.all(20),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            minimumSize: Size(width * 0.4, width * 0.2),
                            padding: const EdgeInsets.all(16)),
                        child: Text(
                          "Match Scouting",
                          style: TextStyle(
                            fontSize: width * scalar,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  settings:
                                      const RouteSettings(name: "/prematch"),
                                  builder: (context) => const PrematchPage()));
                        },
                      )),
                  Container(
                      margin: const EdgeInsets.all(20),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            minimumSize: Size(width * 0.4, width * 0.2),
                            padding: const EdgeInsets.all(16)),
                        child: Text(
                          "Pit Scouting",
                          style: TextStyle(
                            fontSize: width * scalar,
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  settings: const RouteSettings(name: "/pit"),
                                  builder: (context) => PitPage(
                                        questions: pitQuestions,
                                        tableName: "pit",
                                      )));
                        },
                      ))
                ],
              ))),
    );
  }
}

class PitPage extends StatefulWidget {
  final List<Question> questions;
  final String tableName;

  const PitPage({Key? key, required this.questions, required this.tableName})
      : super(key: key);

  @override
  State<PitPage> createState() => _PitPageState();
}

// we have to do this page separately in order to not route to a normal page
class _PitPageState extends State<PitPage> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, dynamic> _answers = {"\"Team Number\"": teamNo};

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    keys.add(_formKey);
    // Build a Form widget using the _formKey created above.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scouting App'),
      ),
      body: Center(
          child: Column(
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListView.builder(
                    shrinkWrap: true,
                    itemCount: widget.questions.length,
                    padding: const EdgeInsets.all(16.0),
                    itemBuilder: (context, i) {
                      return question(widget.questions[i], _answers);
                    }),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      // Validate returns true if the form is valid, or false otherwise.
                      if (_formKey.currentState!.validate()) {
                        SQLHelper.insertData(
                            widget.questions, _answers, widget.tableName);
                        SQLHelper.review(-1, -1);
                        teamNo = -1;
                        for (var key in keys) {
                          key.currentState?.reset();
                        }
                        keys = keys.sublist(0, 1);
                        if (kDebugMode) {
                          print(keys.toString());
                        }
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: width * 0.03,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      )),
    );
  }
}

class PrematchPage extends StatefulWidget {
  const PrematchPage({Key? key}) : super(key: key);

  @override
  State<PrematchPage> createState() => _PrematchPageState();
}

class _PrematchPageState extends State<PrematchPage> {
  @override
  Widget build(BuildContext context) {
    return questionPage(generalQuestions, "prematch", "auton", context);
  }
}

class AutonPage extends StatefulWidget {
  const AutonPage({Key? key}) : super(key: key);

  @override
  State<AutonPage> createState() => _AutonPageState();
}

class _AutonPageState extends State<AutonPage> {
  @override
  Widget build(BuildContext context) {
    return questionPage(autonQuestions, "auton", "teleop", context);
  }
}

class TeleopPage extends StatefulWidget {
  const TeleopPage({Key? key}) : super(key: key);

  @override
  State<TeleopPage> createState() => _TeleopPageState();
}

class _TeleopPageState extends State<TeleopPage> {
  @override
  Widget build(BuildContext context) {
    return questionPage(teleopQuestions, "teleop", "endgame", context);
  }
}

class EndgamePage extends StatefulWidget {
  const EndgamePage({Key? key}) : super(key: key);

  @override
  State<EndgamePage> createState() => _EndgamePageState();
}

class _EndgamePageState extends State<EndgamePage> {
  @override
  Widget build(BuildContext context) {
    return questionPage(endgameQuestions, "endgame", "review", context);
  }
}

class ReviewPage extends StatefulWidget {
  const ReviewPage({Key? key}) : super(key: key);

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  var _ans = [];
  void _refresh() async {
    final answers = await SQLHelper.review(matchNo, teamNo);
    setState(() {
      _ans = answers.entries.toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _refresh(); // Loading the diary when the app starts
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text('Review: Team ' +
            teamNo.toString() +
            ', match ' +
            matchNo.toString()),
      ),
      body: Center(
          child: Column(
        children: [
          Expanded(
            child: ListView.builder(
                itemCount: _ans.length,
                padding: const EdgeInsets.all(16.0),
                itemBuilder: (context, i) {
                  return ListTile(
                    title: Text(_ans[i].key),
                    subtitle: Text(_ans[i].value.toString()),
                  );
                }),
          ),
          ElevatedButton(
            child: Text(
              "Complete",
              style: TextStyle(
                fontSize: width * .03,
              ),
            ),
            onPressed: () {
              matchNo++;
              teamNo = -1;
              for (var key in keys) {
                key.currentState?.reset();
              }
              keys = keys.sublist(0, 1);
              if (kDebugMode) {
                print(keys.toString());
              }
              Navigator.popUntil(context, ModalRoute.withName("/prematch"));
            },
          )
        ],
      )),
    );
  }
}

class QuestionForm extends StatefulWidget {
  final List<Question> questions;
  final String tableName;
  final String next;

  const QuestionForm(
      {Key? key,
      required this.questions,
      required this.tableName,
      required this.next})
      : super(key: key);

  @override
  State<QuestionForm> createState() => _QuestionFormState();
}

class _QuestionFormState extends State<QuestionForm> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  final Map<String, dynamic> _answers = {
    "\"Match Number\"": matchNo,
    "\"Team Number\"": teamNo
  };

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    keys.add(_formKey);
    // Build a Form widget using the _formKey created above.
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.builder(
              shrinkWrap: true,
              itemCount: widget.questions.length,
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, i) {
                return question(widget.questions[i], _answers);
              }),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                // Validate returns true if the form is valid, or false otherwise.
                if (_formKey.currentState!.validate()) {
                  SQLHelper.insertData(
                      widget.questions, _answers, widget.tableName);
                  if (kDebugMode) {
                    print(_answers["\"" + widget.questions[0].label + "\""]);
                  }
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings: RouteSettings(name: "/" + widget.next),
                          builder: (context) {
                            switch (widget.next) {
                              case "auton":
                                return const AutonPage();
                              case "teleop":
                                return const TeleopPage();
                              case "endgame":
                                return const EndgamePage();
                              case "review":
                                return const ReviewPage();
                              default:
                                return const ReviewPage();
                            }
                          }));
                }
              },
              child: Text(
                'Next',
                style: TextStyle(
                  fontSize: width * 0.03,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget questionPage(List<Question> questions, String current, String next,
    BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Scouting App'),
    ),
    body: Center(
        child: Column(
      children: [
        QuestionForm(
          questions: questions,
          tableName: current,
          next: next,
        ),
      ],
    )),
  );
}
