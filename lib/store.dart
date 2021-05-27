import 'package:flutter/widgets.dart';

class Store<S, A, E>
    extends InheritedWidget {
  const Store({
    Key? key,
    required Widget child,
    required this.stateStream,
    required this.eventStream,
    required this.actionDispatcher,
    required this.getState,
  }) : super(key: key, child: child);

  final Stream<S> stateStream;
  final Stream<E> eventStream;
  final void Function(A) actionDispatcher;
  final S Function() getState;

  @override
  bool updateShouldNotify(covariant InheritedWidget oldWidget) => false;

  static Store<S, A, E>?
      of<S, A, E>(
          BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<Store<S, A, E>>();
  }
}