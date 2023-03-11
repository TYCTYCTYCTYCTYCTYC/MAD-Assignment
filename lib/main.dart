import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(home: MainPage()));
}

class HomeSHARE extends StatefulWidget {
  const HomeSHARE({super.key});

  @override
  State<HomeSHARE> createState() => _HomeSHAREState();
}

class _HomeSHAREState extends State<HomeSHARE> {
  int active_index = 0;
  int grid_count = 3;
  int cur_index = 0;
  int score = 0;
  int round = 1;
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

  late List<double> borders =
      List.generate(grid_count * grid_count, (index) => 0);
  late List<int> image_status =
      List.generate(grid_count * grid_count, (index) => 0);
  late List<int> remaining =
      List.generate(grid_count * grid_count, (index) => index);

  bool _isGreyedOut = true;
  int _countdownSeconds = 10;

  void _startCountdown() {
    setState(() {
      _isGreyedOut = true;
    });

    Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _countdownSeconds--;
      });

      if (_countdownSeconds == 0) {
        timer.cancel();
        setState(() {
          _isGreyedOut = false;
          _countdownSeconds = 10;
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();
    remaining.shuffle();
    image_status[remaining[0]] = 1;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "test",
        home: Scaffold(
          appBar: AppBar(
            // leading: const Icon(Icons.menu, size: 50),
            title: const Text('height', style: TextStyle(fontSize: 30)),
            // actions: const [Icon(Icons.account_circle, size: 50)],
            centerTitle: true,
            backgroundColor: Colors.blue,
          ),
          body: SingleChildScrollView(
              reverse: true,
              child: Stack(children: <Widget>[
                // if (_isGreyedOut)
                //   Builder(builder: (BuildContext context) {
                //     return SingleChildScrollView(
                //         primary: false,
                //         physics: NeverScrollableScrollPhysics(),
                //         child: SizedBox(
                //             height: MediaQuery.of(context).size.height,
                //             width: MediaQuery.of(context).size.width,
                //             child: ListView.builder(
                //               controller:
                //                   ScrollController(initialScrollOffset: 0),
                //               itemBuilder: (context, index) {
                //                 // your list items here
                //                 ModalBarrier(
                //                   dismissible: false,
                //                   color: Colors.grey.withOpacity(0.5),
                //                 );
                //               },
                //             )));
                //   }),
                // if (_isGreyedOut)
                //   Center(
                //     child: Column(
                //       mainAxisSize: MainAxisSize.min,
                //       children: [
                //         Text(
                //           '$_countdownSeconds',
                //           style: TextStyle(fontSize: 64),
                //         ),
                //         ElevatedButton(
                //           onPressed: _startCountdown,
                //           child: Text('Start Countdown'),
                //         ),
                //       ],
                //     ),
                //   ),
                Flexible(
                    flex: 100,
                    fit: FlexFit.tight,
                    child: Container(
                      child: Builder(builder: (BuildContext context) {
                        return Center(
                            child: SizedBox(
                          height: min(
                              MediaQuery.of(context).size.height -
                                  AppBar().preferredSize.height,
                              MediaQuery.of(context).size.width),
                          width: min(
                              MediaQuery.of(context).size.height -
                                  AppBar().preferredSize.height,
                              MediaQuery.of(context).size.width),
                          child: GridView.count(
                            physics: const NeverScrollableScrollPhysics(),
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
                                          round++;
                                          remaining.removeAt(0);
                                          if (!remaining.isEmpty == true) {
                                            image_status[remaining[0]] = 1;
                                          } else
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      const LeaderboardPage()),
                                            );
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
                      }),
                    )
                    // Padding(
                    //     padding: EdgeInsets.all(15),
                    //     child: ElevatedButton(
                    //         onPressed: () {
                    //           Navigator.pop(context);
                    //         },
                    //         child: const Text('Exit Game')))
                    )
              ])),
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
        title: 'test`',
        home: Scaffold(
            appBar: AppBar(
              title: const Text('test2', style: TextStyle(fontSize: 30)),
              centerTitle: true,
              backgroundColor: Colors.blue,
            ),
            body: Column(
              children: <Widget>[
                const Center(child: Text('GAME!!')),
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
            )));
  }
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'test`',
        home: Scaffold(
            appBar: AppBar(
              title: const Text('test2', style: TextStyle(fontSize: 30)),
              centerTitle: true,
              backgroundColor: Colors.blue,
            ),
            body: Column(
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
                          child: const Center(child: Text('Main Page')))),
                ),
              ],
            )));
  }
}


//ctrl shift p > flutter:launch emulator > device