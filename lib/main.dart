import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

int total_score = 0;

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
//   WidgetsFlutterBinding.ensureInitialized();
// // Open the database and store the reference.
//   final database = openDatabase(
//     // Set the path to the database. Note: Using the `join` function from the
//     // `path` package is best practice to ensure the path is correctly
//     // constructed for each platform.
//     p.join(await getDatabasesPath(), 'Leaderboard.db'),
//   );
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
  int grid_count = 3;
  // int cur_index = 0;
  // int score = 0;
  double game_timer = 5;
  double active_border = 5.0;
  final double appBarHeight = AppBar().preferredSize.height;
  //final double bottomNavigationBarHeight = kBottomNavigationBarHeight;

  int score = 0;

  late final Size size = MediaQuery.of(context).size;
  late final double height = size.height - appBarHeight;
  late final double width = size.width;

  List<String> images = [
    "assets/images/no_mishy.png",
    "assets/images/mishy_pop.png",
    "assets/images/mishy_bop.png",
    "assets/images/mishy_sadge.png"
  ];

  late Timer timer;
  double _countdownTime = 5.0;

  late TextSpan span = TextSpan(
      text: 'time: $_countdownTime',
      style: TextStyle(fontSize: 16, color: Colors.black));
  late TextPainter tp = TextPainter(
      text: span, textAlign: TextAlign.left, textDirection: TextDirection.ltr);
  late double textHeight;

  late List<double> borders =
      List.generate(grid_count * grid_count, (index) => 0);
  late List<int> image_status =
      List.generate(grid_count * grid_count, (index) => 0);
  late List<int> remaining =
      List.generate(grid_count * grid_count, (index) => index);

  bool _isGreyedOut = true, isclick = false;
  int _countdownSeconds = 3;
  late int _startCountdownSeconds;

// final formatter = DurationFormatter(DurationFormatterBuilder()
//       ..alwaysUseSingularUnits = true
//       ..zeroPadDays = false
//       ..fractionalDigits = 2);

  String format(int _countdownSeconds) {
    if (this._countdownSeconds == _startCountdownSeconds) {
      return "Ready ...";
    } else if (this._countdownSeconds == 1) {
      return "Start!";
    } else {
      return (_countdownSeconds - 1).toString();
    }
  }

  void _startTimer() {
    timer = Timer.periodic(const Duration(milliseconds: 10), (timer) {
      setState(() {
        if (_countdownTime <= 0) {
          endGame();
        } else {
          _countdownTime -= 0.01;
        }
      });
    });
  }

  void _startCountdown() {
    _countdownSeconds += 2;
    setState(() {
      _isGreyedOut = true;
      isclick = true;
    });

    Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _countdownSeconds--;
      });

      if (_countdownSeconds == 0) {
        timer.cancel();
        setState(() {
          _isGreyedOut = false;
          // _countdownSeconds = 10;
          image_status[remaining[0]] = 1;
          _startTimer();
        });
      }
    });
  }

  void endGame() {
    //stop countdown
    timer.cancel();
    total_score = score;
    score = 0;

    //navigate to leaderboard
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LeaderboardPage()),
    );
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

  // @override
  // void dispose() {
  //   _timer.cancel();
  //   super.dispose();
  // }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Mishy Panic!",
        home: Scaffold(
          appBar: AppBar(
            title: const Text('Mishy Panic!', style: TextStyle(fontSize: 30)),
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
                      // RichText(text: span),
                      Text(
                        _countdownTime.toStringAsFixed(2),
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
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      if (index == remaining[0]) {
                                        setState(() {
                                          score++;
                                          image_status[index] = 2;
                                          remaining.removeAt(0);
                                          if (!remaining.isEmpty == true) {
                                            image_status[remaining[0]] = 1;
                                          } else {
                                            //get score and publish to leaderboard if within top 25
                                            endGame();
                                          }
                                        });

                                        Future.delayed(
                                                Duration(milliseconds: 150))
                                            .then((value) {
                                          setState(() {
                                            image_status[index] = 3;
                                          });
                                        });
                                      }
                                    });
                                  },
                                  child: ClipRRect(
                                      child: Container(
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(
                                            images[image_status[index]]),
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
                if (_isGreyedOut)
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
              ]),
        ));
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'test`',
        home: Scaffold(
            // appBar: AppBar(
            //   title: const Text('Mishy Panic!', style: TextStyle(fontSize: 30)),
            //   centerTitle: true,
            //   backgroundColor: Colors.blue,
            // ),
            body: Stack(
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Center(
                    child:
                        Text('Mishy Panic!', style: TextStyle(fontSize: 60))),
                Padding(
                  padding: EdgeInsets.all(15), //apply padding to all four sides
                  child: Center(
                      child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const HomeSHARE()),
                            );
                          },
                          child: const Center(child: Text('Start Game')))),
                ),
                Padding(
                  padding: EdgeInsets.all(15), //apply padding to all four sides
                  child: Center(
                      child: ElevatedButton(
                          onPressed: () {
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
            Positioned(
              bottom: 0,
              right: 0,
              child: Image.asset(
                'assets/images/tio.png',
                width: max(MediaQuery.of(context).size.width / 3,
                    MediaQuery.of(context).size.height / 3),
                height: max(MediaQuery.of(context).size.width / 3,
                    MediaQuery.of(context).size.height / 3),
              ),
            )
          ],
        )));
  }
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  //insert
  //delete those that are not first 25 in sorted order by score desc, date desc
  //read first 25 in same sorted order

  Future<List<Map<String, dynamic>>> results = Leaderboard.initialQuery();

  late String _name;
  bool submitted = false;

  void _onSubmitted(String value) {
    setState(() {
      _name = value.trim();
      results = Leaderboard.insertAndQuery(_name, DateTime.now(), total_score);
    });
  }

  //display those 25 records, if not 25 display those records only

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
            Center(
              child: Container(
                width: 300,
                height: 50,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  textAlignVertical: TextAlignVertical.center,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Enter Name',
                  ),
                  onSubmitted: _onSubmitted,
                ),
              ),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: results,
              builder: (BuildContext context, AsyncSnapshot snapshot) {
                // Check if the query results have been loaded
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                // Extract the query results from the snapshot
                final results = snapshot.data;

                // Build the table rows from the query results
                final tableRows = List<TableRow>.generate(
                  results.length,
                  (int index) => TableRow(
                    children: <Widget>[
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
                return Table(
                  columnWidths: {
                    0: FlexColumnWidth(2.0),
                    1: FlexColumnWidth(1.0),
                    2: FlexColumnWidth(1.0),
                  },
                  border: TableBorder.all(),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[100],
                      ),
                      children: <Widget>[
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
                );
              },
            ),
            Padding(
              padding: EdgeInsets.all(15), //apply padding to all four sides
              child: Center(
                  child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const MainPage()),
                        );
                      },
                      child:
                          const Center(child: Text('Go back to Main Page')))),
            ),
          ],
        ))));
  }
}

//ctrl shift p > flutter:launch emulator > device
