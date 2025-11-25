import 'dart:html' as html;

bool sendLeaveBeaconPayload(String url, String body) {
  final blob = html.Blob([body], 'application/json');
  final success = html.window.navigator.sendBeacon(url, blob);
  if (success) {
    return true;
  }
  try {
    final request = html.HttpRequest();
    request.open('POST', url, async: false);
    request.setRequestHeader('Content-Type', 'application/json');
    request.send(body);

    return request.status! >= 200 && request.status! < 400;
  } catch (_) {
    return false;
  }
}
