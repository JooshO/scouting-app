import 'dart:core';

import 'package:flutter/material.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

// using an example from https://pub.dev/packages/dropdown_button2
class Dropdown extends StatefulWidget {
  final String label;
  final List<String> options;
  final Map<String, dynamic> a;
  const Dropdown({Key? key, required this.label, required this.options, required this.a}) : super(key: key);

  @override
  State<Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown> {
  String? _selectedValue;
  @override
  Widget build(BuildContext context) {
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
        buttonHeight: 40,
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
  final String label;

  final ValueChanged<int> onChanged;

  const NumericStepButton(
      {Key? key,
        this.minValue = 0,
        this.maxValue = 10,
        required this.label,
        required this.onChanged})
      : super(key: key);

  @override
  State<NumericStepButton> createState() {
    return _NumericStepButtonState();
  }
}

class _NumericStepButtonState extends State<NumericStepButton> {
  int counter = 0;

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

  const CheckBoxStatus({Key? key, required this.label, required this.a}) : super(key: key);

  @override
  State<CheckBoxStatus> createState() => _CheckBoxStatusState();
}

class _CheckBoxStatusState extends State<CheckBoxStatus> {
  var _value = false;

  @override
  Widget build(BuildContext context) {
    widget.a.update("\"" + widget.label + "\"", (value2) => _value.toString(),
        ifAbsent: () => _value.toString());
    return  Row(
        children: <Widget>[
          const SizedBox(width: 10,),
          Text(widget.label + ": " ,style: const TextStyle(fontSize: 17.0), ),
          Checkbox(
            value: _value,
            onChanged: (bool? value) {
              widget.a.update("\"" + widget.label + "\"", (value2) => value.toString(),
                  ifAbsent: () => value.toString());
              setState(() {
                _value = value!;
              });
            },
          ),]);
  }
}
