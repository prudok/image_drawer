import 'package:dartcv4/dartcv.dart';

class DrawBuilder {
  final Mat image;
  final double epsilonFactor;
  final int lineSpacing;
  final double areaLimit;

  DrawBuilder({
    required this.image,
    this.epsilonFactor = 0.01,
    this.lineSpacing = 5,
    this.areaLimit = 0,
  });

  Contours? contours;
  List<List<Point>> approxContours = [];

  void analyzeContours() {
    final result = findContours(
      image,
      RETR_LIST,
      CHAIN_APPROX_SIMPLE,
    );

    contours = result.$1;
    if (contours == null) {
      print('No contours found');
      return;
    }

    for (final contour in contours!) {
      final epsilon = epsilonFactor * arcLength(contour, true);
      final approx = approxPolyDP(contour, epsilon, true);
      final area = contourArea(approx);

      if (area >= areaLimit) {
        // TODO: check if working wrong
        approxContours.add(approx.toList());
      }
    }
  }

  Iterable<(bool, double, double)> pathIterator() sync* {
    analyzeContours();

    for (int i = 0; i < approxContours.length; i++) {
      final contour = approxContours[i];

      if (contour.length >= 3) {
        contour.add(contour.first);
      }

      yield (true, contour.first.x.toDouble(), contour.first.y.toDouble());

      for (final point in contour) {
        yield (false, point.x.toDouble(), point.y.toDouble());
      }
    }

    yield (true, 0, 0);
    yield (false, -1, -1);
  }
}
