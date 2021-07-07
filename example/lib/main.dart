import 'package:flutter/material.dart';
import 'package:whelm/whelm.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  Widget build(BuildContext context) {
    return StoreWidget<int, int, String>(
      initaialState: 0,
      reducer: (state, action) {
        return state + action;
      },
      middleware: (state, action, actionDispatcher, eventDispatcher) {
        eventDispatcher('action: $action');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                'You have pushed the button this many times:',
              ),
              StoreConnection<int, int, String, int>(
                builder: (context, state, dispatcher) {
                  return Text(
                    '$state',
                    style: Theme.of(context).textTheme.headline4,
                  );
                },
                connect: (state) => state,
                eventListener: (context, event) async =>
                    ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$event'),
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: StoreConnection<int, int, String, int>(
          builder: (context, state, dispatcher) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FloatingActionButton(
                  onPressed: () => dispatcher(1),
                  tooltip: 'Increment',
                  child: Icon(Icons.add),
                ),
                SizedBox(
                  width: 20,
                ),
                FloatingActionButton(
                  onPressed: () => dispatcher(-1),
                  tooltip: 'Decrement',
                  child: Icon(Icons.remove),
                ),
              ],
            );
          },
          connect: (state) => state,
        ),
      ),
    );
  }
}
