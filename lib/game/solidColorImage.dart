import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math.dart' show Vector2;

Future<Image> solidColorImage(Vector2 size, Color color) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..color = color;

  final rect = Rect.fromLTWH(0, 0, size.x, size.y);
  canvas.drawRect(rect, paint);

  final picture = recorder.endRecording();
  final uiImage = await picture.toImage(size.x.toInt(), size.y.toInt());
  return Image.memory(
    (await uiImage.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List(),
    width: size.x,
    height: size.y,
  );
}