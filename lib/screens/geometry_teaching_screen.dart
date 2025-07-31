// lib/screens/geometry_teaching_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_polygon/flutter_polygon.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui;
import 'dart:math';

class GeometryTeachingScreen extends StatefulWidget {
  const GeometryTeachingScreen({super.key});

  @override
  _GeometryTeachingScreenState createState() => _GeometryTeachingScreenState();
}

class _GeometryTeachingScreenState extends State<GeometryTeachingScreen> {
  late FlutterTts flutterTts;

  // قائمة الأشكال مع خصائصها
  List<ShapeInfo> shapes = [
    ShapeInfo(
      name: 'مثلث',
      sides: 3,
      description: 'هو شكل هندسي يتكون من ثلاثة أضلاع وثلاث زوايا.',
      color: Colors.red,
      shapeType: ShapeType.polygon,
    ),
    ShapeInfo(
      name: 'مربع',
      sides: 4,
      description: 'هو شكل رباعي جميع أضلاعه متساوية وجميع زواياه قائمة.',
      color: Colors.green,
      shapeType: ShapeType.polygon,
      imagePath: 'assets/square.png',
    ),
    ShapeInfo(
      name: 'مستطيل',
      sides: 4,
      description: 'هو شكل رباعي بأضلاع متقابلة متساوية وزوايا قائمة.',
      color: Colors.blue,
      shapeType: ShapeType.rectangle,
    ),
    ShapeInfo(
      name: 'دائرة',
      sides: 0,
      description: 'هي شكل مستوي جميع النقاط عليه تبعد نفس المسافة عن المركز.',
      color: Colors.orange,
      shapeType: ShapeType.circle,
    ),
    ShapeInfo(
      name: 'معين',
      sides: 4,
      description:
          'هو شكل رباعي جميع أضلاعه متساوية والأضلاع المتقابلة متوازية.',
      color: Colors.purple,
      shapeType: ShapeType.rhombus,
    ),
    ShapeInfo(
      name: 'مضلع خماسي',
      sides: 5,
      description: 'هو مضلع مكون من خمسة أضلاع وخمس زوايا.',
      color: Colors.teal,
      shapeType: ShapeType.polygon,
    ),
    ShapeInfo(
      name: 'مضلع سداسي',
      sides: 6,
      description: 'هو مضلع مكون من ستة أضلاع وست زوايا.',
      color: Colors.brown,
      shapeType: ShapeType.polygon,
    ),
    ShapeInfo(
      name: 'مضلع ثماني',
      sides: 8,
      description: 'هو مضلع مكون من ثمانية أضلاع وثمان زوايا.',
      color: Colors.cyan,
      shapeType: ShapeType.polygon,
    ),
    ShapeInfo(
      name: 'مكعب',
      sides: 6, // المكعب له 6 أوجه
      description: 'هو شكل ثلاثي الأبعاد يتكون من ستة أوجه مربعة.',
      color: Colors.grey,
      shapeType: ShapeType.cube,
      imagePath: 'assets/cube.png',
    ),
    ShapeInfo(
      name: 'مثلث قائم الزاوية',
      sides: 3,
      description: 'هو مثلث يحتوي على زاوية قائمة (90 درجة).',
      color: Colors.indigo,
      shapeType: ShapeType.rightTriangle,
    ),
    ShapeInfo(
      name: 'بيضاوي',
      sides: 0,
      description: 'هو شكل يشبه الدائرة ولكنه ممدود.',
      color: Colors.lime,
      shapeType: ShapeType.oval,
    ),
    ShapeInfo(
      name: 'هرم',
      sides: 5, // الهرم الرباعي له 5 أوجه
      description:
          'هو شكل ثلاثي الأبعاد ذو قاعدة متعددة الأضلاع وأوجه مثلثة تلتقي في قمة.',
      color: Colors.pink,
      shapeType: ShapeType.pyramid,
      imagePath: 'assets/pyramid.png',
    ),
    ShapeInfo(
      name: 'مخروط',
      sides: 2, // المخروط له قاعدة وجانب منحني
      description:
          'هو شكل ثلاثي الأبعاد ذو قاعدة دائرية وجانب منحني يلتقي في قمة.',
      color: Colors.amber,
      shapeType: ShapeType.cone,
      imagePath: 'assets/cone.png',
    ),
    ShapeInfo(
      name: 'أسطوانة',
      sides: 3, // الأسطوانة لها قاعدتان وجانب منحني
      description:
          'هو شكل ثلاثي الأبعاد ذو قاعدتين دائريتين متوازيتين وجانب منحني.',
      color: Colors.deepOrange,
      shapeType: ShapeType.cylinder,
      imagePath: 'assets/pyramid.png',
    ),
    ShapeInfo(
      name: 'منحنى',
      sides: 0,
      description: 'هو خط غير مستقيم يتغير اتجاهه باستمرار.',
      color: Colors.deepPurple,
      shapeType: ShapeType.curve,
    ),
    ShapeInfo(
      name: 'شبه منحرف',
      sides: 4,
      description: 'هو شكل رباعي له زوج واحد من الأضلاع المتوازية.',
      color: Colors.lightBlue,
      shapeType: ShapeType.trapezoid,
    ),
    ShapeInfo(
      name: 'متوازي الأضلاع',
      sides: 4,
      description:
          'هو شكل رباعي فيه كل زوج من الأضلاع المتقابلة متوازية ومتساوية.',
      color: Colors.lightGreen,
      shapeType: ShapeType.parallelogram,
    ),
  ];

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();

    // تفعيل الانتظار حتى ينتهي النطق
    flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> speak(String text) async {
    await flutterTts.setLanguage("ar-SA");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // اتجاه من اليمين إلى اليسار
      child: Scaffold(
        appBar: AppBar(
          title: Text('تعلم الأشكال الهندسية'),
          backgroundColor: Colors.white,
          systemOverlayStyle: SystemUiOverlayStyle.light,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            itemCount: shapes.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // عدد العناصر في كل صف
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.8, // تعديل حسب الحاجة
            ),
            itemBuilder: (context, index) {
              final shapeInfo = shapes[index];
              return GestureDetector(
                onTap: () {
                  // الانتقال إلى تفاصيل الشكل
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShapeDetailScreen(
                        shapeInfo: shapeInfo,
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ShapeWidget(shapeInfo: shapeInfo, size: 80),
                        SizedBox(height: 10),
                        Text(
                          shapeInfo.name,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ShapeDetailScreen extends StatefulWidget {
  final ShapeInfo shapeInfo;

  const ShapeDetailScreen({super.key, required this.shapeInfo});

  @override
  _ShapeDetailScreenState createState() => _ShapeDetailScreenState();
}

class _ShapeDetailScreenState extends State<ShapeDetailScreen> {
  late FlutterTts flutterTts;

  @override
  void initState() {
    super.initState();
    flutterTts = FlutterTts();

    // تفعيل الانتظار حتى ينتهي النطق
    flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> speak(String text) async {
    await flutterTts.setLanguage("ar-SA");
    await flutterTts.setSpeechRate(0.5);
    await flutterTts.setPitch(1.0);
    await flutterTts.speak(text);
  }

  @override
  void dispose() {
    flutterTts.stop();
    super.dispose();
  }

  // دالة لفتح شاشة الرسم
  void openDrawingScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DrawingScreen(shapeInfo: widget.shapeInfo),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // اتجاه من اليمين إلى اليسار
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.shapeInfo.name),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ShapeWidget(shapeInfo: widget.shapeInfo, size: 150),
                SizedBox(height: 20),
                Text(
                  widget.shapeInfo.description,
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () async {
                    await speak(widget.shapeInfo.description);
                  },
                  icon: Icon(Icons.volume_up),
                  label: Text('استمع إلى الوصف'),
                ),
                SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: openDrawingScreen,
                  icon: Icon(Icons.brush),
                  label: Text('ارسم الشكل'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DrawingScreen extends StatefulWidget {
  final ShapeInfo shapeInfo;

  const DrawingScreen({super.key, required this.shapeInfo});

  @override
  _DrawingScreenState createState() => _DrawingScreenState();
}

enum DrawMode { freehand, line, rectangle, circle }

class _DrawingScreenState extends State<DrawingScreen> {
  List<DrawingPoint> points = [];
  Color selectedColor = Colors.black;
  double strokeWidth = 4.0;
  DrawMode drawMode = DrawMode.freehand;
  bool isEraserSelected = false;
  Offset? startPoint;
  double totalLength = 0.0;

  // إضافة GlobalKey لالتقاط الرسم
  final GlobalKey _globalKey = GlobalKey();

  // قائمة الألوان المتاحة
  List<Color> colors = [
    Colors.black,
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.brown,
    Colors.grey,
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // اتجاه من اليمين إلى اليسار
      child: Scaffold(
        appBar: AppBar(
          title: Text('ارسم ${widget.shapeInfo.name}'),
        ),
        body: Stack(
          children: [
            // الشكل كخلفية لمساعدة المستخدم
            Positioned.fill(
              child: Opacity(
                opacity: 0.1,
                child: Center(
                  child: ShapeWidget(
                    shapeInfo: widget.shapeInfo,
                    size: MediaQuery.of(context).size.width * 0.8,
                  ),
                ),
              ),
            ),
            // منطقة الرسم
            RepaintBoundary(
              key: _globalKey,
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: GestureDetector(
                  onPanStart: (details) {
                    Offset point = details.localPosition;

                    setState(() {
                      startPoint = point;
                      points.add(DrawingPoint(
                        point: point,
                        paint: Paint()
                          ..color = isEraserSelected
                              ? Colors.transparent
                              : selectedColor
                          ..strokeWidth = strokeWidth
                          ..strokeCap = StrokeCap.round
                          ..blendMode = isEraserSelected
                              ? BlendMode.clear
                              : BlendMode.srcOver,
                        mode: drawMode,
                        isEraser: isEraserSelected,
                      ));
                    });
                  },
                  onPanUpdate: (details) {
                    Offset point = details.localPosition;

                    setState(() {
                      if (drawMode == DrawMode.freehand || isEraserSelected) {
                        points.add(DrawingPoint(
                          point: point,
                          paint: Paint()
                            ..color = isEraserSelected
                                ? Colors.transparent
                                : selectedColor
                            ..strokeWidth = strokeWidth
                            ..strokeCap = StrokeCap.round
                            ..blendMode = isEraserSelected
                                ? BlendMode.clear
                                : BlendMode.srcOver,
                          mode: drawMode,
                          isEraser: isEraserSelected,
                        ));
                      } else {
                        points.removeLast();
                        points.add(DrawingPoint(
                          point: point,
                          paint: Paint()
                            ..color = selectedColor
                            ..strokeWidth = strokeWidth
                            ..strokeCap = StrokeCap.round,
                          mode: drawMode,
                          startPoint: startPoint,
                          isEraser: false,
                        ));
                      }
                    });
                  },
                  onPanEnd: (details) {
                    setState(() {
                      points.add(DrawingPoint(
                        point: Offset.zero,
                        paint: Paint(),
                        mode: drawMode,
                        isEraser: isEraserSelected,
                      ));
                    });
                  },
                  child: CustomPaint(
                    painter: ShapePainter(points: points),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
            // عرض طول الخط المرسوم
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                color: Colors.white70,
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'الطول المرسوم: ${totalLength.toStringAsFixed(2)} سم',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          child: SizedBox(
            height: 80,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // اختيار اللون
                  Row(
                    children: colors
                        .map(
                          (color) => GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedColor = color;
                                isEraserSelected = false;
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.symmetric(horizontal: 5.0),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: color,
                                border: Border.all(
                                    color: Colors.black,
                                    width: selectedColor == color ? 2 : 1),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  // ضبط سمك الخط
                  Row(
                    children: [
                      Icon(Icons.brush),
                      Slider(
                        min: 1.0,
                        max: 10.0,
                        value: strokeWidth,
                        onChanged: (value) {
                          setState(() {
                            strokeWidth = value;
                          });
                        },
                      ),
                    ],
                  ),
                  // اختيار نوع الرسم
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.create),
                        onPressed: () {
                          setState(() {
                            drawMode = DrawMode.freehand;
                          });
                        },
                        tooltip: 'رسم حر',
                        color: drawMode == DrawMode.freehand
                            ? Colors.blue
                            : Colors.black,
                      ),
                      IconButton(
                        icon: Icon(Icons.show_chart),
                        onPressed: () {
                          setState(() {
                            drawMode = DrawMode.line;
                          });
                        },
                        tooltip: 'خط مستقيم',
                        color: drawMode == DrawMode.line
                            ? Colors.blue
                            : Colors.black,
                      ),
                      IconButton(
                        icon: Icon(Icons.crop_square),
                        onPressed: () {
                          setState(() {
                            drawMode = DrawMode.rectangle;
                          });
                        },
                        tooltip: 'مستطيل',
                        color: drawMode == DrawMode.rectangle
                            ? Colors.blue
                            : Colors.black,
                      ),
                      IconButton(
                        icon: Icon(Icons.radio_button_unchecked),
                        onPressed: () {
                          setState(() {
                            drawMode = DrawMode.circle;
                          });
                        },
                        tooltip: 'دائرة',
                        color: drawMode == DrawMode.circle
                            ? Colors.blue
                            : Colors.black,
                      ),
                      // أداة الممحاة
                      IconButton(
                        icon: Icon(isEraserSelected
                            ? Icons.brush
                            : Icons.cleaning_services),
                        onPressed: () {
                          setState(() {
                            isEraserSelected = !isEraserSelected;
                          });
                        },
                        tooltip: isEraserSelected ? 'فرشاة' : 'ممحاة',
                        color: isEraserSelected ? Colors.blue : Colors.black,
                      ),
                      // أداة التراجع
                      IconButton(
                        icon: Icon(Icons.undo),
                        onPressed: () {
                          setState(() {
                            if (points.isNotEmpty) {
                              points.removeLast();
                            }
                          });
                        },
                        tooltip: 'تراجع',
                      ),
                      // أداة المسح
                      IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            points.clear();
                            totalLength = 0.0;
                          });
                        },
                        tooltip: 'مسح',
                      ),
                      // أداة الحفظ
                      IconButton(
                        icon: Icon(Icons.save),
                        onPressed: _saveDrawing,
                        tooltip: 'حفظ',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // دالة لحساب المسافة بين نقطتين وتحويلها إلى سنتيمترات
  double calculateDistance(Offset a, Offset b) {
    double pixelsPerCm =
        MediaQuery.of(context).devicePixelRatio * (96.0 / 2.54);
    double distanceInPixels = sqrt(pow(b.dx - a.dx, 2) + pow(b.dy - a.dy, 2));
    return distanceInPixels / pixelsPerCm;
  }

  // دالة لحفظ الرسم كصورة
  void _saveDrawing() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // حفظ الصورة في معرض الصور (يتطلب أذونات وتطبيق حزم إضافية)
      // مثال باستخدام image_gallery_saver:
      // final result = await ImageGallerySaver.saveImage(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('تم حفظ الرسم بنجاح')),
      );
    } catch (e) {
      print(e);
    }
  }
}

class DrawingPoint {
  Offset point;
  Paint paint;
  DrawMode mode;
  Offset? startPoint;
  bool isEraser;

  DrawingPoint({
    required this.point,
    required this.paint,
    required this.mode,
    this.startPoint,
    this.isEraser = false,
  });
}

class ShapePainter extends CustomPainter {
  List<DrawingPoint> points;

  ShapePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length; i++) {
      DrawingPoint point = points[i];

      if (point.mode == DrawMode.freehand || point.isEraser) {
        if (i < points.length - 1 && points[i + 1].point != Offset.zero) {
          canvas.drawLine(point.point, points[i + 1].point, point.paint);
        }
      } else if (point.mode == DrawMode.line && point.startPoint != null) {
        canvas.drawLine(point.startPoint!, point.point, point.paint);
      } else if (point.mode == DrawMode.rectangle && point.startPoint != null) {
        Rect rect = Rect.fromPoints(point.startPoint!, point.point);
        canvas.drawRect(rect, point.paint);
      } else if (point.mode == DrawMode.circle && point.startPoint != null) {
        double radius = (point.point - point.startPoint!).distance;
        canvas.drawCircle(point.startPoint!, radius, point.paint);
      }
    }
  }

  @override
  bool shouldRepaint(ShapePainter oldDelegate) => true;
}

enum ShapeType {
  polygon,
  rectangle,
  circle,
  rhombus,
  cube,
  rightTriangle,
  oval,
  pyramid,
  cone,
  cylinder,
  curve,
  trapezoid,
  parallelogram,
}

class ShapeWidget extends StatelessWidget {
  final ShapeInfo shapeInfo;
  final double size;

  const ShapeWidget({super.key, required this.shapeInfo, this.size = 100});

  @override
  Widget build(BuildContext context) {
    if (shapeInfo.imagePath != null) {
      return Image.asset(
        shapeInfo.imagePath!,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }
    switch (shapeInfo.shapeType) {
      case ShapeType.polygon:
        return ClipPolygon(
          sides: shapeInfo.sides,
          borderRadius: 8.0,
          rotate: 0.0,
          child: Container(
            color: shapeInfo.color,
            width: size,
            height: size,
          ),
        );
      case ShapeType.rectangle:
        return Container(
          color: shapeInfo.color,
          width: size,
          height: size * 0.6,
        );
      case ShapeType.circle:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: shapeInfo.color,
            shape: BoxShape.circle,
          ),
        );
      case ShapeType.rhombus:
        return Transform.rotate(
          angle: pi / 4,
          child: Container(
            width: size,
            height: size,
            color: shapeInfo.color,
          ),
        );
      case ShapeType.rightTriangle:
        return CustomPaint(
          size: Size(size, size),
          painter: RightTrianglePainter(color: shapeInfo.color),
        );
      case ShapeType.oval:
        return Container(
          width: size * 1.2,
          height: size,
          decoration: BoxDecoration(
            color: shapeInfo.color,
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.all(Radius.elliptical(size * 0.6, size)),
          ),
        );
      case ShapeType.curve:
        return CustomPaint(
          size: Size(size, size),
          painter: CurvePainter(color: shapeInfo.color),
        );
      case ShapeType.trapezoid:
        return ClipPath(
          clipper: TrapezoidClipper(),
          child: Container(
            color: shapeInfo.color,
            width: size,
            height: size * 0.6,
          ),
        );
      case ShapeType.parallelogram:
        return Transform(
          transform: Matrix4.skewX(-0.5),
          child: Container(
            width: size,
            height: size * 0.6,
            color: shapeInfo.color,
          ),
        );
      default:
        // للأشكال ثلاثية الأبعاد أو غير المعرفة، يمكن استخدام صورة توضيحية
        return Container(
          width: size,
          height: size,
          color: Colors.grey[300],
          child: Center(
            child: Text(
              shapeInfo.name,
              textAlign: TextAlign.center,
            ),
          ),
        );
    }
  }
}

class ShapeInfo {
  final String name;
  final int sides;
  final String description;
  final Color color;
  final ShapeType shapeType;
  final String? imagePath;

  ShapeInfo({
    required this.name,
    required this.sides,
    required this.description,
    required this.color,
    required this.shapeType,
    this.imagePath,
  });
}

class RightTrianglePainter extends CustomPainter {
  final Color color;

  RightTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    var path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, 0);
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(RightTrianglePainter oldDelegate) => false;
}

class CurvePainter extends CustomPainter {
  final Color color;

  CurvePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    var path = Path();
    path.moveTo(0, size.height / 2);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height / 2);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CurvePainter oldDelegate) => false;
}

class TrapezoidClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    double cut = size.width / 4;
    Path path = Path();
    path.lineTo(cut, 0);
    path.lineTo(size.width - cut, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(TrapezoidClipper oldClipper) => false;
}
