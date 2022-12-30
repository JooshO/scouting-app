import 'dart:core';

import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/services.dart';

import 'helper_classes.dart';
import 'main.dart';

/// A widget that contains a question and the ability to answer it depending on
/// the type of question, constructed this way for modularity.
/// Takes in a question to construct from on and a map for answers mapping question text
/// (the string) to a dynamic typed answer - could be boolean, int, string, etc.
Widget question(Question q, Map<String, dynamic> a) {
  var key = "\"" + q.label + "\"";

  switch (q.type) {
    case QuestionType.kNumber:
      return Padding(
          padding: const EdgeInsets.all(8),
          child: TextFormField(
            keyboardType: TextInputType.number,
            initialValue: a.containsKey(key) ? a[key].toString() : null,
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
          ));
    case QuestionType.kNumberInc:
      return Padding(
          padding: const EdgeInsets.all(8),
          child: NumericStepButton(
              initValue: a.containsKey(key) ? a[key] : 0,
              a: a,
              minValue: 0,
              label: q.label,
              onChanged: (value) {
                a.update("\"" + q.label + "\"", (value2) => value,
                    ifAbsent: () => value);
              }));
    case QuestionType.kCheckbox:
      return Padding(
          padding: const EdgeInsets.all(8),
          child: CheckBoxStatus(
              label: q.label,
              a: a,
              initialValue: a.containsKey(key)
                  ? a[key].toString().contains("true")
                  : null));
    case QuestionType.kString:
      return Padding(
          padding: const EdgeInsets.all(8),
          child: TextFormField(
            // The validator receives the text that the user has entered.
            initialValue: a.containsKey(key) ? a[key] : null,
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
          ));
    case QuestionType.kSelect:
      return Padding(
          padding: const EdgeInsets.all(8),
          child: Dropdown(
              label: q.label,
              options: q.options,
              a: a,
              initialValue: a.containsKey(key) ? a[key] : null));
  }
}

// using an example from https://pub.dev/packages/dropdown_button2
class Dropdown extends StatefulWidget {
  final String label;
  final List<String> options;
  final Map<String, dynamic> a;
  final String? initialValue;

  const Dropdown(
      {Key? key,
      this.initialValue,
      required this.label,
      required this.options,
      required this.a})
      : super(key: key);

  @override
  State<Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown> {
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return DropdownButtonHideUnderline(
      child: DropdownButton2(
        hint: Text(
          widget.label,
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).hintColor,
          ),
        ),
        items: widget.options
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ))
            .toList(),
        value: _selectedValue,
        onChanged: (value) {
          setState(() {
            _selectedValue = value as String;
          });
          widget.a.update("\"" + widget.label + "\"", (value2) => value,
              ifAbsent: () => value);
        },
        buttonHeight: height * 0.05,
        buttonDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.black26,
          ),
        ),
        buttonPadding: const EdgeInsets.all(8),
        buttonWidth: 140,
        itemHeight: 40,
      ),
    );
  }
}

// shamelessly borrowed from https://stackoverflow.com/questions/57914542/is-there-a-number-input-field-in-flutter-with-increment-decrement-buttons-attach
class NumericStepButton extends StatefulWidget {
  final int minValue;
  final int maxValue;
  final int initValue;
  final String label;

  final Map<String, dynamic> a;

  final ValueChanged<int> onChanged;

  const NumericStepButton(
      {Key? key,
      this.minValue = 0,
      this.maxValue = 10,
      required this.initValue,
      required this.label,
      required this.onChanged,
      required this.a})
      : super(key: key);

  @override
  State<NumericStepButton> createState() {
    return _NumericStepButtonState();
  }
}

class _NumericStepButtonState extends State<NumericStepButton> {
  late int counter;

  @override
  void initState() {
    super.initState();
    counter = widget.initValue;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Text(widget.label),
        IconButton(
          icon: Icon(
            Icons.remove,
            color: Theme.of(context).colorScheme.secondary,
          ),
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 18.0),
          iconSize: 32.0,
          color: Theme.of(context).primaryColor,
          onPressed: () {
            setState(() {
              if (counter > widget.minValue) {
                counter--;
              }
              widget.onChanged(counter);
            });
          },
        ),
        Text(
          '$counter',
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 18.0,
            fontWeight: FontWeight.w500,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.add,
            color: Theme.of(context).colorScheme.secondary,
          ),
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 18.0),
          iconSize: 32.0,
          color: Theme.of(context).primaryColor,
          onPressed: () {
            setState(() {
              if (counter < widget.maxValue) {
                counter++;
              }
              widget.onChanged(counter);
            });
          },
        ),
      ],
    );
  }
}

class CheckBoxStatus extends StatefulWidget {
  final String label;
  final Map<String, dynamic> a;
  final bool? initialValue;

  const CheckBoxStatus(
      {Key? key, this.initialValue, required this.label, required this.a})
      : super(key: key);

  @override
  State<CheckBoxStatus> createState() => _CheckBoxStatusState();
}

class _CheckBoxStatusState extends State<CheckBoxStatus> {
  var _value = false;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue ?? false;
  }

  @override
  Widget build(BuildContext context) {
    widget.a.update("\"" + widget.label + "\"", (value2) => _value.toString(),
        ifAbsent: () => _value.toString());
    return Row(children: <Widget>[
      const SizedBox(
        width: 10,
      ),
      Text(
        widget.label + ": ",
        style: const TextStyle(fontSize: 17.0),
      ),
      Checkbox(
        value: _value,
        onChanged: (bool? value) {
          widget.a.update(
              "\"" + widget.label + "\"", (value2) => value.toString(),
              ifAbsent: () => value.toString());
          setState(() {
            _value = value!;
          });
        },
      ),
    ]);
  }
}
