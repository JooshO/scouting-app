import 'dart:convert';
import 'dart:core';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:external_path/external_path.dart';
import 'package:scouter/sql_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import 'elements.dart';
import 'helper_classes.dart';

// Below are the lists of questions to be displayed on each page, in the order
// that they are displayed.
List<Question> generalQuestions = [];
List<Question> autonQuestions = [];
List<Question> teleopQuestions = [];
List<Question> endgameQuestions = [];
List<Question> pitQuestions = [];

Map<String, Map<String, dynamic>> answersMap = {};

// tracker for match number and team number for general access
int matchNo = 1;
int teamNo = -1;

// global tracker for form keys to let us clear the forms from anywhere
List<GlobalKey<FormState>> keys = [];

void main() async {
  // Avoid errors caused by flutter upgrade.
  // Importing 'package:flutter/widgets.dart' is required.
  WidgetsFlutterBinding.ensureInitialized();

  // check our last saved json string for questions
  final prefs = await SharedPreferences.getInstance();
  final questionJson = prefs.getString("questions") ?? ""; //a ?? b is basically "if a is null, b instead"

  // read in potential new questions
  final newQuestions = await readData();

  /// a map from our questions to answers (questions represented as strings)
  Map<String, dynamic> questions;
  /// whether we need to drop the tables we have
  bool dropOldTables = false;

  // if our new questions are not the same as our old questions,
  // overwrite our old questions.
  if (newQuestions.compareTo(questionJson) != 0) {
    await prefs.setString("questions", newQuestions);
    dropOldTables = true;
  }

  // If they are the same, we can use either, if they are different, use new.
  // So we will just use the new values
  questions = jsonDecode(newQuestions);

  // fill out our question lists
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

  // if we need to, drop all our old tables and remake them
  if (dropOldTables) {
    SQLHelper.dropTable(generalQuestions, "prematch");
    SQLHelper.dropTable(autonQuestions, "auton");
    SQLHelper.dropTable(teleopQuestions, "teleop");
    SQLHelper.dropTable(endgameQuestions, "endgame");
    SQLHelper.dropTable(pitQuestions, "pit");
    await SQLHelper.createTable(null, generalQuestions, "prematch", false);
    await SQLHelper.createTable(null, autonQuestions, "auton", false);
    await SQLHelper.createTable(null, teleopQuestions, "teleop", false);
    await SQLHelper.createTable(null, endgameQuestions, "endgame", false);
    await SQLHelper.createTable(null, pitQuestions, "pit", false);
  }

  // start the app!
  runApp(const MyApp());
}

/// Reads our saved questions if they are present, returning a blank string if not
/// External storage directory should look like InternalStorage/DCIM/scouting
/// DEV NOTE: Using this area AT ALL is basically deprecated in modern devices.
///           If we get an upgrade at some point, this will probably need to be looked at
Future<String> readData() async {
  try {
    if (await Permission.storage.request().isGranted) {
      final externalDir = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DCIM);
      final file = File(join(externalDir, 'scouting/questions.json'));

      // Read the file
      return await file.readAsString();
    }
    else {
      return "";
    }

  } catch (e) {
    // If encountering an error, return the empty string
    if (kDebugMode) {
      print(e.toString());
    }
    return "";
  }
}

/// app boilerplate mainly
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

/// more boilerplate, this contains our homepage state which is our base page
class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    // get width number and define a scalar we use throughout
    final width = MediaQuery.of(context).size.width;
    const scalar = 0.05;

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
                          // TODO: this uber chugs and IDK why
                          // TODO: Look into restoring values when navigating backwards
                          // Because of the way flutter handles pushing
                          // things onto the naviagtion stack, if we go back one page then forward,
                          // we lose anything we had on the forward page - when we move back
                          // we fully delete the page we navigated away from.
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

class ReviewPage extends StatefulWidget {
  const ReviewPage({Key? key}) : super(key: key);

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  var _ans = [];

  // async helper just for the review page
  // get the answers from our database then refresh this page with those values
  void _refresh() async {
    final answers = await SQLHelper.review(matchNo, teamNo);
    setState(() {
      _ans = answers.entries.toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _refresh(); // Loading the answers when we get to the review page
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
                // action taken on pressing the submit/complete button
                onPressed: () {
                  // increment match number
                  matchNo++;
                  // reset team number
                  teamNo = -1;

                  // clear all of our forms
                  for (var key in keys) {
                    key.currentState?.reset();
                  }

                  answersMap.clear();

                  // remove all keys other than the first page
                  keys = keys.sublist(0, 1);

                  // pop back to the first match scouting page
                  Navigator.popUntil(context, ModalRoute.withName("/prematch"));
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          settings:
                          const RouteSettings(name: "/prematch"),
                          builder: (context) => const PrematchPage()));

                },
              )
            ],
          )),
    );
  }
}

/// The widget that holds the form - what we actually fill out while scouting
class QuestionForm extends StatefulWidget {
  /// questions attached to this page
  final List<Question> questions;
  /// the name of the table this page fills
  final String tableName;
  /// the name of the page this one leads to
  final String next;

  final String current;

  const QuestionForm(
      {Key? key,
        required this.questions,
        required this.tableName,
        required this.current,
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

  Map<String, dynamic> _answers = {
    "\"Match Number\"": matchNo,
    "\"Team Number\"": teamNo
  };

  @override
  void initState() {
    super.initState();
    _answers = answersMap[widget.current] ?? {
      "\"Match Number\"": matchNo,
      "\"Team Number\"": teamNo
    };
  }

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
            // shrink wrap keeps this listview from expanding forever and breaking things
              shrinkWrap: true,
              itemCount: widget.questions.length,
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, i) {
                return question(widget.questions[i], _answers);
              }),
          Padding(
            padding: const EdgeInsets.all(16.0),
            // "next" button
            child: ElevatedButton(
              onPressed: () {
                // Validate returns true if the form is valid, or false otherwise.
                if (_formKey.currentState!.validate()) {
                  SQLHelper.insertData(
                      widget.questions, _answers, widget.tableName);
                  if (kDebugMode) {
                    print(_answers["\"" + widget.questions[0].label + "\""]);
                  }
                  answersMap.update(widget.current, (value) => _answers, ifAbsent: () => _answers);

                  // depending on what we have selected for next, redirect to a
                  // different page
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

/// Generic question page widget.
///
/// [questions] are the questions for this page. [current] is the name of this
/// page, [next] is the name of the page that goes after.
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
              current: current,
              tableName: current,
              next: next,
            ),
          ],
        )),
  );
}


//
// Below are pages and page states for specific pages
//

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

