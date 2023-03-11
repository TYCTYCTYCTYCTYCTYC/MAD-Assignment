import 'dart:math';

import 'package:flutter/material.dart';

void main() {
  runApp(const HomeSHARE());
}

class HomeSHARE extends StatefulWidget {
  const HomeSHARE({super.key});

  @override
  State<HomeSHARE> createState() => _HomeSHAREState();
}

class _HomeSHAREState extends State<HomeSHARE> {
  int active_index = 0;
  int grid_count = 5;
  int cur_index = 0;
  int score = 0;
  int round = 1;
  double active_border = 5.0;
  Random random = Random();

  late int rng = random.nextInt(grid_count * grid_count);
  late List<double> borders =
      List.generate(grid_count * grid_count, (index) => 0);

  @override
  void initState() {
    super.initState();
    // final int rng = Random().nextInt(grid_count * grid_count);
    borders[rng] = active_border;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: "test",
        home: Scaffold(
          appBar: AppBar(
            // leading: const Icon(Icons.menu, size: 50),
            title: const Text('game', style: TextStyle(fontSize: 30)),
            // actions: const [Icon(Icons.account_circle, size: 50)],
            centerTitle: true,
            backgroundColor: Colors.blue,
          ),
          body: SingleChildScrollView(
            reverse: true,
            child: Column(
              children: <Widget>[
                // Image.asset('assets/images/tio.png'),
                Text(
                  'score: ' + score.toString(),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'rng: ' + rng.toString(),
                ),
                Text(
                  'round: ' + round.toString(),
                ),
                Builder(builder: (BuildContext context) {
                  return SizedBox(
                    height: max(MediaQuery.of(context).size.height,
                        MediaQuery.of(context).size.width),
                    child: GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: grid_count,
                      children: List.generate(grid_count * grid_count, (index) {
                        return Material(
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                if (index == rng) {
                                  score++;
                                } else {
                                  score = max(score - 1, 0);
                                }
                                borders[rng] = 0;
                                int tmp = Random()
                                    .nextInt(grid_count * grid_count - 1);
                                if (tmp >= rng)
                                  rng = tmp + 1;
                                else
                                  rng = tmp;
                                borders[rng] = active_border;
                                round++;
                              });
                            },
                            child: ClipRRect(
                                //borderRadius: BorderRadius.circular(20.0),
                                child: Container(
                              decoration: BoxDecoration(
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/tio.png'),
                                  fit: BoxFit.cover,
                                ),
                                border: Border.all(
                                  color: Colors.black,
                                  width: borders[index],
                                ),
                              ),
                            )),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Home'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.brush), label: 'Business'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_month), label: 'School'),
              BottomNavigationBarItem(
                  icon: Icon(Icons.person), label: 'Settings'),
            ],
            currentIndex: active_index,
            onTap: (int index) {
              setState(() {
                active_index = index;
              });
            },
          ),
        ));
  }
}

//ctrl shift p > flutter:launch emulator > device