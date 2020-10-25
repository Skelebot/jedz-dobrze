import 'package:flutter/material.dart';

import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'dart:async';

import 'package:image/image.dart' as img;
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'package:extended_image/extended_image.dart';

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
  ExtendedImage _imageWidget;
  DrawingOverlay drawingOverlay;

  // progress indicator stuff
  bool _isLoading = false;
  int _loadingStackPos = 0;
  String _progressText = '';

  @override
  void initState() {
    super.initState();
    // initialize the imageWidget with the imageFile
    _imageWidget = ExtendedImage.file(widget._imageFile, fit: BoxFit.contain,
        loadStateChanged: (ExtendedImageState state) {
      switch (state.extendedImageLoadState) {
        case LoadState.loading:
          _isLoading = true;
          return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(child: CircularProgressIndicator()),
                Text("Wczytywanie obrazu...",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )),
              ]);
        default:
          _isLoading = false;
          return null;
      }
    });
    // initialize the drawingOverlay with the imageWidget
    drawingOverlay = DrawingOverlay(_imageWidget, _screenshotController);
  }

  void _onResetPress() {
    // check if is loading just in case
    if (!_isLoading) {
      drawingOverlay.resetState();
    }
  }

  void _onSavePress() async {
    // check if is loading just in case
    if (!_isLoading) {
      // update progress indicator
      setState(() {
        _isLoading = true;
        _loadingStackPos = 1;
        _progressText = "Przycinanie zdjęcia...";
      });

      _loadingDialog(context);

      print('cutting the image');
      img.Image cutImageImage = await _cutUnselectedArea();

      // update progress indicator
      setState(() {
        _progressText = "Zapisywanie...";
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
        _isLoading = false;
        _loadingStackPos = 0;
        _progressText = '';
      });
      Navigator.of(context).pop();
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => SummaryScreen(resultPath, widget.data)));
    }
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
      appBar: AppBar(title: Text('Zaznacz składniki'), actions: <Widget>[
        IconButton(
          icon: Icon(Icons.home),
          onPressed: () => {
            // Pop screens until we arrive back at the main screen
            Navigator.popUntil(context, (route) => route.isFirst)
          },
        )
      ]),
      body: Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Stack(children: [
                  Center(child: drawingOverlay),
                  IndexedStack(index: _loadingStackPos, children: [
                    Container(),
                    Center(
                        child: Padding(
                            padding: EdgeInsets.all(10.0),
                            child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: EdgeInsets.all(15.0),
                                    child: CircularProgressIndicator(),
                                  ),
                                  // progress label
                                ]))),
                  ]),
                ]),
              ), // buttons
              Padding(
                  padding: EdgeInsets.all(15.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      RaisedButton(
                          disabledColor: Color(0xfffac800).withOpacity(0.85),
                          onPressed: _isLoading ? null : () => _onResetPress(),
                          child: Text(
                            "Resetuj",
                            style: TextStyle(color: Colors.black),
                          )),
                      Spacer(),
                      RaisedButton(
                          disabledColor: Color(0xfffac800).withOpacity(0.85),
                          onPressed: _isLoading ? null : () => _onSavePress(),
                          child: Text(
                            "Potwierdź",
                            style: TextStyle(color: Colors.black),
                          )),
                    ],
                  ))
            ]),
      ),
    );
  }

  Future _loadingDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                  padding: EdgeInsets.all(15.0),
                  child: CircularProgressIndicator()),
              Text(_progressText)
            ]),
          );
        });
  }
}

class DrawingOverlay extends StatefulWidget {
  DrawingOverlay(
    this._image,
    this.screenshotController,
  );

  final ExtendedImage _image;
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
