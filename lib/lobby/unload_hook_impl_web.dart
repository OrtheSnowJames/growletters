import 'dart:html' as html;

typedef UnloadDisposer = void Function();

UnloadDisposer registerBeforeUnloadImpl(void Function() callback) {
  void listener(html.Event event) {
    callback();
    if (event is html.BeforeUnloadEvent) {
      // Allow default behaviour; no prompt by default.
      event.returnValue = '';
    }
  }

  html.window.addEventListener('beforeunload', listener);
  return () {
    html.window.removeEventListener('beforeunload', listener);
  };
}
