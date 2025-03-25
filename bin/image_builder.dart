import 'package:dartcv4/dartcv.dart';

class ImageBuilder {
  final String path;
  final int width;
  final int height;
  final int threshold;
  Mat? image;

  ImageBuilder(this.path, this.width, this.height, this.threshold);

  Future<Mat> build() async {
    final image = imread(path, flags: IMREAD_GRAYSCALE);
    resize(image, (width, height));
    thresholdAsync(image, threshold.toDouble(), 255, THRESH_BINARY);
    return image;
  }
}
