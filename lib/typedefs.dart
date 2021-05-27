typedef Reducer<S, A> = S Function(S, A);

typedef Middleware<S, A, E> = void Function(
  S,
  A,
  void Function(A),
  void Function(E),
);

bool typeOfReducerAction<S, A>(Reducer<S, A> r, dynamic action) =>
    A == action.runtimeType;

bool typeOfMiddlewareAction<S, A, E>(Middleware<S, A, E> m, dynamic action) =>
    A == action.runtimeType;
