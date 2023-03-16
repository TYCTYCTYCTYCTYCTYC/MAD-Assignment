import 'package:flutter/material.dart';
import 'dart:math';

import 'package:mad_ass/main.dart';
// import 'package:mad_ass/home.dart';
import 'package:mad_ass/game.dart';
import 'package:mad_ass/leaderboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
