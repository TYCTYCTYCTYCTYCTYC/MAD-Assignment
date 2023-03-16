// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vibration/vibration.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart' as intl;

//testing purposes, test = true uses smaller testing values of min_level, max_level, top and _countdownTime
//else use actual values
const bool test = true;

bool insertScore = false;
bool played = false;
// bool enter = false;
int total_score = 0;
int level = min_level;
const int min_level =
    (!test) ? 1 : 1; //technically toggleable but recommended to be 1
const int max_level = (!test) ? 5 : 3; //toggleable parameter
const int top = (!test) ? 25 : 3; //toggleable parameter
List<int> score_list = [];
final double _startingCountdownTime =
    (!test) ? 5.0 : 3.0; //toggleable parameter
String? name = null;

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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final db = await Leaderboard.instance.database;

  runApp(
      const MaterialApp(debugShowCheckedModeBanner: false, home: MainPage()));
}

class Game extends StatefulWidget {
  const Game({super.key});

  @override
  State<Game> createState() => _GameState();
}

class _GameState extends State<Game> {
  //page state data
  bool _isGreyedOut = true, _startTimerCountdown = false;

  //timer and score data
  int _countdownSeconds = 3;
  int active_index = 0;
  int grid_count = level + 1;
  int score = 0;
  late int _startCountdownSeconds;

  double _countdownTime = _startingCountdownTime;

  late Timer timer;
  late Timer initialTimer;
  late TextSpan span = TextSpan(
      text: 'remaining time\n${_countdownTime.toStringAsFixed(1)}',
      style: const TextStyle(fontSize: 16, color: Colors.black));
  late TextPainter tp = TextPainter(
      text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
  late double textHeight;

  //image state data
  late List<int> image_status =
      List.generate(grid_count * grid_count, (index) => 0);
  late List<int> remaining =
      List.generate(grid_count * grid_count, (index) => index);
  List<ImageProvider> images = [
    const AssetImage('assets/images/no_mishy.png'),
    const AssetImage('assets/images/mishy_pop.png'),
    const AssetImage('assets/images/mishy_bop.png'),
    const AssetImage('assets/images/mishy_sadge.png')
  ];

  String format(int countdownSeconds) {
    if (_countdownSeconds == _startCountdownSeconds) {
      return "Ready ...";
    } else if (_countdownSeconds == 1) {
      return "Start!";
    } else {
      return (countdownSeconds - 1).toString();
    }
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        if (_countdownTime <= 0) {
          promptCont();
        } else {
          _countdownTime = max(_countdownTime - 0.1, 0);
        }
      });
    });
  }

  void _startCountdown() {
    _countdownSeconds += 2;
    setState(() {
      _isGreyedOut = true;
      _startTimerCountdown = true; //manually set on end of promptCont snippet
    });

    initialTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownSeconds--;
      });

      if (_countdownSeconds == 0) {
        timer.cancel();
        setState(() {
          _isGreyedOut = false;
          _startTimerCountdown = false;
          image_status[remaining[0]] = 1;
          _startTimer();
        });
      }
    });
  }

  void promptCont() {
    timer.cancel();
    total_score += score;
    score_list.add(score);
    score = 0;

    _isGreyedOut = true;
    _startTimerCountdown = false;
  }

  void endGame() {
    //stop countdown
    timer.cancel();

    if (level < max_level) {
      setState(() {
        level++;

        //reinitialize
        grid_count = level + 1;
        image_status = List.generate(grid_count * grid_count, (index) => 0);
        remaining = List.generate(grid_count * grid_count, (index) => index);
        _isGreyedOut = true;
        _countdownSeconds = 3;
        _countdownTime = _startingCountdownTime;

        remaining.shuffle();
        tp.layout();
        textHeight = tp.size.height;
        _startCountdownSeconds = _countdownSeconds + 2;
        _startCountdown();
      });
    } else {
      total_score += score;
      score_list.add(score);
      score = 0;
      insertScore = true;
      // enter = true;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LeaderboardPage()),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    remaining.shuffle();
    tp.layout();
    textHeight = tp.size.height;
    _startCountdownSeconds = _countdownSeconds + 2;
    _startCountdown();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "Mishy Panic!",
            home: Scaffold(
              appBar: AppBar(
                title: Text('LEVEL ${level - min_level + 1}',
                    style: const TextStyle(fontSize: 30)),
                centerTitle: true,
                backgroundColor: Colors.blue,
              ),
              backgroundColor: const Color.fromARGB(255, 180, 231, 255),
              body: Stack(children: <Widget>[
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        "remaining time\n${_countdownTime.toStringAsFixed(1)}s",
                        textAlign: TextAlign.center,
                        style:
                            const TextStyle(fontSize: 16, color: Colors.black),
                      ),
                      Builder(builder: (BuildContext context) {
                        return Center(
                            child: SizedBox(
                          height: min(
                              MediaQuery.of(context).size.height -
                                  AppBar().preferredSize.height -
                                  textHeight,
                              MediaQuery.of(context).size.width),
                          width: min(
                              MediaQuery.of(context).size.height -
                                  AppBar().preferredSize.height -
                                  textHeight,
                              MediaQuery.of(context).size.width),
                          child: GridView.count(
                            crossAxisCount: grid_count,
                            children:
                                List.generate(grid_count * grid_count, (index) {
                              return Material(
                                child: GestureDetector(
                                  onTapDown: (TapDownDetails details) {
                                    setState(() {
                                      if (index == remaining[0]) {
                                        //some issue here, remaining can be empty
                                        score++;
                                        image_status[index] = 2;
                                        remaining.removeAt(0);
                                        if (remaining.isNotEmpty == true) {
                                          image_status[remaining[0]] = 1;
                                        } else {
                                          promptCont();
                                        }
                                      }
                                    });
                                  },
                                  onTap: () {
                                    setState(() {
                                      Future.delayed(
                                              const Duration(milliseconds: 150))
                                          .then((value) {
                                        if (image_status[index] == 2) {
                                          image_status[index] = 3;
                                        }
                                      });
                                    });
                                  },
                                  child: ClipRRect(
                                      child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: images[image_status[index]],
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  )),
                                ),
                              );
                            }),
                          ),
                        ));
                      })
                    ],
                  ),
                ),
                if (_isGreyedOut)
                  SizedBox(
                    height: MediaQuery.of(context).size.height -
                        AppBar().preferredSize.height,
                    child: ModalBarrier(
                      dismissible: false,
                      color: Colors.black.withOpacity(0.7),
                    ),
                  ),
                if (_isGreyedOut && _startTimerCountdown)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          format(_countdownSeconds),
                          style: const TextStyle(
                              fontSize: 64, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                if (_isGreyedOut && !_startTimerCountdown)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Evaluation",
                          style: TextStyle(fontSize: 64, color: Colors.white),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(15),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.8,
                            child: Table(
                              border: TableBorder.all(),
                              columnWidths: const <int, TableColumnWidth>{
                                0: FlexColumnWidth(1),
                                1: FlexColumnWidth(1),
                              },
                              children: <TableRow>[
                                for (int i = 0; i < score_list.length; i++)
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                    ),
                                    children: <Widget>[
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'Level ${i + 1}',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      TableCell(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            '${score_list[i]}',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                TableRow(
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                  ),
                                  children: <Widget>[
                                    const TableCell(
                                      child: Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          'Total Score',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    TableCell(
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          '${score_list.fold(0, (prev, curr) => prev + curr)}',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            //quit button
                            Padding(
                              padding: const EdgeInsets.all(15),
                              child: ElevatedButton(
                                  onPressed: () {
                                    insertScore = true;
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              const LeaderboardPage()),
                                    );
                                  },
                                  child: const Center(child: Text('Quit'))),
                            ),
                            if (level < max_level)
                              Padding(
                                padding: const EdgeInsets.all(15),
                                child: ElevatedButton(
                                    onPressed: () {
                                      endGame();
                                    },
                                    child:
                                        const Center(child: Text('Continue'))),
                              )
                            //continut botton
                          ],
                        )
                      ],
                    ),
                  ),
              ]),
            )),
        onWillPop: () async {
          timer.cancel();
          initialTimer.cancel();
          return true;
        });
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Mishy Panic!',
        home: Scaffold(
            backgroundColor: const Color.fromARGB(255, 180, 231, 255),
            body: Center(
                child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Center(
                      child: Image.asset(
                        'assets/images/title.png',
                        width: max(MediaQuery.of(context).size.width / 2,
                            MediaQuery.of(context).size.height / 2),
                        height: max(MediaQuery.of(context).size.width / 2,
                            MediaQuery.of(context).size.height / 2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: Center(
                          child: ElevatedButton(
                              onPressed: () {
                                total_score = 0;
                                level = min_level;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        Game(key: UniqueKey()),
                                  ),
                                );
                              },
                              child: const Center(child: Text('Start Game')))),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(
                          15), //apply padding to all four sides
                      child: Center(
                          child: ElevatedButton(
                              onPressed: () {
                                insertScore = false;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          const LeaderboardPage()),
                                );
                              },
                              child:
                                  const Center(child: Text('LeaderBoards')))),
                    ),
                  ],
                ),
              ),
            ))));
  }
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  bool name_entered = false;
  final nameController = TextEditingController();
  late DateTime now;
  late List<int> temp_score_list;
  late Future<List<Map<String, dynamic>>> results;
  late Future<Map<String, int>> leaderboardData;

  void _saveText(String text) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_name', text);
  }

  void _onButtonPressed() {
    final tmp = nameController.text.trim();
    _saveText(tmp);

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
                title:
                    const Text('Leaderboard', style: TextStyle(fontSize: 30)),
                centerTitle: true,
                backgroundColor: Colors.blue,
              ),
              backgroundColor: const Color.fromARGB(255, 180, 231, 255),
              // backgroundColor: Colors.red,
              body: Center(
                child: Container(
                    color: Colors.white,
                    child: Stack(
                      children: <Widget>[
                        Center(
                            child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            if (insertScore)
                              Center(
                                  child: Column(
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
                                            children: [
                                              TableCell(
                                                child: Container(
                                                  color: results[index]
                                                                  ['name'] ==
                                                              name &&
                                                          results[index]
                                                                      ['date']
                                                                  .toString() ==
                                                              now
                                                                  .toIso8601String()
                                                      ? const Color.fromARGB(
                                                          255, 127, 217, 255)
                                                      : Colors.white,
                                                  child:
                                                      Text((rank++).toString()),
                                                ),
                                              ),
                                              TableCell(
                                                child: Container(
                                                  color: results[index]
                                                                  ['name'] ==
                                                              name &&
                                                          results[index]
                                                                      ['date']
                                                                  .toString() ==
                                                              now
                                                                  .toIso8601String()
                                                      ? const Color.fromARGB(
                                                          255, 127, 217, 255)
                                                      : Colors.white,
                                                  child: Text(
                                                      results[index]['name']),
                                                ),
                                              ),
                                              TableCell(
                                                child: Container(
                                                  color: results[index]
                                                                  ['name'] ==
                                                              name &&
                                                          results[index]
                                                                      ['date']
                                                                  .toString() ==
                                                              now
                                                                  .toIso8601String()
                                                      ? const Color.fromARGB(
                                                          255, 127, 217, 255)
                                                      : Colors.white,
                                                  child: Text(results[index]
                                                          ['score']
                                                      .toString()),
                                                ),
                                              ),
                                              TableCell(
                                                child: Container(
                                                  color: results[index]
                                                                  ['name'] ==
                                                              name &&
                                                          results[index]
                                                                      ['date']
                                                                  .toString() ==
                                                              now
                                                                  .toIso8601String()
                                                      ? const Color.fromARGB(
                                                          255, 127, 217, 255)
                                                      : Colors.white,
                                                  child: Text(formattedDate(
                                                      results[index]['date']
                                                          .toString())),
                                                ),
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
                        )),
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
                                              fontSize: 32,
                                              color: Colors.white),
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
                    )),
              ))),
    );
  }
}

//ctrl shift p > flutter:launch emulator > device
