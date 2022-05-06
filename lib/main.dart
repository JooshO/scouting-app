import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scouter/sql_helper.dart';

import 'helper_classes.dart';


void main() async {
  // Avoid errors caused by flutter upgrade.
  // Importing 'package:flutter/widgets.dart' is required.
  WidgetsFlutterBinding.ensureInitialized();

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

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const List<Question> _questions = [
    Question(type: QuestionType.kNumber, label: "Team Number", options: []),
    Question(type: QuestionType.kNumber, label: "Points Scored", options: []),
    Question(type: QuestionType.kString, label: "Question 3", options: []),
    Question(type: QuestionType.kString, label: "Question 4", options: []),
    Question(type: QuestionType.kString, label: "Question 6", options: []),
  ];


  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scouting App'),
      ),
      body: const Center(
        child: QuestionForm(questions: _questions, tableName: "answers"),
      ),
    );
  }
}

class QuestionForm extends StatefulWidget {
  final List<Question> questions;
  final String tableName;

  const QuestionForm({Key? key, required this.questions, required this.tableName}) : super(key: key);

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

  final Map<String, dynamic> _answers = {};

  Widget question(Question q, Map<String, dynamic> a) {
    if (q.type == QuestionType.kString) {
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
          a.update("\"" + q.label + "\"", (value2) => value, ifAbsent: () => value);
        },
        onChanged: (dynamic value) {
          a.update("\"" + q.label + "\"", (value2) => value, ifAbsent: () => value);
        },
      );
    } else {
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
            a.update("\"" + q.label + "\"", (value2) => num, ifAbsent: () => num);
          },
        onChanged: (String value) {
          var num = int.parse(value);
          a.update("\"" + q.label + "\"", (value2) => num, ifAbsent: () => num);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
              }
              ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {
                // Validate returns true if the form is valid, or false otherwise.
                if (_formKey.currentState!.validate()) {
                  SQLHelper.insertData(widget.questions, _answers, widget.tableName);
                  if (kDebugMode) {
                    print(_answers["\"" + widget.questions[0].label + "\"" ]);
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
