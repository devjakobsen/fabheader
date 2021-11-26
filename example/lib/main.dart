import 'package:flutter/material.dart';
import 'package:fab_header/fab_header.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

GlobalKey floatingGlobalKey = GlobalKey();

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: FabHeader(
          navbarColor: Colors.deepOrange,
          floatingChild: _buildChild(),
          navbarImagePath: 'https://picsum.photos/200/300',
          child: Container(
            key: GlobalKey(debugLabel: 'cake'),
            height: 1000,
            width: 300,
            color: Colors.deepPurple,
          ),
        ),
      ),
    );
  }

  Widget _buildChild() {
    return Container(
      key: floatingGlobalKey,
      color: Colors.grey,
      width: 300,
      height: 300,
    );
  }
}
