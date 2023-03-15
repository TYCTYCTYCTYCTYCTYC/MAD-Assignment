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

int total_score = 0;
String? name = null;
bool played = false;
const int min_level = 1;
const int max_level = 3;
int level = min_level;
bool insertScore = false;
List<int> score_list = [];
const int top = 3;

class Leaderboard {
  static final _databaseName = 'leaderboard.db';
  static final _databaseVersion = 1;
  static Database? _database;

  static final table = 'leaderboard';
  // static final String name;
  // static final DateTime date;
  // static final int score;

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
    //come back to date later
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

    // total_score = 0;
    //back of press main menu then change to 0
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
    Map<String, int> output = new Map<String, int>();
    final List<Map<String, dynamic>> updatedResults = await _database!.query(
      table,
      orderBy: 'Score DESC, Date DESC',
      limit: top,
    );
    //minScore reading null
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

class HomeSHARE extends StatefulWidget {
  const HomeSHARE({super.key});

  @override
  State<HomeSHARE> createState() => _HomeSHAREState();
}

class _HomeSHAREState extends State<HomeSHARE> {
  int active_index = 0;
  int grid_count = level + 1;
  // int cur_index = 0;
  // int score = 0;
  double game_timer = 5;
  final double appBarHeight = AppBar().preferredSize.height;
  //final double bottomNavigationBarHeight = kBottomNavigationBarHeight;

  int score = 0;

  late final Size size = MediaQuery.of(context).size;
  late final double height = size.height - appBarHeight;
  late final double width = size.width;

  // List<String> images = [
  //   "assets/images/no_mishy.png",
  //   "assets/images/mishy_pop.png",
  //   "assets/images/mishy_bop.png",
  //   "assets/images/mishy_sadge.png"
  // ];

  List<ImageProvider> images = [
    AssetImage('assets/images/no_mishy.png'),
    AssetImage('assets/images/mishy_pop.png'),
    AssetImage('assets/images/mishy_bop.png'),
    AssetImage('assets/images/mishy_sadge.png')
  ];

  late Timer timer;
  late Timer initialTimer;
  double _countdownTime = 3.0;

  late TextSpan span = TextSpan(
      text: 'remaining time\n${_countdownTime.toStringAsFixed(1)}',
      style: const TextStyle(fontSize: 16, color: Colors.black));
  late TextPainter tp = TextPainter(
      text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
  late double textHeight;

  late List<double> borders =
      List.generate(grid_count * grid_count, (index) => 0);
  late List<int> image_status =
      List.generate(grid_count * grid_count, (index) => 0);
  late List<int> remaining =
      List.generate(grid_count * grid_count, (index) => index);

  bool _isGreyedOut = true,
      isclick = false,
      _startTimerCountdown = false; //dont really use isclick
  int _countdownSeconds = 3;
  late int _startCountdownSeconds;

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
      isclick = true;
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
    //hide timer countdown with another boolean logic
    timer.cancel();
    total_score += score;
    score_list.add(score);
    score = 0;

    _isGreyedOut = true;
    _startTimerCountdown = false;

    //show score screen if grey and !startTimer

    //show new screen
    //how to run
  }

  void endGame() {
    //stop countdown
    timer.cancel();

    if (level < max_level) {
      setState(() {
        level++;

        //reinitialize
        grid_count = level + 1;
        borders = List.generate(grid_count * grid_count, (index) => 0);
        image_status = List.generate(grid_count * grid_count, (index) => 0);
        remaining = List.generate(grid_count * grid_count, (index) => index);
        _isGreyedOut = true;
        isclick = false;
        _countdownSeconds = 3;
        _countdownTime = 5.0;

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
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LeaderboardPage()),
      );
    }
  }

  // void loadImages() async {
  //   for (int i = 0; i < images.length; i++) {
  //     await precacheImage(images[i], context);
  //   }
  // }

  @override
  void initState() {
    super.initState();
    remaining.shuffle();
    tp.layout();
    textHeight = tp.size.height;
    _startCountdownSeconds = _countdownSeconds + 2;
    _startCountdown();

    // loadImages();
  }

  // @override
  // void dispose() {
  //   _timer.cancel();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: "Mishy Panic!",
            home: Scaffold(
              appBar: AppBar(
                title:
                    Text('LEVEL $level', style: const TextStyle(fontSize: 30)),
                actions: const [Icon(Icons.pause, size: 50)],
                centerTitle: true,
                backgroundColor: Colors.blue,
              ),
              body: Stack(
                  //alignment: Alignment.center,
                  children: <Widget>[
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Text(
                            "remaining time\n${_countdownTime.toStringAsFixed(1)}s",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.black),
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
                                children: List.generate(grid_count * grid_count,
                                    (index) {
                                  return Material(
                                    child: GestureDetector(
                                      onTapDown: (TapDownDetails details) {
                                        setState(() {
                                          if (index == remaining[0]) {
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
                                          Future.delayed(const Duration(
                                                  milliseconds: 150))
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
                          // Padding(
                          //     padding: EdgeInsets.all(15),
                          //     child: ElevatedButton(
                          //         onPressed: () {
                          //           Navigator.pop(context);
                          //         },
                          //         child: const Text('Exit Game')))
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
                              style:
                                  TextStyle(fontSize: 64, color: Colors.white),
                            ),
                            Padding(
                              padding: EdgeInsets.all(15),
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
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                'Level ${i + 1}',
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                          TableCell(
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: Text(
                                                '${score_list[i]}',
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    TableRow(
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                      ),
                                      children: <Widget>[
                                        TableCell(
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
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
                                              style: TextStyle(
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
                                    padding: EdgeInsets.all(15),
                                    child: ElevatedButton(
                                        onPressed: () {
                                          endGame();
                                        },
                                        child: const Center(
                                            child: Text('Continue'))),
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
        title: 'test`',
        home: Scaffold(
            body: Center(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Center(
                  child: Image.asset(
                    'assets/images/title.png',
                    width: max(MediaQuery.of(context).size.width / 3,
                        MediaQuery.of(context).size.height / 3),
                    height: max(MediaQuery.of(context).size.width / 3,
                        MediaQuery.of(context).size.height / 3),
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
                                    HomeSHARE(key: UniqueKey()),
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
                          child: const Center(child: Text('LeaderBoards')))),
                ),
              ],
            ),
          ),
        )));
  }
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  late Future<List<Map<String, dynamic>>> results;
  late List<int> temp_score_list;
  bool askName = false;
  late Future<Map<String, int>> leaderboardData;
  final nameController = TextEditingController();
  bool name_entered = false;

  void _saveText(String text) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_name', text);
  }

  void _onButtonPressed() {
    final tmp = nameController.text.trim();
    _saveText(tmp);

    if (tmp.isEmpty) {
      // Vibrate the phone
      Vibration.vibrate(duration: 500);

      // Show a message
      Fluttertoast.showToast(
        msg: 'Please input name',
        gravity: ToastGravity.TOP,
      );

      // Highlight the TextField
      // nameFocusNode.requestFocus();
    } else {
      // pressed = true;
      name_entered = true;
      name = tmp;

      setState(() {
        results =
            Leaderboard.insertAndQuery(name!, DateTime.now(), total_score);
        ;
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
        Navigator.of(context).popUntil((route) => route.isFirst);
        return true;
      },
      child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'test`',
          home: Scaffold(
              // appBar: AppBar(
              //   title: const Text('test2', style: TextStyle(fontSize: 30)),
              //   centerTitle: true,
              //   backgroundColor: Colors.blue,
              // ),
              body: Stack(
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
                          "SCORE",
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.black,
                              decoration: TextDecoration.underline),
                        ),
                        Text(
                          total_score.toString(),
                          style:
                              const TextStyle(fontSize: 50, color: Colors.blue),
                        ),
                      ],
                    )),
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: FutureBuilder<List<Map<String, dynamic>>>(
                      future: results,
                      builder: (BuildContext context, AsyncSnapshot snapshot) {
                        // Check if the query results have been loaded
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        // Extract the query results from the snapshot
                        final results = snapshot.data;

                        if (results.length == 0) {
                          return const Center(
                            child: Text("No leaderboard"),
                          );
                        }

                        int rank = 1;

                        // Build the table rows from the query results
                        final tableRows = List<TableRow>.generate(
                          min(results.length, top),
                          (int index) => TableRow(
                            children: <Widget>[
                              TableCell(
                                child: Text((rank++).toString()),
                              ),
                              TableCell(
                                child: Text(results[index]['name']),
                              ),
                              TableCell(
                                child: Text(results[index]['score'].toString()),
                              ),
                              TableCell(
                                child: Text(formattedDate(
                                    results[index]['date'].toString())),
                              ),
                            ],
                          ),
                        );

                        // Build the table widget with the rows
                        return Column(children: <Widget>[
                          const Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              "Leaderboard",
                              style:
                                  TextStyle(fontSize: 50, color: Colors.black),
                            ),
                          ),
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
                                  color: Color.fromARGB(255, 127, 217, 255),
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
                    padding: const EdgeInsets.all(
                        15), //apply padding to all four sides
                    child: Center(
                        child: ElevatedButton(
                            onPressed: () {
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //       builder: (context) => const MainPage()),
                              // );
                              total_score = 0;
                              Navigator.of(context)
                                  .popUntil((route) => route.isFirst);
                            },
                            child: const Center(child: Text('Main menu')))),
                  ),
                ],
              )),
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
                            padding: EdgeInsets.all(15),
                            child: Text(
                              style:
                                  TextStyle(fontSize: 32, color: Colors.white),
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
          ))),
    );
  }
}

//ctrl shift p > flutter:launch emulator > device
