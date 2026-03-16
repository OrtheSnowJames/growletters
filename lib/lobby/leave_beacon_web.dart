import 'dart:html' as html;

bool sendLeaveBeaconPayload(String url, String body, String authToken) {
  try {
    final request = html.HttpRequest();
    request.open('POST', url, async: false);
    request.setRequestHeader('Content-Type', 'application/json');
    request.setRequestHeader('Authorization', 'Bearer $authToken');
    request.send(body);

    return request.status! >= 200 && request.status! < 400;
  } catch (_) {
    return false;
  }
}
