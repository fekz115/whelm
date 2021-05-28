typedef Reducer<S, A> = S Function(S, A);

typedef Middleware<S, A, E> = void Function(
  S,
  A,
  void Function(A),
  void Function(E),
);

bool typeOfReducerAction<S, A>(Reducer<S, A> r, dynamic action) =>
    action is A;

bool typeOfMiddlewareAction<S, A, E>(Middleware<S, A, E> m, dynamic action) =>
    action is A;
