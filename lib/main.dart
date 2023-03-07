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

  @override
  Widget build(BuildContext context) {
    //Size size = MediaQuery.of(context).size;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
            leading: const Icon(Icons.menu, size: 50),
            title: const Text('HomeSHARE', style: TextStyle(fontSize: 30)),
            actions: const [Icon(Icons.account_circle, size: 50)],
            centerTitle: true,
            backgroundColor: Colors.blue),
        // body: Center(child: Image.asset('assets/images/tio.png')),
        body: Stack(
          children: <Widget>[
            // Center(child: Image.asset('assets/images/tio.png')),
            Image.asset('assets/images/tio.png'),
            GridView.count(
              crossAxisCount: 3,
              children: List.generate(9, (index) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black,
                      width: 2.0,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'Box ${index + 1}',
                      style: TextStyle(fontSize: 20.0),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.brush), label: 'Business'),
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
      ),
    );
  }
}

//ctrl shift p > flutter:launch emulator > device