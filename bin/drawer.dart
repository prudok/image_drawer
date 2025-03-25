import 'draw_builder.dart';
import 'image_builder.dart';

const W = 200.0;
const H = 200.0;
const areaLimit = 1.0;
const width = 1000;
const height = 1000;
const threshold = 50;

Future<void> run() async {
  final imageBuilder = ImageBuilder('input.png', width, height, threshold);
  final matImage = await imageBuilder.build();

  final drawer = DrawBuilder(
    image: matImage,
    lineSpacing: 5,
    areaLimit: (width * height) / (W * H) * areaLimit,
  );

  final path = drawer.pathIterator();

  for (final element in path) {
    if (element == (false, -1.0, -1.0)) break;

    final scaledX = (element.$2 / width * W).toStringAsFixed(2);
    final scaledY = (element.$3 / height * H).toStringAsFixed(2);

    print('Sending path element: (${element.$1}, $scaledX, $scaledY)');
  }
}

Future<void> main() async {
  await run();
}
