import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'enhancement_state.dart';

/// MOD-03 — Crop Overlay Widget
/// Interactive drag-handle cropping tool overlaid on the image preview.
/// Outputs a normalized [CropRect] (0.0–1.0) relative to image dimensions.
class CropOverlay extends StatefulWidget {
  /// Called whenever the user adjusts the crop handles
  final ValueChanged<CropRect> onCropChanged;

  /// Initial crop rectangle (or full image if null)
  final CropRect? initialCrop;

  const CropOverlay({
    super.key,
    required this.onCropChanged,
    this.initialCrop,
  });

  @override
  State<CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<CropOverlay> {
  // Normalized positions (0.0–1.0)
  double _left = 0.1;
  double _top = 0.1;
  double _right = 0.9;
  double _bottom = 0.9;

  static const double _handleSize = 24.0;
  static const double _minSize = 0.1;

  @override
  void initState() {
    super.initState();
    if (widget.initialCrop != null) {
      _left = widget.initialCrop!.left;
      _top = widget.initialCrop!.top;
      _right = widget.initialCrop!.right;
      _bottom = widget.initialCrop!.bottom;
    }
  }

  void _notify() {
    widget.onCropChanged(CropRect(
      left: _left,
      top: _top,
      right: _right,
      bottom: _bottom,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        // Convert normalized to pixel positions
        final pxLeft = _left * w;
        final pxTop = _top * h;
        final pxRight = _right * w;
        final pxBottom = _bottom * h;
        final cropW = pxRight - pxLeft;
        final cropH = pxBottom - pxTop;

        return Stack(
          children: [
            // Darkened outside regions
            _buildDimOverlay(pxLeft, pxTop, pxRight, pxBottom, w, h),

            // Crop border + grid lines
            Positioned(
              left: pxLeft,
              top: pxTop,
              width: cropW,
              height: cropH,
              child: _CropBorderPainter(width: cropW, height: cropH),
            ),

            // Corner handles
            _buildHandle(pxLeft - _handleSize / 2, pxTop - _handleSize / 2,
                _DragHandle.topLeft, w, h),
            _buildHandle(pxRight - _handleSize / 2, pxTop - _handleSize / 2,
                _DragHandle.topRight, w, h),
            _buildHandle(pxLeft - _handleSize / 2, pxBottom - _handleSize / 2,
                _DragHandle.bottomLeft, w, h),
            _buildHandle(pxRight - _handleSize / 2, pxBottom - _handleSize / 2,
                _DragHandle.bottomRight, w, h),

            // Edge handles
            _buildHandle(pxLeft + cropW / 2 - _handleSize / 2,
                pxTop - _handleSize / 2, _DragHandle.top, w, h),
            _buildHandle(pxLeft + cropW / 2 - _handleSize / 2,
                pxBottom - _handleSize / 2, _DragHandle.bottom, w, h),
            _buildHandle(pxLeft - _handleSize / 2,
                pxTop + cropH / 2 - _handleSize / 2, _DragHandle.left, w, h),
            _buildHandle(pxRight - _handleSize / 2,
                pxTop + cropH / 2 - _handleSize / 2, _DragHandle.right, w, h),
          ],
        );
      },
    );
  }

  Widget _buildDimOverlay(
      double l, double t, double r, double b, double w, double h) {
    return CustomPaint(
      size: Size(w, h),
      painter: _DimOverlayPainter(left: l, top: t, right: r, bottom: b),
    );
  }

  Widget _buildHandle(
      double x, double y, _DragHandle handle, double w, double h) {
    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onPanUpdate: (details) => _onHandleDrag(details.delta, handle, w, h),
        child: Container(
          width: _handleSize,
          height: _handleSize,
          decoration: BoxDecoration(
            color: AppColors.accent,
            shape: handle.isCorner ? BoxShape.rectangle : BoxShape.circle,
            borderRadius: handle.isCorner ? BorderRadius.circular(4) : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withOpacity(0.4),
                blurRadius: 8,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onHandleDrag(Offset delta, _DragHandle handle, double w, double h) {
    final dx = delta.dx / w;
    final dy = delta.dy / h;

    setState(() {
      switch (handle) {
        case _DragHandle.topLeft:
          _left = (_left + dx).clamp(0.0, _right - _minSize);
          _top = (_top + dy).clamp(0.0, _bottom - _minSize);
        case _DragHandle.topRight:
          _right = (_right + dx).clamp(_left + _minSize, 1.0);
          _top = (_top + dy).clamp(0.0, _bottom - _minSize);
        case _DragHandle.bottomLeft:
          _left = (_left + dx).clamp(0.0, _right - _minSize);
          _bottom = (_bottom + dy).clamp(_top + _minSize, 1.0);
        case _DragHandle.bottomRight:
          _right = (_right + dx).clamp(_left + _minSize, 1.0);
          _bottom = (_bottom + dy).clamp(_top + _minSize, 1.0);
        case _DragHandle.top:
          _top = (_top + dy).clamp(0.0, _bottom - _minSize);
        case _DragHandle.bottom:
          _bottom = (_bottom + dy).clamp(_top + _minSize, 1.0);
        case _DragHandle.left:
          _left = (_left + dx).clamp(0.0, _right - _minSize);
        case _DragHandle.right:
          _right = (_right + dx).clamp(_left + _minSize, 1.0);
      }
    });
    _notify();
  }
}

enum _DragHandle {
  topLeft, topRight, bottomLeft, bottomRight,
  top, bottom, left, right;

  bool get isCorner => this == topLeft || this == topRight ||
      this == bottomLeft || this == bottomRight;
}

// ── Custom painters ───────────────────────────────────────────────────────────

class _DimOverlayPainter extends CustomPainter {
  final double left, top, right, bottom;
  _DimOverlayPainter({
    required this.left, required this.top,
    required this.right, required this.bottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.55);
    // Top band
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top), paint);
    // Bottom band
    canvas.drawRect(Rect.fromLTWH(0, bottom, size.width, size.height - bottom), paint);
    // Left band
    canvas.drawRect(Rect.fromLTWH(0, top, left, bottom - top), paint);
    // Right band
    canvas.drawRect(Rect.fromLTWH(right, top, size.width - right, bottom - top), paint);
  }

  @override
  bool shouldRepaint(_DimOverlayPainter old) =>
      old.left != left || old.top != top || old.right != right || old.bottom != bottom;
}

class _CropBorderPainter extends StatelessWidget {
  final double width;
  final double height;
  const _CropBorderPainter({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _GridPainter(),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = AppColors.accent.withOpacity(0.35)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    // Border
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), borderPaint);

    // Rule-of-thirds grid
    final thirdW = size.width / 3;
    final thirdH = size.height / 3;
    canvas.drawLine(Offset(thirdW, 0), Offset(thirdW, size.height), gridPaint);
    canvas.drawLine(Offset(thirdW * 2, 0), Offset(thirdW * 2, size.height), gridPaint);
    canvas.drawLine(Offset(0, thirdH), Offset(size.width, thirdH), gridPaint);
    canvas.drawLine(Offset(0, thirdH * 2), Offset(size.width, thirdH * 2), gridPaint);
  }

  @override
  bool shouldRepaint(_GridPainter old) => false;
}
