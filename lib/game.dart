import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

import 'package:mad_ass/main.dart';
// import 'package:mad_ass/home.dart';
// import 'package:mad_ass/game.dart';
import 'package:mad_ass/leaderboard.dart';

class Game extends StatefulWidget {
  const Game({super.key});

  @override
  _GameState createState() => _GameState();
}

class _GameState extends State<Game> {
  bool _isGreyedOut = true, _startTimerCountdown = false;

  //timer and score data
  int _countdownSeconds = 3;
  int active_index = 0;
  int grid_count = level + 1;
  int score = 0;
  late int _startCountdownSeconds;

  double _countdownTime = startingCountdownTime;

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
      } else if (_countdownSeconds != 4) {
        //play countdown-x.mp3
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
        _countdownTime = startingCountdownTime;

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
                            const TextStyle(fontSize: 32, color: Colors.black),
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
                                    //play bonk.mp3

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
                              // border: TableBorder.all(),
                              columnWidths: const <int, TableColumnWidth>{
                                0: FlexColumnWidth(1),
                                1: FlexColumnWidth(1),
                              },
                              children: <TableRow>[
                                TableRow(
                                  children: [
                                    // transparent cell in the left column
                                    TableCell(
                                      child:
                                          Container(color: Colors.transparent),
                                    ),
                                    // cell with content in the right column
                                    TableCell(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(),
                                          color: Colors.grey,
                                        ),
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Text(
                                            'Score',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                for (int i = 0; i < score_list.length; i++)
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                    ),
                                    children: <Widget>[
                                      TableCell(
                                          child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            'Level ${i + 1}',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )),
                                      TableCell(
                                          child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            '${score_list[i]}',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      )),
                                    ],
                                  ),
                                TableRow(
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                  ),
                                  children: <Widget>[
                                    TableCell(
                                        child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(),
                                      ),
                                      child: const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          'Total',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    )),
                                    TableCell(
                                        child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(),
                                      ),
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
                                    )),
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
