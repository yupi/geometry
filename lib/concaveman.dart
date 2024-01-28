// ignore_for_file: curly_braces_in_flow_control_structures

import 'dart:collection';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:rbush/rbush.dart';

import 'orient.dart';
import 'pip.dart';

class Node extends RBushBox {
  Node(this.point);

  final Float64x2 point;
  late Node next;
  late Node prev;

  void updateBBox() {
    final p1 = point;
    final p2 = next.point;
    minX = math.min(p1.x, p2.x);
    minY = math.min(p1.y, p2.y);
    maxX = math.max(p1.x, p2.x);
    maxY = math.max(p1.y, p2.y);
  }

  @override
  String toString() => 'node(x: ${point.x}, y: ${point.y})';
}

List<Float64x2> concaveman({
  required List<Float64x2> points,
  double concavity = 2,
  double lengthThreshold = 0,
}) {
  // start with a convex hull of the points
  final hull = fastConvexHull(points);

  // index the points with an R-tree
  final tree = RBushBase<Float64x2>(
    maxEntries: 16,
    toBBox: (p) => RBushBox(minX: p.x, minY: p.y, maxX: p.x, maxY: p.y),
    getMinX: (p) => p.x,
    getMinY: (p) => p.y,
  );
  tree.load(points);

  // turn the convex hull into a linked list and populate the initial edge queue with the nodes
  Node? last;
  List<Node> queue = [];
  for (int i = 0; i < hull.length; i++) {
    final p = hull[i];
    tree.remove(p);
    last = insertNode(p, last);
    queue.add(last);
  }

  // index the segments with an R-tree (for intersection checks)
  final segTree = RBushBase<Node>(
    maxEntries: 16,
    toBBox: (n) => n,
    getMinX: (n) => n.minX,
    getMinY: (n) => n.minY,
  );
  for (int i = 0; i < queue.length; i++) segTree.insert(queue[i]..updateBBox());

  final sqConcavity = concavity * concavity;
  final sqLenThreshold = lengthThreshold * lengthThreshold;

  // process edges one by one
  while (queue.isNotEmpty) {
    final node = queue.removeAt(0);
    final a = node.point;
    final b = node.next.point;

    // skip the edge if it's already short enough
    final sqLen = sqDist(a, b);
    if (sqLen < sqLenThreshold) continue;

    final maxSqLen = sqLen / sqConcavity;

    // find the best connection point for the current edge to flex inward to
    final p0 = node.prev.point;
    final p1 = node.next.next.point;
    final p = findCandidate(p0, a, b, p1, maxSqLen, tree, segTree);

    if (p != null && math.min(sqDist(p, a), sqDist(p, b)) <= maxSqLen) {
      // connect the edge endpoints through this point and add 2 new edges to the queue
      queue.add(node);
      queue.add(insertNode(p, node));

      // update point and segment indexes
      tree.remove(p);
      segTree.remove(node);
      segTree.insert(node..updateBBox());
      segTree.insert(node.next..updateBBox());
    }
  }

  // convert the resulting hull linked list to an array of points
  Node node = last!;
  final List<Float64x2> concave = [];
  do {
    concave.add(node.point);
    node = node.next;
  } while (node != last);
  concave.add(node.point);
  return concave;
}

Node insertNode(Float64x2 p, Node? prev) {
  final node = Node(p);
  if (prev != null) {
    node.next = prev.next;
    node.prev = prev;
    prev.next.prev = node;
    prev.next = node;
  } else {
     node.next = node;
     node.prev = node;
  }
  return node;
}

Float64x2? findCandidate(
  Float64x2 a, Float64x2 b, Float64x2 c, Float64x2 d,
  double maxDist,
  RBushBase<Float64x2> tree,
  RBushBase<Node> segTree,
) {
  final points = tree.knn2(
    1,
    distance: (p, bbox) {
      final dist = p != null ? sqSegPointDist(p, b, c) : sqSegBoxDist(b, c, bbox);
      return dist <= maxDist ? dist : null;
    },
    predicate: (p, dist) {
      final d0 = sqSegPointDist(p, a, b);
      final d1 = sqSegPointDist(p, c, d);
      return dist < d0 && dist < d1 &&
        noIntersections(b, p, segTree) && noIntersections(c, p, segTree);
    },
  );

  return points.firstOrNull;
}

List<Float64x2> fastConvexHull(List<Float64x2> points) {
  Float64x2 left = points[0];
  Float64x2 top = points[0];
  Float64x2 right = points[0];
  Float64x2 bottom = points[0];

  // find the leftmost, rightmost, topmost and bottommost points
  for (int i = 0; i < points.length; i++) {
    final p = points[i];
    if (p.x < left.x) left = p;
    if (p.x > right.x) right = p;
    if (p.y < top.y) top = p;
    if (p.y > bottom.y) bottom = p;
  }

  final cullSet = HashSet<Float64x2>(
    equals: (a, b) => a.equal(b),
    hashCode: (f) => Object.hashAll([f.x, f.y]),
  )..addAll([left, top, right, bottom]);
  if (cullSet.length < 4) {
    return convexHull(points);
  }

  final cull = cullSet.toList();
  final filtered = [...cull];
  cull.add(cull[0]);
  for (final p in points) {
    if (pointInPolygon(p, cull) > 0) filtered.add(p);
  }

  // get convex hull around the filtered points
  return convexHull(filtered);
}

int compareByX(Float64x2 a, Float64x2 b) => (a.x == b.x ? a.y - b.y : a.x - b.x).sign.toInt();

List<Float64x2> convexHull(List<Float64x2> points) {
  points.sort(compareByX);

  List<Float64x2> lower = [];
  for (int i = 0; i < points.length; i++) {
    while (lower.length >= 2 &&
      cross(lower[lower.length - 2], lower[lower.length - 1], points[i]) <= 0)
    {
      lower.removeLast();
    }
    lower.add(points[i]);
  }

  List<Float64x2> upper = [];
  for (int i = points.length - 1; i >= 0; i--) {
    while (upper.length >= 2 &&
      cross(upper[upper.length - 2], upper[upper.length - 1], points[i]) <= 0)
    {
      upper.removeLast();
    }
    upper.add(points[i]);
  }

  upper.removeLast();
  lower.removeLast();
  return lower..addAll(upper);
}

bool inside(Float64x2 a, RBushBox bbox) {
  return a.x >= bbox.minX &&
    a.x <= bbox.maxX &&
    a.y >= bbox.minY &&
    a.y <= bbox.maxY;
}

// check if the edge (a,b) doesn't intersect any other edges
bool noIntersections(Float64x2 a, Float64x2 b, RBushBase<Node> segTree) {
  final bbox = RBushBox(
    minX: math.min(a.x, b.x),
    minY: math.min(a.y, b.y),
    maxX: math.max(a.x, b.x),
    maxY: math.max(a.y, b.y),
  );

  for (final node in segTree.search(bbox)) {
    if (intersects(node.point, node.next.point, a, b)) return false;
  }
  return true;
}

double cross(Float64x2 p1, Float64x2 p2, Float64x2 p3) {
  return orient2dFast(p1, p2, p3);
}

// check if the edges (p1,q1) and (p2,q2) intersect
bool intersects(Float64x2 p1, Float64x2 q1, Float64x2 p2, Float64x2 q2) {
  return !p1.equal(q2) && !q1.equal(p2) &&
    cross(p1, q1, p2) > 0 != cross(p1, q1, q2) > 0 &&
    cross(p2, q2, p1) > 0 != cross(p2, q2, q1) > 0;
}

double sqDist(Float64x2 p1, Float64x2 p2) {
  final dx = p1.x - p2.x;
  final dy = p1.y - p2.y;
  return dx * dx + dy * dy;
}

// square distance from segment to bbox
double sqSegBoxDist(Float64x2 a, Float64x2 b, RBushBox bbox) {
  if (inside(a, bbox) || inside(b, bbox)) return 0;

  double dist = double.infinity;
  var d1 = sqSegSegDist(a, b, bbox.topLeft, bbox.topRight);
  if (d1 != 0) dist = d1;
  var d2 = sqSegSegDist(a, b, bbox.topLeft, bbox.bottomLeft);
  if (d2 != 0) dist = math.min(dist, d2);
  var d3 = sqSegSegDist(a, b, bbox.topRight, bbox.bottomRight);
  if (d3 != 0) dist = math.min(dist, d3);
  var d4 = sqSegSegDist(a, b, bbox.bottomLeft, bbox.bottomRight);
  if (d4 != 0) dist = math.min(dist, d4);

  return dist;
}

// square distance from a point to a segment
double sqSegPointDist(Float64x2 p0, Float64x2 p1, Float64x2 p2) {
  double x = p1.x;
  double y = p1.y;
  double dx = p2.x - x;
  double dy = p2.y - y;

  if (dx != 0 || dy != 0) {
    var t = ((p0.x - x) * dx + (p0.y - y) * dy) / (dx * dx + dy * dy);
    if (t > 1) {
      x = p2.x;
      y = p2.y;
    } else if (t > 0) {
      x += dx * t;
      y += dy * t;
    }
  }

  dx = p0.x - x;
  dy = p0.y - y;

  return dx * dx + dy * dy;
}

// segment to segment distance,
// ported from http://geomalgorithms.com/a07-_distance.html by Dan Sunday
double sqSegSegDist(Float64x2 p0, Float64x2 p1, Float64x2 p2, Float64x2 p3) {
  final ux = p1.x - p0.x;
  final uy = p1.y - p0.y;
  final vx = p3.x - p2.x;
  final vy = p3.y - p2.y;
  final wx = p0.x - p2.x;
  final wy = p0.y - p2.y;
  final a = ux * ux + uy * uy;
  final b = ux * vx + uy * vy;
  final c = vx * vx + vy * vy;
  final d = ux * wx + uy * wy;
  final e = vx * wx + vy * wy;
  final D = a * c - b * b;

  double sc, sN, tc, tN;
  double sD = D;
  double tD = D;

  if (D == 0) {
    sN = 0;
    sD = 1;
    tN = e;
    tD = c;
  } else {
    sN = b * e - c * d;
    tN = a * e - b * d;
    if (sN < 0) {
      sN = 0;
      tN = e;
      tD = c;
    } else if (sN > sD) {
      sN = sD;
      tN = e + b;
      tD = c;
    }
  }

  if (tN < 0.0) {
    tN = 0.0;
    if (-d < 0.0) sN = 0.0;
    else if (-d > a) sN = sD;
    else {
      sN = -d;
      sD = a;
    }
  } else if (tN > tD) {
    tN = tD;
    if ((-d + b) < 0.0) sN = 0;
    else if (-d + b > a) sN = sD;
    else {
      sN = -d + b;
      sD = a;
    }
  }

  sc = sN == 0 ? 0 : sN / sD;
  tc = tN == 0 ? 0 : tN / tD;

  final cx = (1 - sc) * p0.x + sc * p1.x;
  final cy = (1 - sc) * p0.y + sc * p1.y;
  final cx2 = (1 - tc) * p2.x + tc * p3.x;
  final cy2 = (1 - tc) * p2.y + tc * p3.y;
  final dx = cx2 - cx;
  final dy = cy2 - cy;

  return dx * dx + dy * dy;
}

extension RBushBoxExt on RBushBox {
  Float64x2 get topLeft => Float64x2(minX, minY);
  Float64x2 get topRight => Float64x2(maxX, minY);
  Float64x2 get bottomLeft => Float64x2(minX, maxY);
  Float64x2 get bottomRight => Float64x2(maxX, maxY);
}

extension Float64x2Equal on Float64x2 {
  bool equal(dynamic other) => other is Float64x2 && x == other.x && y == other.y;
}