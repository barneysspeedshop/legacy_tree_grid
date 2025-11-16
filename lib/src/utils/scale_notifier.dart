// lib/providers/scale_notifier.dart
import 'package:flutter/material.dart';

class ScaleNotifier extends ChangeNotifier {
  double _scale = 1.0;
  static const double _minScale = 0.5;
  static const double _maxScale = 2.0; // Adjust max scale as needed
  static const double _scaleIncrement = 0.1;

  double get scale => _scale;

  void updateScale(double newScale) {
    _scale = newScale.clamp(_minScale, _maxScale);
    notifyListeners();
  }

  void zoomIn() {
    if (_scale < _maxScale) {
      _scale = (_scale + _scaleIncrement).clamp(_minScale, _maxScale);
      notifyListeners();
    }
  }

  void zoomOut() {
    if (_scale > _minScale) {
      _scale = (_scale - _scaleIncrement).clamp(_minScale, _maxScale);
      notifyListeners();
    }
  }

  void resetZoom() {
    _scale = 1.0;
    notifyListeners();
  }
}

class ZoomInIntent extends Intent {}

class ZoomOutIntent extends Intent {}

class ResetZoomIntent extends Intent {}
