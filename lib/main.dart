// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geometry_demo/concaveman.dart';
import 'package:geometry_demo/math.dart';

void main() {
  runApp(const GeometryDemoApp());
}

class GeometryDemoApp extends StatelessWidget {
  const GeometryDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Geometry Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum DemoPage {orientation, pointInPolygon, polygon}

class _HomePageState extends State<HomePage> {
  DemoPage page = DemoPage.orientation;
  UniqueKey key = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.amber,
        title: Text(page.name),
        actions: [
          IconButton(
            onPressed: () => setState(() => key = UniqueKey()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      drawer: Drawer(
        shape: const ContinuousRectangleBorder(),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ListTile(
              selected: page == DemoPage.orientation,
              selectedTileColor: Colors.amber,
              onTap: () {
                setState(() => page = DemoPage.orientation);
                Navigator.pop(context);
              },
              title: const Text('Orientation'),
            ),
            ListTile(
              selected: page == DemoPage.pointInPolygon,
              selectedTileColor: Colors.amber,
              onTap: () {
                setState(() => page = DemoPage.pointInPolygon);
                Navigator.pop(context);
              },
              title: const Text('Point in polygon'),
            ),
            ListTile(
              selected: page == DemoPage.polygon,
              selectedTileColor: Colors.amber,
              onTap: () {
                setState(() => page = DemoPage.polygon);
                Navigator.pop(context);
              },
              title: const Text('Convex/Concave'),
            ),
          ],
        ),
      ),
      body: switch (page) {
        DemoPage.orientation => OrientationDemo(key: key),
        DemoPage.pointInPolygon => PointInPolygonDemo(key: key),
        DemoPage.polygon => PolygonDemo(key: key),
      }
    );
  }
}

class OrientationDemo extends StatefulWidget {
  const OrientationDemo({super.key});

  @override
  State<OrientationDemo> createState() => _OrientationDemoState();
}

class _OrientationDemoState extends State<OrientationDemo> {
  Float64x2 p0 = Float64x2.zero();
  Float64x2 p1 = Float64x2.zero();
  Float64x2List? points;
  List<Color>? colors;
  int count = 3000;

  @override
  void initState() {
    super.initState();
    calculate();
  }

  void calculate() async {
    final rand = Random.secure();
    p0 = randomPoint(rand);
    p1 = randomPoint(rand);

    final (points, result) = await compute((args) {
      final rand = Random(DateTime.now().millisecondsSinceEpoch);
      final points = randomPoints(args.$3, rand);
      final result = calcOrientation(args.$1, args.$2, points);
      return (points, result);
    }, (p0, p1, count));

    setState(() {
      this.points = points;
      colors = result.map((r) => switch (r) {
        < 0 => Colors.blue,
        > 0 => Colors.yellow,
        _   => Colors.red,
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black87,
      child: CustomPaint(
        painter: points != null && colors != null
          ? PointsPainter(points!, colors: colors!)
          : null,
        foregroundPainter: LinePainter(p0, p1),
      ),
    );
  }
}

class PointInPolygonDemo extends StatefulWidget {
  const PointInPolygonDemo({super.key});

  @override
  State<PointInPolygonDemo> createState() => _PointInPolygonDemoState();
}

class _PointInPolygonDemoState extends State<PointInPolygonDemo> {
  Float64x2List? points;
  Float64x2List? polygon;
  List<Color>? colors;
  int count = 1500;

  @override
  void initState() {
    super.initState();
    calculate();
  }

  void calculate() async {
    final rand = Random.secure();
    final polygon = List .generate(8, (_) => randomPoint(rand));
    polygon.add(polygon[0]);
    this.polygon = Float64x2List.fromList(polygon);

    final (points, result) = await compute((args) {
      final rand = Random(DateTime.now().millisecondsSinceEpoch);
      final points = randomPoints(args.$2, rand);
      final result = calcPointInPolygon(args.$1, points);
      return (points, result);
    }, (this.polygon!, count));

    setState(() {
      this.points = points;
      colors = result.map((r) => switch (r) {
        < 0 => Colors.blue,
        > 0 => Colors.yellow,
        _   => Colors.red,
      }).toList();
    });
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black87,
      child: CustomPaint(
        painter: points != null
          ? PointsPainter(points!, colors: colors!)
          : null,
        foregroundPainter: PolygonPainter(points: polygon!, color: Colors.red.shade800),
      ),
    );
  }
}

class PolygonDemo extends StatefulWidget {
  const PolygonDemo({super.key});

  @override
  State<PolygonDemo> createState() => _PolygonDemoState();
}

class _PolygonDemoState extends State<PolygonDemo> {
  late final List<Float64x2> _points;
  late final List<Float64x2> _convexPolygon;
  late final List<Float64x2> _concavePolygon;

  @override
  void initState() {
    super.initState();

    final rand = Random.secure();
    _points = List.generate(25, (_) => randomPoint(rand));
    final convex = fastConvexHull(_points);
    _convexPolygon = convex..add(convex[0]);
    _concavePolygon = concaveman(points: _points, concavity: 1.5);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black87,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: PointsPainter(_points, colors: null, color: Colors.yellow),
          ),
          CustomPaint(
            painter: PolygonPainter(points: _convexPolygon, color: Colors.green)
          ),
          CustomPaint(
            painter: PolygonPainter(points: _concavePolygon, color: Colors.blue)
          ),
        ],
      ),
    );
  }
}

class LinePainter extends CustomPainter {
  LinePainter(this.p0, this.p1);

  final Float64x2 p0;
  final Float64x2 p1;
  
  @override
  void paint(Canvas canvas, Size size) {
    final a = Float64x2.zero();
    final b = Float64x2(size.width, 0);
    final c = Float64x2(size.width, size.height);
    final d = Float64x2(0, size.height);
    final _p0 = Float64x2(p0.x*size.width, p0.y*size.height);
    final _p1 = Float64x2(p1.x*size.width, p1.y*size.height);
    final i1 = linesIntersection(a, b, _p0, _p1);
    final i2 = linesIntersection(b, c, _p0, _p1);
    final i3 = linesIntersection(c, d, _p0, _p1);
    final i4 = linesIntersection(d, a, _p0, _p1);

    List<Offset> line = [];
    if (i1 != null && i1.x >= 0 && i1.x <= size.width) {
      line.add(Offset(i1.x, i1.y));
    }
    if (i2 != null && i2.y >= 0 && i2.y <= size.height) {
      line.add(Offset(i2.x, i2.y));
    }
    if (i3 != null && i3.x >= 0 && i3.x <= size.width) {
      line.add(Offset(i3.x, i3.y));
    }
    if (i4 != null && i4.y >= 0 && i4.y <= size.height) {
      line.add(Offset(i4.x, i4.y));
    }
    assert(line.length == 2);

    final paint = Paint()
      ..color = Colors.red.shade800
      ..strokeWidth = 1.0;
    canvas.drawLine(line[0], line[1], paint);
  }
  
  @override
  bool shouldRepaint(covariant LinePainter oldDelegate) {
    return p0 != oldDelegate.p0 || p1 != oldDelegate.p1;
  }
}

class PointsPainter extends CustomPainter {
  PointsPainter(this.points, {this.colors, this.color});

  final List<Float64x2> points;
  final List<Color>? colors;
  final Color? color;
  
  @override
  void paint(Canvas canvas, Size size) {
    assert(colors != null || color != null);
    for (int i = 0; i < points.length; ++i) {
      final offset = Offset(points[i].x*size.width, points[i].y*size.height);
      final paint = Paint()..color = colors != null ? colors![i] : color!;
      canvas.drawCircle(offset, 2.5, paint);

      //final builder = ParagraphBuilder(ParagraphStyle(
      //  textAlign: TextAlign.left,
      //  fontSize: 10,
      //))
      //  ..addText('(${points[i].x}, ${points[i].y})');
      //final para = builder.build()..layout(const ParagraphConstraints(width: 150));
      //canvas.drawParagraph(para, offset);
    }
  }
  
  @override
  bool shouldRepaint(covariant PointsPainter oldDelegate) {
    return points != oldDelegate.points || colors != oldDelegate.colors;
  }
}

class PolygonPainter extends CustomPainter {
  PolygonPainter({required this.points, required this.color});

  final List<Float64x2> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scaledPoints = points
      .map((p) => Offset(p.x*size.width, p.y*size.height))
      .toList(growable: false);

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    canvas.drawPoints(PointMode.polygon, scaledPoints, paint);
  }

  @override
  bool shouldRepaint(covariant PolygonPainter oldDelegate) {
    return points != oldDelegate.points;
  }
}