import 'dart:math';

import 'package:flutter/material.dart';
import 'package:overflow_page_view/overflow_page_view.dart';
import 'package:random_color/random_color.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OverflowPageView Demo',
      home: MyHomePage(title: 'Overflow Page View'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class ExampleItem extends StatelessWidget {
  final Color color;
  final double height;
  final Widget child;
  ExampleItem({
    Key key,
    @required this.color,
    @required this.height,
    @required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(height: height, color: color, child: child);
  }
}

class _MyHomePageState extends State<MyHomePage> {
  Random rng = Random();
  RandomColor rcg = RandomColor();
  List<ExampleItem> items;

  @override
  void initState() {
    super.initState();
    items = List.generate(
      64,
      (index) => ExampleItem(
        color: rcg.randomColor(),
        height: 32.0 + rng.nextInt(64),
        child: Center(child: Text('$index')),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: OverflowPageView(
        itemBuilder: (context, index) {
          if (index >= items.length) {
            return null;
          }
          print('Building item $index');
          return items[index];
        },
        onPageChanged: (first, last) =>
            print('Showing page with widgets $first through $last'),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
