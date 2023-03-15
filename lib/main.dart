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

int total_score = 0;
String? name = null;
bool played = false;
const int min_level = 1;
const int max_level = 3;
int level = min_level;
bool insertScore = false;
List<int> score_list = [];

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
          name TEXT PRIMARY KEY,
          date DATE NOT NULL, 
          score INTEGER NOT NULL
        )
          ''');
  }

  static Future<List<Map<String, dynamic>>> insertAndQuery(
      String name, DateTime date, int score) async {
    // Check if the name already exists in the database
    final List<Map<String, dynamic>> existingRecords = await _database!.query(
      table,
      where: 'name = ?',
      whereArgs: [name],
    );

    if (existingRecords.isNotEmpty) {
      final existingScore = existingRecords.first['score'] as int;
      final existingDate =
          DateTime.parse(existingRecords.first['date'] as String);

      // Update the record if the score is higher than the existing score
      if (score > existingScore) {
        await _database!.update(
          table,
          {
            'date': date.toIso8601String().substring(0, 10),
            'score': score,
          },
          where: 'name = ?',
          whereArgs: [name],
        );
      }
      // Update the date if the scores are the same but the date is later
      else if (score == existingScore && date.isAfter(existingDate)) {
        await _database!.update(
          table,
          {
            'date': date.toIso8601String().substring(0, 10),
          },
          where: 'name = ?',
          whereArgs: [name],
        );
      }
    } else {
      // Insert the new record if the name doesn't exist in the database
      await _database!.insert(table, {
        "name": name,
        "date": date.toIso8601String().substring(0, 10),
        "score": score,
      });

      // Remove excess records if necessary
      final List<Map<String, dynamic>> results = await _database!.query(
        table,
        orderBy: 'Score DESC, Date DESC',
      );
      if (results.length > 25) {
        final idsToDelete = results
            .sublist(25)
            .map((result) => result["name"] as String)
            .toList();
        await _database!.delete(
          table,
          where: 'name IN (${idsToDelete.map((_) => '?').join(', ')})',
          whereArgs: idsToDelete,
        );
      }
    }

    // Return the updated results
    final List<Map<String, dynamic>> updatedResults = await _database!.query(
      table,
      orderBy: 'Score DESC, Date DESC',
    );
    total_score = 0;
    return updatedResults;
  }

  static Future<List<Map<String, dynamic>>> initialQuery() async {
    final List<Map<String, dynamic>> updatedResults = await _database!.query(
      table,
      orderBy: 'Score DESC, Date DESC',
      limit: 25,
    );
    return updatedResults;
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
  double _countdownTime = 5.0;

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

  // final nameFocusNode = FocusNode();
  bool pressed = false;
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
      name = tmp;
      pressed = true;
    }
  }

  void _loadSavedText() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String savedText = prefs.getString('last_name') ?? '';
    setState(() {
      nameController.text = savedText;
    });
  }

  void _saveText(String text) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_name', text);
  }

  @override
  void initState() {
    super.initState();
    _loadSavedText();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'test`',
        home: Scaffold(
            // resizeToAvoidBottomInset: false,
            body: Center(
          child: SingleChildScrollView(
            // physics: const BouncingScrollPhysics(),
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
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text("Player: "),
                      SizedBox(
                        width: MediaQuery.of(context).size.width /
                            3, //adjust width
                        child: TextField(
                          textAlign: TextAlign.center,
                          controller: nameController,
                          // focusNode: nameFocusNode,
                          decoration: const InputDecoration(
                            hintText: 'Enter your name',
                          ),
                          onSubmitted: (_) => _onButtonPressed(),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Center(
                      child: ElevatedButton(
                          onPressed: () {
                            _onButtonPressed();
                            if (pressed) {
                              level = min_level;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      HomeSHARE(key: UniqueKey()),
                                ),
                              );
                            }
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
  @override
  void initState() {
    super.initState();
    temp_score_list = List.from(score_list);
    score_list.clear();

    if (insertScore == true) {
      results = Leaderboard.insertAndQuery(name!, DateTime.now(), total_score);
    } else {
      results = Leaderboard.initialQuery();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
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
              body: Center(
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
                      style: const TextStyle(fontSize: 50, color: Colors.blue),
                    ),
                  ],
                )),
              // if (insertScore)
              //   const Text(
              //     "Evaluation",
              //     style: TextStyle(fontSize: 64, color: Colors.black),
              //   ),
              // if (insertScore)
              //   Padding(
              //     padding: const EdgeInsets.fromLTRB(15, 15, 15, 60),
              //     child: SizedBox(
              //       width: MediaQuery.of(context).size.width * 0.8,
              //       child: Table(
              //         border: TableBorder.all(),
              //         columnWidths: const <int, TableColumnWidth>{
              //           0: FlexColumnWidth(1),
              //           1: FlexColumnWidth(1),
              //         },
              //         children: <TableRow>[
              //           for (int i = 0; i < temp_score_list.length; i++)
              //             TableRow(
              //               decoration: BoxDecoration(
              //                 color: Colors.grey.shade300,
              //               ),
              //               children: <Widget>[
              //                 TableCell(
              //                   child: Padding(
              //                     padding: const EdgeInsets.all(8.0),
              //                     child: Text(
              //                       'Level ${i + 1}',
              //                       textAlign: TextAlign.center,
              //                     ),
              //                   ),
              //                 ),
              //                 TableCell(
              //                   child: Padding(
              //                     padding: const EdgeInsets.all(8.0),
              //                     child: Text(
              //                       '${temp_score_list[i]}',
              //                       textAlign: TextAlign.center,
              //                     ),
              //                   ),
              //                 ),
              //               ],
              //             ),
              //           TableRow(
              //             decoration: BoxDecoration(
              //               color: Colors.blue,
              //             ),
              //             children: <Widget>[
              //               TableCell(
              //                 child: Padding(
              //                   padding: const EdgeInsets.all(8.0),
              //                   child: Text(
              //                     'Total Score',
              //                     textAlign: TextAlign.center,
              //                     style: TextStyle(
              //                       fontWeight: FontWeight.bold,
              //                     ),
              //                   ),
              //                 ),
              //               ),
              //               TableCell(
              //                 child: Padding(
              //                   padding: const EdgeInsets.all(8.0),
              //                   child: Text(
              //                     '${temp_score_list.fold(0, (prev, curr) => prev + curr)}',
              //                     textAlign: TextAlign.center,
              //                     style: TextStyle(
              //                       fontWeight: FontWeight.bold,
              //                     ),
              //                   ),
              //                 ),
              //               ),
              //             ],
              //           ),
              //         ],
              //       ),
              //     ),
              //   ),
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: results,
                  builder: (BuildContext context, AsyncSnapshot snapshot) {
                    // Check if the query results have been loaded
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
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
                      results.length,
                      (int index) => TableRow(
                        children: <Widget>[
                          TableCell(
                            child: Text((rank++).toString()),
                          ),
                          TableCell(
                            child: Text(results[index]['name']),
                          ),
                          TableCell(
                            child: Text(results[index]['date'].toString()),
                          ),
                          TableCell(
                            child: Text(results[index]['score'].toString()),
                          ),
                        ],
                      ),
                    );

                    // Build the table widget with the rows
                    return Column(children: <Widget>[
                      const Text(
                        "Leaderboard",
                        style: TextStyle(fontSize: 64, color: Colors.black),
                      ),
                      Table(
                        columnWidths: const {
                          0: FlexColumnWidth(1.0),
                          1: FlexColumnWidth(1.0),
                          2: FlexColumnWidth(1.0),
                          3: FlexColumnWidth(1.0),
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
                                child: Text('Date'),
                              ),
                              TableCell(
                                child: Text('Score'),
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
                padding:
                    const EdgeInsets.all(15), //apply padding to all four sides
                child: Center(
                    child: ElevatedButton(
                        onPressed: () {
                          // Navigator.push(
                          //   context,
                          //   MaterialPageRoute(
                          //       builder: (context) => const MainPage()),
                          // );
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        },
                        child: const Center(child: Text('Main menu')))),
              ),
            ],
          )))),
    );
  }
}

//ctrl shift p > flutter:launch emulator > device
