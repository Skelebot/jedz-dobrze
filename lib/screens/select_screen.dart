import 'package:flutter/material.dart';
import 'package:jedzdobrze/screens/splash_screen.dart';
import 'package:jedzdobrze/screens/summary_screen.dart';

import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';

import 'dart:async';
import 'package:flutter/services.dart';

class SelectScreen extends StatefulWidget {
  // image to select from
  final Image _image;
  final SpreadsheetData data;

  // constructor
  SelectScreen(this._image, this.data);

  @override
  State<StatefulWidget> createState() => SelectScreenState(_image, data);
}

class SelectScreenState extends State<SelectScreen> {
  // image to select from
  final Image _image;
  // data
  final SpreadsheetData data;

  // constructor
  SelectScreenState(this._image, this.data);

  // screenshot controllers for the original image and the one you draw over
  final ScreenshotController _initScreenshotController = ScreenshotController();
  final ScreenshotController _ovrlScreenshotController = ScreenshotController();

  DrawingOverlay drawingOverlay;

  @override
  void initState() {
    super.initState();
    drawingOverlay = DrawingOverlay(Center(child: _image));
  }

  void _resetDrawingOverlay() {
    drawingOverlay.resetState();
  }

  void _saveAndExtractIngredients() async {
    // take a 'screenshot' of the two imageBodies
    ui.Image initUiImage =
        await _initScreenshotController.captureAsUiImage(pixelRatio: 1);
    ui.Image ovrlUiImage =
        await _ovrlScreenshotController.captureAsUiImage(pixelRatio: 1);

    // convert ui.Image to img.Image
    img.Image initImage = await _uiImageToImage(initUiImage);
    img.Image ovrlImage = await _uiImageToImage(ovrlUiImage);

    // iterate through every pixel
    img.Image selectImage = img.Image(initImage.width, initImage.height);
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

    List<int> selectImageBytesPng = img.encodePng(selectImage);

    // save the image to tempPath/select_img.png
    String tempPath = (await getTemporaryDirectory()).path;
    File file = File('$tempPath/select_img.png');
    await file.writeAsBytes(selectImageBytesPng);

    String resultPath = '$tempPath/select_img.png';

    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => SummaryScreen(resultPath, data)));
  }

  /// Converts ui.Image to img.Image
  Future<img.Image> _uiImageToImage(ui.Image uiImage) async {
    ByteData imageByteData =
        await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    Uint8List uiImageBytes = imageByteData.buffer.asUint8List();

    return img.Image.fromBytes(uiImage.width, uiImage.height, uiImageBytes,
        format: img.Format.rgba);
  }

  // TODO: add loading visualisation when loading image
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Zaznacz składniki')),
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
                          child: drawingOverlay,
                        )),
                  ],
                )),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: _resetDrawingOverlay, child: Text("Resetuj")),
                ElevatedButton(
                    onPressed: _saveAndExtractIngredients,
                    child: Text("Potwierdź")),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class DrawingOverlay extends StatefulWidget {
  DrawingOverlay(this._imageBody);

  final Widget _imageBody;

  final DrawingOverlayState state = DrawingOverlayState();

  void resetState() {
    state.reset();
  }

  @override
  State<StatefulWidget> createState() => state;
}

class DrawingOverlayState extends State<DrawingOverlay> {
  // every touched point (a wonky way to do this but i dont care)
  List<Offset> _touchedPoints = [];

  void reset() {
    setState(() {
      _touchedPoints = [];
    });
  }

  void _onPanDown(BuildContext context, DragDownDetails details) {
    final RenderBox box = context.findRenderObject();
    final Offset localOffset = box.globalToLocal(details.globalPosition);
    // update DrawPainter with the touched coords
    setState(() {
      _touchedPoints.add(localOffset);
    });
  }

  void _onPanUpdate(BuildContext context, DragUpdateDetails details) {
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
            onPanDown: (DragDownDetails details) =>
                _onPanDown(context, details),
            onPanUpdate: (DragUpdateDetails details) =>
                _onPanUpdate(context, details),
            child: CustomPaint(
              foregroundPainter: DrawingPainter(_touchedPoints),
              isComplex: true,
              willChange: true,
              child: widget._imageBody,
            )));
  }
}

class DrawingPainter extends CustomPainter {
  DrawingPainter(this._drawOffsets);

  // every coord to draw a circle on (a wonky way to do this but i dont care)
  List<Offset> _drawOffsets;

  // size of the drawn circle
  final double brushSize = 15;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
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
