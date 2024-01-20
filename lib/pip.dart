// Ported to dart with modifications by Yuri Pimenov 2023
// https://web.archive.org/web/20130126163405/http://geomalgorithms.com/a03-_inclusion.html

// Copyright 2000 softSurfer, 2012 Dan Sunday
// This code may be freely used and modified for any purpose
// providing that this copyright notice is included with it.
// SoftSurfer makes no warranty for this code, and cannot be held
// liable for any real or imagined damage resulting from its use.
// Users of this code must verify correctness for their application.

import 'dart:typed_data';

import 'orient.dart';

// pointInPoligon(): test for a point in a polygon
//   Input:  p = a point
//           vs = vertex points of a polygon, vs[n+1] with vs[n]=V[0]
//   Return: -1 - inside
//            0 - on boundary 
//            1 - outside
int pointInPolygon(Float64x2 p, List<Float64x2> vs) {
  int wn = 0;
  for (int i = 0; i < vs.length - 1; i++) {
    final p0 = vs[i];
    final p1 = vs[i+1];
    final orient = orient2dFast(p0, p1, p);
    if (orient == 0) return 0;

    if (p0.y <= p.y) {
      if (p1.y > p.y) {
        if (orient > 0) ++wn;
      }
    } else {
      if (p1.y <= p.y) {
        if (orient < 0) --wn;
      }
    }
  }

  return wn == 0 ? 1 : -1;
}