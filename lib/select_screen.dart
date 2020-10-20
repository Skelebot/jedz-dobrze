import 'package:flutter/material.dart';
import 'dart:ui';

class SelectScreen extends StatefulWidget {
  SelectScreen(this.image);

  // image to select from
  final Image image;

  @override
  State<StatefulWidget> createState() => SelectScreenState(image);
}

class SelectScreenState extends State<SelectScreen> {
  SelectScreenState(this.image);

  // image to select from
  Image image;

  // TODO: add text & reset/send buttons
  @override
  Widget build(BuildContext context) {
    // this is copied into the DrawingOverlay
    Widget imageBody = Center(
        child: Column(children: <Widget>[
      image,
    ]));

    return Stack(
      children: [
        Scaffold(
          body: imageBody,
        ),
        DrawingOverlay(imageBody),
      ],
    );
  }
}

class DrawingOverlay extends StatefulWidget {
  DrawingOverlay(this.imageBody);

  final Widget imageBody;
  @override
  State<StatefulWidget> createState() => DrawingOverlayState(imageBody);
}

// TODO: add getting image from canvas
class DrawingOverlayState extends State<DrawingOverlay> {
  DrawingOverlayState(this.imageBody);

  final Widget imageBody;

  List<Offset> touchedPoints = [];

  void onPanDown(BuildContext context, DragDownDetails details) {
    final RenderBox box = context.findRenderObject();
    final Offset localOffset = box.globalToLocal(details.globalPosition);
    setState(() {
      touchedPoints.add(localOffset);
    });
  }

  void onPanUpdate(BuildContext context, DragUpdateDetails details) {
    final RenderBox box = context.findRenderObject();
    final Offset localOffset = box.globalToLocal(details.globalPosition);
    setState(() {
      touchedPoints.add(localOffset);
    });
  }

  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5,
      child: Scaffold(
          body: GestureDetector(
              onPanDown: (DragDownDetails details) =>
                  onPanDown(context, details),
              onPanUpdate: (DragUpdateDetails details) =>
                  onPanUpdate(context, details),
              child: CustomPaint(
                foregroundPainter: DrawPainter(touchedPoints),
                isComplex: true,
                willChange: true,
                child: imageBody,
              ))),
    );
  }
}

class DrawPainter extends CustomPainter {
  DrawPainter(this.drawOffsets);

  List<Offset> drawOffsets;

  // size of the drawn circle
  final double brushSize = 30;

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Color(0xffffffff).withOpacity(1.0)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // draw every circle in drawOffsets
    for (int i = 0; i < drawOffsets.length; i++) {
      canvas.drawCircle(drawOffsets[i], brushSize, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
