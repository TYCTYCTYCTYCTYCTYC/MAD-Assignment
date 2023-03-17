import 'package:flutter/material.dart';
import 'package:mad_ass/home.dart';
import 'package:mad_ass/leaderboard.dart';

//testing purposes, test = true uses smaller testing values of min_level, max_level, top and _countdownTime
//else use actual values
const bool test = false;

bool insertScore = false;
bool played = false;
bool enter = false;
int total_score = 0;
int level = min_level;
final int min_level =
    (!test) ? 1 : 1; //technically toggleable but recommended to be 1
final int max_level = (!test) ? 5 : 3; //toggleable parameter
final int top = (!test) ? 25 : 3; //toggleable parameter
List<int> score_list = [];
final double startingCountdownTime = (!test) ? 5.0 : 3.0; //toggleable parameter
String? name = null;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Leaderboard.instance.database;

  runApp(
      const MaterialApp(debugShowCheckedModeBanner: false, home: HomePage()));
}
