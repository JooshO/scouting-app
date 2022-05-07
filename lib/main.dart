import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouter/sql_helper.dart';

import 'elements.dart';
import 'helper_classes.dart';

const List<Question> generalQuestions = [
  Question(
      type: QuestionType.kNumber,
      label: "Match Number",
      options: ["PRIMARY KEY"]),
  Question(
      type: QuestionType.kNumber,
      label: "Team Number",
      options: ["PRIMARY KEY"]),
  Question(
      type: QuestionType.kSelect, label: "Alliance", options: ["Red", "Blue"]),
  Question(type: QuestionType.kCheckbox, label: "Present?", options: []),
];

const List<Question> autonQuestions = [
  Question(type: QuestionType.kNumberInc, label: "Auton High Goals", options: []),
  Question(type: QuestionType.kNumberInc, label: "Auton Low Goals", options: []),
  Question(type: QuestionType.kCheckbox, label: "Crossed the line?", options: []),
  Question(type: QuestionType.kNumberInc, label: "Auton Terminal intake", options: []),
  Question(type: QuestionType.kNumberInc, label: "Auton Floor intake", options: []),
  Question(type: QuestionType.kString, label: "Auton Fouls", options: []),
];

const List<Question> teleopQuestions = [
  Question(type: QuestionType.kNumberInc, label: "Teleop High Goals", options: []),
  Question(type: QuestionType.kNumberInc, label: "Teleop Low Goals", options: []),
  Question(type: QuestionType.kNumberInc, label: "Teleop Terminal intake", options: []),
  Question(type: QuestionType.kNumberInc, label: "Teleop Floor intake", options: []),
  Question(type: QuestionType.kCheckbox, label: "Breakdown", options: []),
  Question(type: QuestionType.kSelect, label: "Teleop Status", options: ["Normal", "Dead/Unresponsive","Recovered from Unresponsive", "Disabled By Official"]),
  Question(type: QuestionType.kString, label: "Teleop Fouls", options: []),
];

const List<Question> endgameQuestions = [
  Question(type: QuestionType.kSelect, label: "Endgame Status", options: ["Normal", "Dead/Unresponsive","Recovered from Unresponsive", "Disabled By Official"]),
  Question(type: QuestionType.kSelect, label: "Climb Status", options: ["Did not climb", "Low","Medium", "High", "Traverse"]),
  Question(type: QuestionType.kCheckbox, label: "Red Card", options: []),
  Question(type: QuestionType.kCheckbox, label: "Yellow Card", options: []),
  Question(type: QuestionType.kString, label: "Notes", options: []),
];

int matchNo = 1;
int teamNo = -1;
List<GlobalKey<FormState>> keys = [];

void main() async {
  // Avoid errors caused by flutter upgrade.
  // Importing 'package:flutter/widgets.dart' is required.
  WidgetsFlutterBinding.ensureInitialized();
  if(kDebugMode) {
    SQLHelper.dropTable(generalQuestions, "prematch");
    SQLHelper.dropTable(autonQuestions, "auton");
    SQLHelper.dropTable(teleopQuestions, "teleop");
    SQLHelper.dropTable(endgameQuestions, "endgame");
    await SQLHelper.createTables(null, generalQuestions, "prematch", false);
    await SQLHelper.createTables(null, autonQuestions, "auton", false);
    await SQLHelper.createTables(null, teleopQuestions, "teleop", false);
    await SQLHelper.createTables(null, endgameQuestions, "endgame", false);
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
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
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
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scouting App'),
      ),
      body: Center(
          child: Column(
        children: [
          ElevatedButton(
            child: const Text("Match Scouting"),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      settings: const RouteSettings(name: "/prematch"),
                      builder: (context) => const PrematchPage()));
            },
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

// 'Auton Scouting: Team ' +
// teamNo.toString() +
// ', match ' +
// matchNo.toString())

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
          Expanded( child:ListView.builder(
              itemCount: _ans.length,
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, i) {
                return ListTile(
                  title: Text(_ans[i].key),
                  subtitle: Text(_ans[i].value.toString()),
                );
              }),),
          ElevatedButton(
            child: const Text("Complete"),
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
      {Key? key, required this.questions, required this.tableName, required this.next})
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

  Widget question(Question q, Map<String, dynamic> a) {
    switch (q.type) {
      case QuestionType.kNumber:
        return TextFormField(
          keyboardType: TextInputType.number,
          inputFormatters: <TextInputFormatter>[
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          ],
          decoration: InputDecoration(
            labelText: q.label,
          ),
          onFieldSubmitted: (String value) {
            var num = int.parse(value);
            a.update("\"" + q.label + "\"", (value2) => num,
                ifAbsent: () => num);
          },
          onChanged: (String value) {
            var num = int.parse(value);
            a.update("\"" + q.label + "\"", (value2) => num,
                ifAbsent: () => num);
            if (q.label == "Match Number") matchNo = int.parse(value);
            if (q.label == "Team Number") teamNo = int.parse(value);
          },
        );
      case QuestionType.kNumberInc:
        a.update("\"" + q.label + "\"", (value2) => 0, ifAbsent: () => 0);
        return NumericStepButton(
            minValue: 0,
            label: q.label,
            onChanged: (value) {
              a.update("\"" + q.label + "\"", (value2) => value,
                  ifAbsent: () => value);
            });
      case QuestionType.kCheckbox:
        return CheckBoxStatus(label: q.label, a: a);
    case QuestionType.kString:
        return TextFormField(
          // The validator receives the text that the user has entered.
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter some text';
            }
            return null;
          },
          decoration: InputDecoration(
            labelText: q.label,
          ),
          onFieldSubmitted: (dynamic value) {
            a.update("\"" + q.label + "\"", (value2) => value,
                ifAbsent: () => value);
          },
          onChanged: (dynamic value) {
            a.update("\"" + q.label + "\"", (value2) => value,
                ifAbsent: () => value);
          },
        );
      case QuestionType.kSelect:
        return Dropdown(label: q.label, options: q.options, a: a);
    }
  }

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(vertical: 16.0),
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
                              case "auton": return const AutonPage();
                              case "teleop": return const TeleopPage();
                              case "endgame": return const EndgamePage();
                              case "review": return const ReviewPage();
                              default: return const ReviewPage();
                            }
                          }));
                }
              },
              child: const Text('Next'),
            ),
          ),
        ],
      ),
    );
  }
}

Widget questionPage(List<Question> questions, String current, String next, BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Scouting App'),
    ),
    body: Center(
        child: Column(
          children: [
            QuestionForm(
                questions: questions, tableName: current, next: next,),
          ],
        )),
  );
}