/*
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:concaveman/src/pip.dart';

void main() {
  test('Basic', () {
    final polygon = Float64x2List.fromList([
      Float64x2(0, 0),
      Float64x2(0, 1),
      Float64x2(1, 1),
      Float64x2(1, 0.5),
      Float64x2(0, 0),
    ]);
    print(pointInPolygon(Float64x2(0.5, 0.249999999), polygon));
  });

  test('Point in polygon', () {
    final polygon = Float64x2List.fromList([
      Float64x2(1, 1),
      Float64x2(1, 2),
      Float64x2(2, 2),
      Float64x2(2, 1),
      Float64x2(1, 1),
    ]);
    expect(pointInPolygon(Float64x2(1.0, 1.0), polygon), 0);
    expect(pointInPolygon(Float64x2(1.0, 2.0), polygon), 0);
    expect(pointInPolygon(Float64x2(2.0, 2.0), polygon), 0);
    expect(pointInPolygon(Float64x2(2.0, 1.0), polygon), 0);
    expect(pointInPolygon(Float64x2(1.5, 1.5), polygon), -1);
    expect(pointInPolygon(Float64x2(1.2, 1.9), polygon), -1);
    expect(pointInPolygon(Float64x2(0.0, 1.9), polygon), 1);
    expect(pointInPolygon(Float64x2(1.5, 2.0), polygon), 0);
    expect(pointInPolygon(Float64x2(1.5, 2.2), polygon), 1);
    expect(pointInPolygon(Float64x2(3.0, 5.0), polygon), 1);

    /*
    var polygon = [ [-1,-1], [1,-1], [1,1], [-1,1] ]
    for(var j=0; j<3; ++j) {
      t.equals(inside(polygon, [0,0]), -1)
      var subdiv = []
      for(var i=0; i<polygon.length; ++i) {
        var a = polygon[i]
        var b = polygon[(i+1)%polygon.length]
        var c = [0.5*(a[0] + b[0]), 0.5*(a[1] + b[1])]
        subdiv.push(a, c)
        t.equals(inside(polygon, polygon[i]), 0)
        t.equals(inside(polygon, c), 0)
      }
      t.equals(inside(polygon, [1e10, 1e10]), 1)
      polygon = subdiv
    }
    */
  });
}
*/