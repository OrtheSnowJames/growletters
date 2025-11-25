typedef UnloadDisposer = void Function();

UnloadDisposer registerBeforeUnloadImpl(void Function() callback) {
  return () {};
}
