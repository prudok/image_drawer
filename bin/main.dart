import 'dart:io';

import 'package:canny_edge_detection/canny_edge_detection.dart';
import 'package:image/image.dart';

import 'drawer.dart';

Future<void> main(List<String> args) async {
  final file = File(args.isNotEmpty ? args[0] : 'input.png');

  Image? image = await decodeImageFile(file.path);

  if (image == null) return;

  final edges = canny(image, blurRadius: 2);

  final newImage = Image(width: image.width, height: image.height);

  for (final edge in edges) {
    final pixel = edge.first;
    newImage.setPixelRgb(pixel.x, pixel.y, 255, 255, 255);
  }

  run(edges);
}
