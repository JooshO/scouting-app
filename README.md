# scouter

FRC5567 Scouting app

To use: Put a questions.json file into InternalStorage/DCIM/scouter. A sample
questions.json is also in the repo. Make sure to allow storage permissions.

JSON Format:
an object containing 5 arrays - prematch, auton, teleop, endgame, pit.
It will expect the presence of each of these arrays.

A question is an object in an array containing:
 - a label (string) - the actual question
 - a type (int) - what type of question. From 0 in order: Number, Number with Increment, String, Select, Checkbox
 - section (string) - which section they are a part of. This is primarily for the generator and doesn't interact with the actual app
 - options (string array) - an array containing possible selections if the question is select, and PRIMARY KEY to denote primary keys
 - deletable, id (string, int) - for the generator

## Deploy instructions
Connect to target android tablet and run in order: `flutter build` `build\app\outputs\flutter-apk\app.apk build\app\outputs\flutter-apk\app-release.apk
` `flutter install` from the home directory of this project.
If flutter is not installed, refer to [their documentation](https://docs.flutter.dev/get-started/install) for installation instructions.

## Current Features
 - Generate form from a local json file
 - Output answers to SQLite db file
 - db file is publicly accessible for easy export
 - pit scouting page
 - recreate tables on local json changes

## TODO
 - possible issue with db design - needs tableau testing
 - more testing