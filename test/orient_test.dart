import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:test/test.dart';

import 'package:geometry_demo/orient.dart';

void main() {
  group('Orientation', () {
    test('Basic', () {
      //expect(orient2d(Float64x2(0, 0), Float64x2(1, 1), Float64x2(0, 1)), lessThan(0));
      //expect(orient2d(Float64x2(0, 0), Float64x2(0, 1), Float64x2(1, 1)), greaterThan(0));
      //expect(orient2d(Float64x2(0, 0), Float64x2(0.5, 0.5), Float64x2(1, 1)), equals(0));

      const r = 0.95;
      const q = 18.0;
      const p = 16.8;
      final w = math.pow(2, -43);

      for (int i = 0; i < 1; i++) {
        for (int j = 0; j < 10; j++) {
          final x = r + w * i / 128.0;
          final y = r + w * j / 128.0;
          final p0 = Float64x2(x, y);
          final p1 = Float64x2(q, q);
          final p2 = Float64x2(p, p);
          orient2d(p0, p1, p2);
        }
      }
    });

    test('Fixture', () async {
      final fixture = File('test/fixtures/orient2d.txt')
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

      await for (final line in fixture) {
        final data = line.split(' ');
        final a = Float64x2(double.parse(data[1]), double.parse(data[2]));
        final b = Float64x2(double.parse(data[3]), double.parse(data[4]));
        final c = Float64x2(double.parse(data[5]), double.parse(data[6]));
        final sign = double.parse(data[7]);
        expect(orient2d(a, b, c), equals(-sign));
      }
    });
  });
}
