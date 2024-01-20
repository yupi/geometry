import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'orient.dart';
import 'pip.dart';

Float64x2 randomPoint(Random rand, {Size size = const Size(1.0, 1.0)}) {
  return Float64x2(
    rand.nextDouble()*size.width,
    rand.nextDouble()*size.height,
  );
}

Float64x2List randomPoints(int count, Random rand, {Size size = const Size(1.0, 1.0)}) {
  final l = Float64x2List(count);
  for (var i = 0; i < count; ++i) {
    l[i] = randomPoint(rand, size: size);
  }
  return l;
}

Float64x2? linesIntersection(Float64x2 p1, Float64x2 p2, Float64x2 p3, Float64x2 p4) {
  final denom = (p1.x - p2.x)*(p3.y - p4.y) - (p1.y - p2.y)*(p3.x - p4.x);
  if (denom == 0) {
    return null;
  }
  final d1 = p1.x*p2.y - p1.y*p2.x;
  final d2 = p3.x*p4.y - p3.y*p4.x;
  final x = (d1*(p3.x - p4.x) - (p1.x - p2.x)*d2)/denom;
  final y = (d1*(p3.y - p4.y) - (p1.y - p2.y)*d2)/denom;
  return Float64x2(x, y);
}

Int8List calcOrientation(Float64x2 p0, Float64x2 p1, List<Float64x2> points) {
  final result = Int8List(points.length);
  for (int i = 0; i < result.length; ++i) {
    result[i] = orient2dFast(p0, p1, points[i]).toInt();
  }
  return result;
}

Int8List calcPointInPolygon(List<Float64x2> polygon, List<Float64x2> points) {
  final result = Int8List(points.length);
  for (int i = 0; i < result.length; ++i) {
    result[i] = pointInPolygon(points[i], polygon).toInt();
  }
  return result;
}