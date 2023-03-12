import 'dart:async';
import 'dart:math';
// import 'package:intl/intl.dart';
import 'package:flutter/material.dart';

void main() {
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
  int grid_count = 2;
  // int cur_index = 0;
  int score = 0;
  double game_timer = 5;
  double active_border = 5.0;
  final double appBarHeight = AppBar().preferredSize.height;
  //final double bottomNavigationBarHeight = kBottomNavigationBarHeight;

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
  //set score to leaderboard if top 25

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
            const Center(child: Text('<insert leaderboard>')),
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
