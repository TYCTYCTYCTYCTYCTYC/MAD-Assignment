import 'dart:math';
import 'package:intl/intl.dart' as intl;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sqflite/sqflite.dart';
import 'package:vibration/vibration.dart';
import 'package:path/path.dart' as p;

import 'package:mad_ass/main.dart';
// import 'package:mad_ass/home.dart';
// import 'package:mad_ass/game.dart';
// import 'package:mad_ass/leaderboard.dart';

class Leaderboard {
  static const _databaseName = 'leaderboard.db';
  static const _databaseVersion = 1;
  static Database? _database;
  static const table = 'leaderboard';

  Leaderboard._privateConstructor();
  static final Leaderboard instance = Leaderboard._privateConstructor();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, _databaseName);
    return await openDatabase(path,
        version: _databaseVersion, onCreate: _onCreate);
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE Leaderboard (
          name TEXT NOT NULL,
          date DATETIME NOT NULL, 
          score INTEGER NOT NULL,
          PRIMARY KEY (name, date)
        );
          ''');
  }

  static Future<List<Map<String, dynamic>>> insertAndQuery(
      String name, DateTime date, int score) async {
    // Insert the new record
    await _database!.insert(table, {
      "name": name,
      "date": date.toIso8601String(),
      "score": score,
    });

    // Remove excess records if necessary
    final List<Map<String, dynamic>> results = await _database!.query(
      table,
      orderBy: 'Score DESC, Date DESC',
    );
    if (results.length > top) {
      final idsToDelete = results
          .sublist(top)
          .map((result) => result["name"] as String)
          .toList();
      await _database!.delete(
        table,
        where: 'name IN (${idsToDelete.map((_) => '?').join(', ')})',
        whereArgs: idsToDelete,
      );
    }

    return results;
  }

  static Future<List<Map<String, dynamic>>> initialQuery() async {
    final List<Map<String, dynamic>> updatedResults = await _database!.query(
      table,
      orderBy: 'Score DESC, Date DESC',
      limit: top,
    );
    return updatedResults;
  }

  static Future<Map<String, int>> getLeaderboardData() async {
    Map<String, int> output = <String, int>{};
    final List<Map<String, dynamic>> updatedResults = await _database!.query(
      table,
      orderBy: 'Score DESC, Date DESC',
      limit: top,
    );

    int minScore = updatedResults.isNotEmpty ? updatedResults.last['score'] : 0;
    int number = updatedResults.length;
    output["minScore"] = minScore;
    output["number"] = number;
    return output;
  }
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  _LeaderboardPageState createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  bool name_entered = false;
  final nameController = TextEditingController();
  late DateTime now;
  late List<int> temp_score_list;
  late Future<List<Map<String, dynamic>>> results;
  late Future<Map<String, int>> leaderboardData;

  void _onButtonPressed() {
    final tmp = nameController.text.trim();

    if (tmp.isEmpty) {
      Vibration.vibrate(duration: 500);

      Fluttertoast.showToast(
        msg: 'Please input name',
        gravity: ToastGravity.BOTTOM,
      );
    } else {
      name_entered = true;
      name = tmp;

      setState(() {
        results = Leaderboard.insertAndQuery(name!, now, total_score);
      });
    }
  }

  String formattedDate(String input) {
    DateTime tmp = DateTime.parse(input);
    input = intl.DateFormat('dd/MM/yyyy HH:mm:ss').format(tmp);
    return input;
  }

  @override
  void initState() {
    now = DateTime.now();
    name = null;
    super.initState();
    temp_score_list = List.from(score_list);
    score_list.clear();

    results = Leaderboard.initialQuery();
    leaderboardData = Leaderboard.getLeaderboardData();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          total_score = 0;
          // enter = false;
          Navigator.of(context).popUntil((route) => route.isFirst);
          return true;
        },
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Mishy Panic!',
          home: Scaffold(
            appBar: AppBar(
              title: const Text('Leaderboard', style: TextStyle(fontSize: 30)),
              centerTitle: true,
              backgroundColor: Colors.blue,
            ),
            backgroundColor: const Color.fromARGB(255, 180, 231, 255),
            body: Stack(
              children: <Widget>[
                Container(
                  color: Colors.white,
                  child: Center(
                      child: Scrollbar(
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Padding(
                              padding: EdgeInsets.fromLTRB(0, 10, 0, 10)),
                          if (insertScore)
                            Center(
                                child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                const Text(
                                  "TOTAL SCORE",
                                  style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.black,
                                      decoration: TextDecoration.underline),
                                ),
                                Text(
                                  total_score.toString(),
                                  style: const TextStyle(
                                      fontSize: 50, color: Colors.blue),
                                ),
                              ],
                            )),
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: FutureBuilder<List<Map<String, dynamic>>>(
                              future: results,
                              builder: (BuildContext context,
                                  AsyncSnapshot snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(
                                      child: CircularProgressIndicator());
                                }
                                final results = snapshot.data;
                                if (results.length == 0) {
                                  return const Center(
                                    child: Text(
                                        textAlign: TextAlign.center,
                                        "Leaderboard empty!\nNo scores yet!"),
                                  );
                                }
                                int rank = 1;
                                final tableRows = List<TableRow>.generate(
                                    min(results.length, top),
                                    (int index) => TableRow(
                                          decoration: BoxDecoration(
                                            color: results[index]['name'] ==
                                                        name &&
                                                    results[index]['date']
                                                            .toString() ==
                                                        now.toIso8601String()
                                                ? const Color.fromARGB(
                                                    255, 127, 217, 255)
                                                : Colors.white,
                                          ),
                                          children: [
                                            TableCell(
                                              child: Text((rank++).toString()),
                                            ),
                                            TableCell(
                                              child:
                                                  Text(results[index]['name']),
                                            ),
                                            TableCell(
                                              child: Text(results[index]
                                                      ['score']
                                                  .toString()),
                                            ),
                                            TableCell(
                                              child: Text(formattedDate(
                                                  results[index]['date']
                                                      .toString())),
                                            ),
                                          ],
                                        ));
                                return Column(children: <Widget>[
                                  Table(
                                    columnWidths: const {
                                      0: FlexColumnWidth(1.0),
                                      1: FlexColumnWidth(3.0),
                                      2: FlexColumnWidth(1.0),
                                      3: FlexColumnWidth(3.0),
                                    },
                                    border: TableBorder.all(),
                                    children: [
                                      const TableRow(
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                        ),
                                        children: <Widget>[
                                          TableCell(
                                            child: Text('Rank'),
                                          ),
                                          TableCell(
                                            child: Text('Name'),
                                          ),
                                          TableCell(
                                            child: Text('Score'),
                                          ),
                                          TableCell(
                                            child: Text('Date'),
                                          ),
                                        ],
                                      ),
                                      ...tableRows,
                                    ],
                                  )
                                ]);
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(15),
                            child: Center(
                                child: ElevatedButton(
                                    onPressed: () {
                                      total_score = 0;
                                      Navigator.of(context)
                                          .popUntil((route) => route.isFirst);
                                    },
                                    child: const Center(
                                        child: Text('Main menu')))),
                          ),
                        ],
                      ),
                    ),
                  )),
                ),
                if (insertScore)
                  FutureBuilder<Map<String, int>>(
                    future: leaderboardData,
                    builder: (context, snapshot) {
                      if (snapshot.hasData &&
                          (snapshot.data!["minScore"]! <= total_score ||
                              snapshot.data!["number"]! < top) &&
                          !name_entered) {
                        return SizedBox(
                          height: MediaQuery.of(context).size.height -
                              AppBar().preferredSize.height,
                          child: ModalBarrier(
                            dismissible: false,
                            color: Colors.black.withOpacity(0.7),
                          ),
                        );
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
                if (insertScore)
                  FutureBuilder<Map<String, int>>(
                    future: leaderboardData,
                    builder: (context, snapshot) {
                      if (snapshot.hasData &&
                          (snapshot.data!["minScore"]! <= total_score ||
                              snapshot.data!["number"]! < top) &&
                          !name_entered) {
                        return Center(
                            child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.all(15),
                                child: Text(
                                  style: const TextStyle(
                                      fontSize: 32, color: Colors.white),
                                  textAlign: TextAlign.center,
                                  "Congratulations!\nYour score is in the top ${top.toString()}!\nPlease enter player name:",
                                ),
                              ),
                            ),
                            SizedBox(
                              width: MediaQuery.of(context).size.width /
                                  2, //adjust width
                              child: TextField(
                                textAlign: TextAlign.center,
                                controller: nameController,
                                decoration: const InputDecoration(
                                  hintText: 'Enter your name',
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                onSubmitted: (_) => _onButtonPressed(),
                              ),
                            ),
                          ],
                        ));
                      } else {
                        return const SizedBox.shrink();
                      }
                    },
                  ),
              ],
            ),
          ),
        ));
  }
}
