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
  final ScreenshotController _orgScreenshotController = ScreenshotController();
  final ScreenshotController _ovrlScreenshotController = ScreenshotController();

  // image to select from
  Image _image;

  void _saveSelectedArea() async {
    // take a 'screenshot' of the two imageBodies
    var orgUiImage = await _orgScreenshotController.captureAsUiImage();
    var ovrlUiImage = await _ovrlScreenshotController.captureAsUiImage();

    // convert ui.Image to img.Image
    var orgImage = await _uiImageToImage(orgUiImage);
    var ovrlImage = await _uiImageToImage(ovrlUiImage);

    // iterate through every pixel
    var selectImage = img.Image(orgImage.width, orgImage.height);
    for (int x = 0; x < orgImage.width; x++) {
      for (int y = 0; y < orgImage.height; y++) {
        // if overlay the same as original, set to white
        if (orgImage.getPixel(x, y) == ovrlImage.getPixel(x, y)) {
          selectImage.setPixelRgba(x, y, 255, 255, 255, 255);
        }
        // if changed (drawn over), set to original pixel
        else {
          selectImage.setPixel(x, y, orgImage.getPixel(x, y));
        }
      }
    }

    // save the image to tempPath/select_img.rgba (currently img is saved as raw rgba #TODO: antek musisz wymiary jeszcze wziac z tego)
    String tempPath = (await getTemporaryDirectory()).path;
    File file = File('$tempPath/select_img.rgba');
    await file.writeAsBytes(selectImage.data.buffer.asUint8List(
        selectImage.data.offsetInBytes, selectImage.data.lengthInBytes));
  }

  Future<img.Image> _uiImageToImage(ui.Image uiImage) async {
    // convert ui.Image to img.Image

    ByteData imageByteData =
        await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    Uint8List uiImageBytes = imageByteData.buffer.asUint8List();

    return img.Image.fromBytes(uiImage.width, uiImage.height, uiImageBytes,
        format: img.Format.rgba);
  }

  // TODO: add text & reset/send buttons
  // TODO: make it look nice
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Zdrowie the aplikacja")),
      body: Center(
        child: Column(
          children: [
            SizedBox(
                height: 500,
                child: Stack(
                  children: [
                    Screenshot(
                      controller: _orgScreenshotController,
                      child: Center(child: _image),
                    ),
                    Screenshot(
                      controller: _orgScreenshotController,
                      child: DrawingOverlay(Center(child: _image)),
                    ),
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

  // every touched point (really bad way to do this but i dont care)
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
    return Opacity(
      opacity: 0.5,
      child: Scaffold(
          body: GestureDetector(
              onPanDown: (DragDownDetails details) =>
                  onPanDown(context, details),
              onPanUpdate: (DragUpdateDetails details) =>
                  onPanUpdate(context, details),
              child: CustomPaint(
                foregroundPainter: DrawingPainter(_touchedPoints),
                isComplex: true,
                willChange: true,
                child: _imageBody,
              ))),
    );
  }
}

class DrawingPainter extends CustomPainter {
  DrawingPainter(this._drawOffsets);

  // every coord to draw a circle on (really bad way to do this but i dont care)
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
