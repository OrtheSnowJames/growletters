import 'unload_hook_impl_stub.dart'
    if (dart.library.html) 'unload_hook_impl_web.dart' as impl;

typedef UnloadDisposer = impl.UnloadDisposer;

UnloadDisposer registerBeforeUnload(void Function() callback) {
  return impl.registerBeforeUnloadImpl(callback);
}
