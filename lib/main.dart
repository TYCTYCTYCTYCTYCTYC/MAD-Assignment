import 'package:flutter/material.dart';
import 'package:mad_ass/home.dart';
import 'package:mad_ass/leaderboard.dart';

bool insertScore = false;
bool played = false;
bool enter = false;
int total_score = 0;
int level = min_level;
final int min_level = 1; //technically toggleable but recommended to be 1
final int max_level = 5; //toggleable parameter
final int top = 25; //toggleable parameter
List<int> score_list = [];
final double startingCountdownTime = 5.0; //toggleable parameter
String? name = null;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Leaderboard.instance.database;

  runApp(
      const MaterialApp(debugShowCheckedModeBanner: false, home: HomePage()));
}
