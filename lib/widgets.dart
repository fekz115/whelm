import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:whelm/store.dart';
import 'package:whelm/typedefs.dart';

class StoreWidget<S, A, E> extends StatefulWidget {
  StoreWidget({
    Key? key,
    required this.initaialState,
    required this.child,
    required this.reducers,
    this.middlewares,
  }) : super(key: key);

  final S initaialState;
  final Widget child;

  final List<Reducer<S, A>> reducers;
  final List<Middleware<S, A, E>>? middlewares;

  @override
  _StoreWidgetState createState() => _StoreWidgetState<S, A, E>();
}

class _StoreWidgetState<S, A, E> extends State<StoreWidget<S, A, E>> {
  late S state;
  late StreamController<S> stateStreamController;
  late StreamController<A> actionsStreamController;
  late StreamSubscription<S> stateStreamSubscription;
  late StreamSubscription<A> actionsStreamSubscription;
  late StreamController<E> eventStreamController;

  @override
  void initState() {
    super.initState();
    state = widget.initaialState;
    eventStreamController = StreamController.broadcast();
    actionsStreamController = StreamController();
    stateStreamController = StreamController.broadcast();
    actionsStreamSubscription =
        actionsStreamController.stream.listen((action) async {
      _processReducers(action, state);
      await _processMiddleware(action, state);
    });
    stateStreamSubscription = stateStreamController.stream
        .listen((stateFromStream) => state = stateFromStream);
    stateStreamController.add(widget.initaialState);
  }

  @override
  Widget build(BuildContext context) {
    return Store<S, A, E>(
      actionDispatcher: (action) => actionsStreamController.add(action),
      stateStream: stateStreamController.stream,
      eventStream: eventStreamController.stream,
      getState: () => state,
      child: widget.child,
    );
  }

  @override
  void dispose() {
    super.dispose();
    stateStreamSubscription.cancel();
    actionsStreamSubscription.cancel();
    actionsStreamController.close();
    stateStreamController.close();
    eventStreamController.close();
  }

  Future<void> _processMiddleware(A action, S state) async {
    widget.middlewares
        ?.where(
            (middleware) => typeOfMiddlewareAction<S, A, E>(middleware, action))
        .forEach(
          (middleware) async => middleware(
            state,
            action,
            (action) => actionsStreamController.add(action),
            (event) => eventStreamController.add(event),
          ),
        );
  }

  void _processReducers(A action, S state) {
    final reducer = widget.reducers
        .firstWhere((reducer) => typeOfReducerAction<S, A>(reducer, action));
    stateStreamController.add(reducer.call(state, action));
  }
}

abstract class StoreConnector<S, A, E, LocalState> extends StatefulWidget {
  const StoreConnector({
    Key? key,
  }) : super(key: key);

  @override
  _StoreConnectorState<S, A, E, LocalState> createState() =>
      _StoreConnectorState<S, A, E, LocalState>();

  Widget build(BuildContext context, LocalState state,
      void Function(A) actionDispatcher);
  LocalState connection(S state);

  void eventSubscription(BuildContext context, E event) async {}
}

class _StoreConnectorState<S, A, E, LocalState>
    extends State<StoreConnector<S, A, E, LocalState>> {
  late StreamSubscription<E> eventStreamSubscription;
  late Stream<S> stateStream;
  late S Function() getState;
  late void Function(A) actionDispatcher;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = Store.of<S, A, E>(context);
    if (store == null) {
      throw new Exception();
    }
    eventStreamSubscription = store.eventStream
        .listen((event) async => widget.eventSubscription(context, event));
    getState = store.getState;
    stateStream = store.stateStream;
    actionDispatcher = store.actionDispatcher;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<LocalState>(
      initialData: widget.connection(getState()),
      stream: stateStream.map((state) => widget.connection(state)).distinct(),
      builder: (context, snapshot) =>
          widget.build(context, snapshot.data!, actionDispatcher),
    );
  }

  @override
  void dispose() {
    super.dispose();
    eventStreamSubscription.cancel();
  }
}

class StoreConnection<S, A, E, LocalState>
    extends StoreConnector<S, A, E, LocalState> {
  const StoreConnection({
    Key? key,
    required this.builder,
    required this.connect,
    this.eventListener,
  }) : super(key: key);

  final Widget Function(BuildContext, LocalState, void Function(A)) builder;
  final LocalState Function(S) connect;
  final Future<void> Function(BuildContext, E)? eventListener;

  @override
  Widget build(BuildContext context, LocalState state,
          void Function(A p1) actionDispatcher) =>
      builder(context, state, actionDispatcher);

  @override
  void eventSubscription(BuildContext context, E event) =>
      eventListener!(context, event);

  @override
  LocalState connection(S state) => connect.call(state);
}

abstract class StoreSubscriber<S, A, E> extends StatefulWidget {
  const StoreSubscriber({
    Key? key,
    required this.child,
  }) : super(key: key);

  final Widget child;

  void eventSubscription(BuildContext context, E event);

  @override
  _StoreSubscriberState<S, A, E> createState() =>
      _StoreSubscriberState<S, A, E>();
}

class _StoreSubscriberState<S, A, E> extends State<StoreSubscriber<S, A, E>> {
  late StreamSubscription<E> eventStreamSubscription;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = Store.of<S, A, E>(context);
    if (store == null) {
      throw new Exception();
    }
    eventStreamSubscription = store.eventStream
        .listen((event) async => widget.eventSubscription(context, event));
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void dispose() {
    super.dispose();
    eventStreamSubscription.cancel();
  }
}

class StoreSubscription<S, A, E> extends StoreSubscriber<S, A, E> {
  const StoreSubscription({
    Key? key,
    required this.eventListener,
    required Widget child,
  }) : super(key: key, child: child);

  final void Function(BuildContext, E) eventListener;

  @override
  void eventSubscription(BuildContext context, E event) async =>
      eventListener(context, event);
}
