
import 'package:bluetooth/screens/home_screen.dart';
import 'package:bluetooth/screens/map_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  const App({super.key});


  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      home: HomeScreen(),
     // home: BaseMapPage(),


    );
  }




}