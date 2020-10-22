import 'package:flutter/material.dart';

import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';

class SelectScreen extends StatefulWidget {
  SelectScreen(this._image);

  // image to select from
  final Image _image;

  @override
  State<StatefulWidget> createState() => SelectScreenState(_image);
}

class SelectScreenState extends State<SelectScreen> {
  SelectScreenState(this._image);

  // screenshot controllers for the original image and the one you draw over
  final ScreenshotController _initScreenshotController = ScreenshotController();
  final ScreenshotController _ovrlScreenshotController = ScreenshotController();

  // image to select from
  Image _image;

  void _saveSelectedArea() async {
    // take a 'screenshot' of the two imageBodies
    var initUiImage =
        await _initScreenshotController.captureAsUiImage(pixelRatio: 1);
    var ovrlUiImage =
        await _ovrlScreenshotController.captureAsUiImage(pixelRatio: 1);

    // convert ui.Image to img.Image
    var initImage = await _uiImageToImage(initUiImage);
    var ovrlImage = await _uiImageToImage(ovrlUiImage);

    // iterate through every pixel
    var selectImage = img.Image(initImage.width, initImage.height);
    for (int x = 0; x < initImage.width; x++) {
      for (int y = 0; y < initImage.height; y++) {
        // if overlay the same as original, set to white
        if (initImage.getPixel(x, y) == (ovrlImage.getPixel(x, y))) {
          selectImage.setPixelRgba(x, y, 0xff, 0xff, 0xff);
        }
        // if changed (drawn over), set to original pixel
        else {
          selectImage.setPixel(x, y, initImage.getPixel(x, y));
        }
      }
    }

    var selectImageBytesPng = img.encodePng(selectImage);

    // save the image to tempPath/select_img.png
    String tempPath = (await getTemporaryDirectory()).path;
    File file = File('$tempPath/select_img.png');
    await file.writeAsBytes(selectImageBytesPng);
  }

  Future<img.Image> _uiImageToImage(ui.Image uiImage) async {
    // convert ui.Image to img.Image

    ByteData imageByteData =
        await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    Uint8List uiImageBytes = imageByteData.buffer.asUint8List();

    return img.Image.fromBytes(uiImage.width, uiImage.height, uiImageBytes,
        format: img.Format.rgba);
  }

  // TODO: add text & reset button
  // TODO: add loading visualisation when loading image
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Zdrowie the aplikacja")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
                fit: FlexFit.tight,
                child: Stack(
                  children: [
                    // initial image
                    Screenshot(
                      controller: _initScreenshotController,
                      child: Center(child: _image),
                    ),
                    //overlay
                    Opacity(
                        opacity: 0.8,
                        child: Screenshot(
                          controller: _ovrlScreenshotController,
                          child: DrawingOverlay(Center(child: _image)),
                        )),
                  ],
                )),
            ElevatedButton(onPressed: _saveSelectedArea, child: Text("Save")),
            ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("Back"))
          ],
        ),
      ),
    );
  }
}

class DrawingOverlay extends StatefulWidget {
  DrawingOverlay(this._imageBody);

  final Widget _imageBody;
  @override
  State<StatefulWidget> createState() => DrawingOverlayState(_imageBody);
}

class DrawingOverlayState extends State<DrawingOverlay> {
  DrawingOverlayState(this._imageBody);

  final Widget _imageBody;

  // every touched point (a wonky way to do this but i dont care)
  List<Offset> _touchedPoints = [];

  void onPanDown(BuildContext context, DragDownDetails details) {
    final RenderBox box = context.findRenderObject();
    final Offset localOffset = box.globalToLocal(details.globalPosition);
    // update DrawPainter with the touched coords
    setState(() {
      _touchedPoints.add(localOffset);
    });
  }

  void onPanUpdate(BuildContext context, DragUpdateDetails details) {
    final RenderBox box = context.findRenderObject();
    final Offset localOffset = box.globalToLocal(details.globalPosition);
    // update DrawPainter with the touched coords
    setState(() {
      _touchedPoints.add(localOffset);
    });
  }

  Widget build(BuildContext context) {
    return Scaffold(
        body: GestureDetector(
            onPanDown: (DragDownDetails details) => onPanDown(context, details),
            onPanUpdate: (DragUpdateDetails details) =>
                onPanUpdate(context, details),
            child: CustomPaint(
              foregroundPainter: DrawingPainter(_touchedPoints),
              isComplex: true,
              willChange: true,
              child: _imageBody,
            )));
  }
}

class DrawingPainter extends CustomPainter {
  DrawingPainter(this._drawOffsets);

  // every coord to draw a circle on (a wonky way to do this but i dont care)
  List<Offset> _drawOffsets;

  // size of the drawn circle
  final double brushSize = 20;

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint()
      ..color = Color(0xffffffff).withOpacity(1.0)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // draw every circle in drawOffsets
    for (int i = 0; i < _drawOffsets.length; i++) {
      canvas.drawCircle(_drawOffsets[i], brushSize, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
