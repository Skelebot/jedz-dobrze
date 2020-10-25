import 'package:flutter/material.dart';

import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

import 'package:image/image.dart' as img;
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';

import 'package:flutter/services.dart';

import 'splash.dart';
import 'summary.dart';

class SelectScreen extends StatefulWidget {
  // file containing the selected image
  final File _imageFile;
  final SpreadsheetData data;

  // constructor
  SelectScreen(this._imageFile, this.data);

  @override
  State<StatefulWidget> createState() => SelectScreenState();
}

class SelectScreenState extends State<SelectScreen> {
  // screenshot controllers for the original image and the one you draw over
  final ScreenshotController _screenshotController = ScreenshotController();

  // widget with the image from widget._imageFile
  Image _imageWidget;
  DrawingOverlay drawingOverlay;

  int _loading = 0;
  String _progressLabel = '';

  @override
  void initState() {
    super.initState();
    // initialize the imageWidget with the imageFile
    _imageWidget = Image.file(widget._imageFile);
    // initialize the drawingOverlay with the imageWidget
    drawingOverlay = DrawingOverlay(_imageWidget, _screenshotController);
  }

  void _onResetPress() {
    drawingOverlay.resetState();
  }

  void _onSavePress() async {
    // update progress indicator
    setState(() {
      _loading = 1;
      _progressLabel = "Przycinanie zdjęcia...";
    });
    print('cutting the image');
    img.Image cutImageImage = await _cutUnselectedArea();

    // update progress indicator
    setState(() {
      _progressLabel = "Zapisywanie...";
    });
    await Future.delayed(const Duration(milliseconds: 50));
    print('saving the image');

    // FIXME: encoding and saving to file can be slow for larger photos
    List<int> cutImageBytesPng = img.encodePng(cutImageImage);

    // save the image to tempPath/select_img.png
    String tempPath = (await getTemporaryDirectory()).path;
    File file = File('$tempPath/select_img.png');
    await file.writeAsBytes(cutImageBytesPng);

    String resultPath = '$tempPath/select_img.png';

    // reset progress indicator
    setState(() {
      _loading = 0;
      _progressLabel = '';
    });
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => SummaryScreen(resultPath, widget.data)));
  }

  /// Returns the original image with the unselected bits cut out
  Future<img.Image> _cutUnselectedArea() async {
    // initial image
    Uint8List imageBytes = await widget._imageFile.readAsBytes();
    ui.Image initiImage = await decodeImageFromList(imageBytes);
    img.Image initImageImage = await _uiImageToImageImage(initiImage);
    // here i'm scaling down the image if its getting to big
    // FIXME: TEMPORARY SOLUTION CAUSE IT WAS TOO SLOW
    if (initImageImage.width >= 3000 || initImageImage.height >= 3000) {
      initImageImage = img.copyResize(initImageImage,
          width: (initImageImage.width / 1.5).round(),
          height: (initImageImage.height / 1.5).round());
    }

    // overlay image
    ui.Image ovrlUiImage =
        await _screenshotController.captureAsUiImage(pixelRatio: 1);
    img.Image ovrlImageImage = await _uiImageToImageImage(ovrlUiImage);
    ovrlImageImage = img.copyResize(ovrlImageImage,
        width: initImageImage.width, height: initImageImage.height);

    // cut image
    img.Image cutImageImage =
        img.Image(initImageImage.width, initImageImage.height);

    // iterate through every pixel in the image
    for (int x = 0; x < initImageImage.width; x++) {
      for (int y = 0; y < initImageImage.height; y++) {
        // if the overlay's pixel is white, set cutImage's pixel to initialImage's pixel
        if (ovrlImageImage.getPixel(x, y) == 0xffffffff) {
          cutImageImage.setPixel(x, y, initImageImage.getPixel(x, y));
        }
        // else just set the cut image's pixel as white
        else {
          cutImageImage.setPixel(x, y, 0xffffffff);
        }
      }
    }

    return cutImageImage;
  }

  /// Converts ui.Image to img.Image
  Future<img.Image> _uiImageToImageImage(ui.Image uiImage) async {
    ByteData imageByteData =
        await uiImage.toByteData(format: ui.ImageByteFormat.rawRgba);
    Uint8List uiImageBytes = imageByteData.buffer.asUint8List();

    return img.Image.fromBytes(uiImage.width, uiImage.height, uiImageBytes,
        format: img.Format.rgba);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Zaznacz składniki')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IndexedStack(index: _loading, children: [
              Container(),
              Center(
                  child: Padding(
                      padding: EdgeInsets.all(10.0),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            Text(_progressLabel,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                )),
                          ]))),
            ]),
            // TODO: add a loading image indicator
            Flexible(
              fit: FlexFit.tight,
              child: drawingOverlay,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: _onResetPress, child: Text("Resetuj")),
                ElevatedButton(
                    onPressed: _onSavePress, child: Text("Potwierdź")),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class DrawingOverlay extends StatefulWidget {
  DrawingOverlay(
    this._image,
    this.screenshotController,
  );

  final Image _image;
  final ScreenshotController screenshotController;

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
    return GestureDetector(
        onPanDown: (DragDownDetails details) => _onPanDown(context, details),
        onPanUpdate: (DragUpdateDetails details) =>
            _onPanUpdate(context, details),
        child: Screenshot(
            controller: widget.screenshotController,
            child: CustomPaint(
              foregroundPainter: DrawingPainter(_touchedPoints),
              isComplex: true,
              willChange: true,
              child: widget._image,
            )));
  }
}

class DrawingPainter extends CustomPainter {
  DrawingPainter(this._drawOffsets);

  // every coord to draw a circle on (a wonky way to do this but i dont care)
  List<Offset> _drawOffsets;

  // size of the drawn circle
  final double brushSize = 25;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Color(0xffffffff).withOpacity(1.0)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // draw every circle in drawOffsets
    for (var offset in _drawOffsets) {
      canvas.drawCircle(offset, brushSize, paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
