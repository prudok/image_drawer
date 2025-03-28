import 'dart:io';

import 'package:image/image.dart';

import 'canny_edge_detection.dart';
import 'constants.dart';

Future<void> main(List<String> args) async {
  final file = File(args.isNotEmpty ? args[0] : 'input.png');

  Image? image = await decodeImageFile(file.path);
  if (image == null) return;

  final formattedImage = copyResize(image, width: width, height: height);

  final edges = canny(
    formattedImage,
    lowThreshold: 50,
    highThreshold: 50,
    blurRadius: 2,
  );

  int coordinatesLength = 0;

  for (final edge in edges) {
    if (edge.isEmpty) continue;
    coordinatesLength += 1;

    final pixel = edge.first;
    formattedImage.setPixelRgb(pixel.x, pixel.y, pixel.x % 255, 255, 255);
    print('${pixel.x}, ${pixel.y}');
  }

  print('Total coordinates: $coordinatesLength');
  File('output.png').writeAsBytesSync(encodePng(formattedImage));
}
