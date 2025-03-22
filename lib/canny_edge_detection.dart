import 'dart:collection';
import 'dart:math' as math;

import 'package:image/image.dart';

/// Detects edges on a given image using the canny edge detection algorithm.
/// This function changes the input image and stores a visualized result of
/// canny edge detection algorithm in it after this function terminates.
/// If you dont want your image object to be changed, call image.clone() beforehand.
/// Canny edge detection is a multi stage algorithm. After each stage, the
/// resulting image can be viewed by utilizing [onGrayConversion],
/// [onBlur], [onSobel], [onNonMaxSuppressed] and [onImageResult] function parameters.
/// Do not change any pixels of the images of the intermediate steps, because
/// they are needed for the following steps. If you want to use the images
/// of the intermediate steps use image.clone()!
/// This function returns a set of all found edges, where an edge is a set
/// of edge-indicating pixels which are connected along the direction of
/// the edge.
/// [lowThreshold] and [highThreshold] parameters determine when a possible
/// edge is defensively suppressed (if signal is lower than [lowThreshold]) and
/// when an edge is defensively preserved (if signal is higher than [highThreshold]).
/// If at least one of the thresholds are given, the other one is set to its
/// double or to its half. If no threshold is given, [highThreshold] is determined
/// by otsus method which splits an image into two classes (foreground & background)
/// and [lowThreshold] is set to half of [highThreshold].
Set<Set<Index2d>> canny(
  Image image, {
  int blurRadius = 2,
  int? lowThreshold,
  int? highThreshold,
  void Function(Image image)? onGrayConversion,
  void Function(Image image)? onBlur,
  void Function(Image image)? onSobel,
  void Function(Image image)? onNonMaxSuppressed,
  void Function(Image image)? onImageResult,
}) {
  //<Convert colored image to grayscale data>
  grayscale(image);
  if (onGrayConversion != null) onGrayConversion(image);

  //<Blur image in order to smooth out noise>
  //do not blur if blurVariance is null
  gaussianBlur(image, radius: blurRadius);
  if (onBlur != null) onBlur(image);

  //<Apply Sobel convolution on Image>
  //and safe orientation of edges
  Image sobel = Image(width: image.width, height: image.height);
  Image edgeDirection = Image(width: image.width, height: image.height);

  int getRed(Pixel pixel) => pixel.getChannel(Channel.red).toInt();
  int clampX(num x) => x.clamp(0, image.width - 1).toInt();
  int clampY(num y) => y.clamp(0, image.height - 1).toInt();
  int clamp255(num p) => p.clamp(0, 255).toInt();
  int getSafe(int x, int y, Image image) => getRed(image.getPixel(clampX(x), clampY(y)));

  for (var y = 0; y < image.height; ++y) {
    for (var x = 0; x < image.width; ++x) {
      int gx = -getSafe(x - 1, y - 1, image) -
          2 * getSafe(x - 1, y, image) -
          getSafe(x - 1, y + 1, image) +
          getSafe(x + 1, y - 1, image) +
          2 * getSafe(x + 1, y, image) +
          getSafe(x + 1, y + 1, image);
      int gy = -getSafe(x - 1, y + 1, image) -
          2 * getSafe(x, y + 1, image) -
          getSafe(x + 1, y + 1, image) +
          getSafe(x - 1, y - 1, image) +
          2 * getSafe(x, y - 1, image) +
          getSafe(x + 1, y - 1, image);
      int mag = clamp255(math.sqrt(gx * gx + gy * gy));
      sobel.setPixelRgba(x, y, mag, mag, mag, 255);
      double direction = math.atan2(gy, gx);
      //convert to angle
      direction = (direction + math.pi / 2) * 180 / math.pi;
      if (direction >= 22.5 && direction < 67.5) {
        //45 deg
        edgeDirection.setPixel(x, y, ColorUint8.rgb(45, 0, 0));
      } else if (direction >= 67.5 && direction < 112.5) {
        //90 deg
        edgeDirection.setPixel(x, y, ColorUint8.rgb(90, 0, 0));
      } else if (direction >= 112.5 && direction < 157.5) {
        //135 deg
        edgeDirection.setPixel(x, y, ColorUint8.rgb(135, 0, 0));
      } else {
        //0 deg
        edgeDirection.setPixel(x, y, ColorUint8.rgb(0, 0, 0));
      }
      // 0 degrees describes a vertical edge and with
      // increasing degrees the edge is going counter-clockwise
    }
  }
  if (onSobel != null) onSobel(sobel);

  // helper function to determine neighbours of an edge
  getNeighbours(x, y) {
    int direction = getRed(edgeDirection.getPixel(x, y));
    Set<Index2d> nei = {};
    switch (direction) {
      case 0:
        if (y > 0) nei.add(Index2d(x, y - 1));
        if (y < image.height - 1) nei.add(Index2d(x, y + 1));
        break;
      case 45:
        if (x > 0 && y > 0) nei.add(Index2d(x - 1, y - 1));
        if (x < image.width - 1 && y < image.height - 1) {
          nei.add(Index2d(x + 1, y + 1));
        }
        break;
      case 90:
        if (x > 0) nei.add(Index2d(x - 1, y));
        if (x < image.width - 1) nei.add(Index2d(x + 1, y));
        break;
      case 135:
        if (y > 0 && x < image.width - 1) nei.add(Index2d(x + 1, y - 1));
        if (x > 0 && y < image.height - 1) nei.add(Index2d(x - 1, y + 1));
        break;
    }
    return nei;
  }

  // <non-maximum suppression>
  for (var y = 0; y < image.height; ++y) {
    for (var x = 0; x < image.width; ++x) {
      int p = getRed(sobel.getPixel(x, y));
      Set<Index2d> nei = getNeighbours(x, y);
      int max = nei.fold(p, (t, i) {
        int pNew = getRed(sobel.getPixel(i.x, i.y));
        return t > pNew ? t : pNew;
      });
      // suppress value if not maximum
      if (max > p) {
        image.setPixelRgba(x, y, 0, 0, 0, 255);
      } else {
        image.setPixelRgba(x, y, p, p, p, 255);
      }
    }
  }
  if (onNonMaxSuppressed != null) onNonMaxSuppressed(image);

  // <Double threshold and hysteresis>
  // first determine threshold values
  // if only lowThreshold value is given, highThreshold is set to its double
  // if only highThreshold value is given, lowThreshold is set to its half
  // if neither threshold values are given, a high threshold value is calculated
  // by otsus method and the lowThreshold value is set to its half
  if (lowThreshold == null && highThreshold == null) {
    highThreshold = _otsusMethod(image);
    lowThreshold = highThreshold ~/ 2;
  } else if (lowThreshold == null) {
    highThreshold = highThreshold!.clamp(0, 255).toInt();
    lowThreshold = highThreshold ~/ 2;
  } else if (highThreshold == null) {
    lowThreshold = lowThreshold.clamp(0, 255).toInt();
    highThreshold = (lowThreshold * 2).clamp(0, 255).toInt();
  } else {
    lowThreshold = lowThreshold.clamp(0, 255).toInt();
    highThreshold = highThreshold.clamp(0, 255).toInt();
    if (lowThreshold > highThreshold) lowThreshold = highThreshold;
  }

  //hysteresis by blob analysis
  isWeak(x, y) => getSafe(x, y, image) >= lowThreshold!;
  isStrong(x, y) => getSafe(x, y, image) >= highThreshold!;
  Set<Set<Index2d>> edges = {};
  Set<Index2d> nonEdges = {};
  int currentLabel = 2;
  ListQueue<Index2d> currentBlobNeighbours = ListQueue();
  Image labeledPixels = Image(width: image.width, height: image.height);

  // a pixel which is neither weak or strong is considered background and is labeled 1
  // a pixel which is at least weak is consideres foreground and is labeled with the
  // same label as all pixels it is connected to along its edge direction
  // a background label will be supressed and a foreground label will not be suppressed
  // if and only if it is in the same region (same label) as a strong edge

  // The image is analyzed component wise, that is, if a (new) connected region is found
  // (two neighbouring pixels are connected if one of their edge direction implies that)
  // then the whole connected region is explored and labelled under the same unique label
  // before continuing analyzing the image in a canoncial order
  for (var y = 0; y < image.height; ++y) {
    for (var x = 0; x < image.width; ++x) {
      // if current pixel is not weak, label it with 1
      if (!isWeak(x, y)) {
        // pixel is background
        labeledPixels.setPixel(x, y, ColorUint8.rgb(1, 0, 0));
        image.setPixelRgba(x, y, 0, 0, 0, 255);
        continue;
      }
      if (getRed(labeledPixels.getPixel(x, y)) != 0) {
        // pixel was already labeled
        continue;
      }
      // pixel is an unlabeled foreground edge
      currentBlobNeighbours.addLast(Index2d(x, y));
      bool isStrongEdge = false;
      Set<Index2d> currentEdge = {};
      while (currentBlobNeighbours.isNotEmpty) {
        Index2d w = currentBlobNeighbours.removeLast();
        currentEdge.add(w);
        if (isStrong(w.x, w.y)) {
          isStrongEdge = true;
        }
        labeledPixels.setPixel(w.x, w.y, ColorUint8.rgb(currentLabel, 0, 0));
        // get all neighbours of pixel at (w.x,w.y)
        // a neighbour of a pixel A is one of the two
        // pixels along the edge direction of A OR a
        // pixel B for which A is a pixel along B's
        // edge direction!
        // if a neighbour is a foreground pixel and
        // not already labelled put it in Queue
        Set<Index2d> symmetricNeighbours = {};
        symmetricNeighbours.addAll(getNeighbours(w.x, w.y));
        if (w.x > 0 && w.y > 0 && getNeighbours(w.x - 1, w.y - 1).contains(w)) {
          symmetricNeighbours.add(Index2d(w.x - 1, w.y - 1));
        }
        if (w.y > 0 && getNeighbours(w.x, w.y - 1).contains(w)) {
          symmetricNeighbours.add(Index2d(w.x, w.y - 1));
        }
        if (w.x < image.width - 1 && w.y > 0 && getNeighbours(w.x + 1, w.y - 1).contains(w)) {
          symmetricNeighbours.add(Index2d(w.x + 1, w.y - 1));
        }
        if (w.x > 0 && w.y < image.height - 1 && getNeighbours(w.x - 1, w.y + 1).contains(w)) {
          symmetricNeighbours.add(Index2d(w.x - 1, w.y + 1));
        }
        if (w.y < image.height - 1 && getNeighbours(w.x, w.y + 1).contains(w)) {
          symmetricNeighbours.add(Index2d(w.x, w.y + 1));
        }
        if (w.x < image.width - 1 && w.y < image.height - 1 && getNeighbours(w.x + 1, w.y + 1).contains(w)) {
          symmetricNeighbours.add(Index2d(w.x + 1, w.y + 1));
        }
        if (w.x > 0 && getNeighbours(w.x - 1, w.y).contains(w)) {
          symmetricNeighbours.add(Index2d(w.x - 1, w.y));
        }
        if (w.x < image.width - 1 && getNeighbours(w.x + 1, w.y).contains(w)) {
          symmetricNeighbours.add(Index2d(w.x + 1, w.y));
        }
        for (var neighbour in symmetricNeighbours) {
          //if edge is foreground edge and not yet labbeled
          if (isWeak(neighbour.x, neighbour.x) && labeledPixels.getPixel(neighbour.x, neighbour.y) == 0) {
            currentBlobNeighbours.add(neighbour);
          }
        }
      }
      if (isStrongEdge) {
        edges.add(currentEdge);
      } else {
        nonEdges.addAll(currentEdge);
      }
      currentLabel++;
    }
  }

  // Suppress all weak edges which are neither strong nor lie in the same region as a strong edge.
  for (var w in nonEdges) {
    image.setPixelRgba(w.x, w.y, 0, 0, 0, 255);
  }

  if (onImageResult != null) onImageResult(image);

  return edges;
}

/// Calculates a luminance threshold for an given input image
/// which separates the images pixels in two classes
/// (background and foreground), so that the intra-class variance
/// of the two foreground and background classes in minimized
int _otsusMethod(Image image) {
  //create histogram of image gray values
  List<int> histogram = List.filled(256, 0);
  for (var y = 0; y < image.height; ++y) {
    for (var x = 0; x < image.width; ++x) {
      histogram[getLuminance(image.getPixel(x, y)).toInt()]++;
    }
  }
  final int imageDimension = image.width * image.height;

  int bestThreshold = 0;
  double maxBetweenClassVariance = 0;

  for (var currentThreshold = 1; currentThreshold < 255; ++currentThreshold) {
    //helper values
    final int backgroundSum = histogram.sublist(0, currentThreshold).fold(0, (a, b) => a + b);
    final int foregroundSum = imageDimension - backgroundSum;

    //calculate Weights
    final double backgroundWeight = backgroundSum / imageDimension;
    final double foregroundWeight = 1 - backgroundWeight;

    //calculate mean
    double backgroundMean = 0;
    for (var i = 0; i < currentThreshold; ++i) {
      backgroundMean += i * histogram[i];
    }
    backgroundMean /= backgroundSum;

    double foregroundMean = 0;
    for (var i = currentThreshold; i < 256; ++i) {
      foregroundMean += i * histogram[i];
    }
    foregroundMean /= foregroundSum;

    // calculate between class variance
    final double currentBetweenClassVariance =
        backgroundWeight * foregroundWeight * math.pow(backgroundMean - foregroundMean, 2);

    if (currentBetweenClassVariance > maxBetweenClassVariance) {
      bestThreshold = currentThreshold;
      maxBetweenClassVariance = currentBetweenClassVariance;
    }
  }

  return bestThreshold;
}

/// This class represents an immutable 2-Tuple for integers.
/// It represents two dimensional indices for pixels in an image.
class Index2d {
  final int x, y;

  const Index2d(this.x, this.y);

  @override
  bool operator ==(var other) => other is Index2d && other.x == x && other.y == y;

  @override
  int get hashCode => x.hashCode | y.hashCode;

  @override
  String toString() {
    return '($x, $y)';
  }
}
