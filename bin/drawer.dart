import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:canny_edge_detection/canny_edge_detection.dart';
import 'package:image/image.dart';

import './constants.dart';

Future<void> run(Set<Set<Index2d>> edges) async {
  final socket = await Socket.connect(hostAddress, port);

  bool goodAnswer = true;

  for (final edge in edges) {
    if (goodAnswer && edge.isNotEmpty) {
      final pixel = edge.first;
      final updatedPath = [1, (pixel.x / width * totalWidth), (pixel.y / height * totalHeight)];

      final data = ByteData(17);
      data.setUint8(0, updatedPath[0].toInt());
      data.setFloat64(1, updatedPath[1].toDouble(), Endian.little);
      data.setFloat64(9, updatedPath[2].toDouble(), Endian.little);
      socket.add(data.buffer.asUint8List());

      final response = await socket.first;

      if (response.length == 1 && response[0] == 0) {
        print('Answer from server: [0]');
        goodAnswer = true;
      } else {
        print('Cannot validate response: $response');
        goodAnswer = false;
        await Future.delayed(Duration(seconds: 1));
      }

      await Future.delayed(Duration(milliseconds: 10));
    }
  }

  await socket.close();
}

Future<void> main(List<String> args) async {
  final file = File(args.isNotEmpty ? args[0] : 'input.png');

  Image? image = await decodeImageFile(file.path);
  if (image == null) return;

  final edges = canny(image, blurRadius: 1);

  await run(edges);
}
