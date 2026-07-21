import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import 'enhancement_state.dart';

/// MOD-03 — Crop Overlay Widget
/// Interactive drag-handle cropping tool overlaid on the image preview.
/// Outputs a normalized [CropRect] (0.0–1.0) relative strictly to actual image pixels.
class CropOverlay extends StatefulWidget {
  /// Called whenever the user adjusts the crop handles
  final ValueChanged<CropRect> onCropChanged;

  /// Initial crop rectangle (or full image if null)
  final CropRect? initialCrop;

  /// Dimensions of the underlying image file
  final Size? imageSize;

  const CropOverlay({
    super.key,
    required this.onCropChanged,
    this.initialCrop,
    this.imageSize,
  });

  @override
  State<CropOverlay> createState() => _CropOverlayState();
}

class _CropOverlayState extends State<CropOverlay> {
  // Normalized positions (0.0–1.0 relative to actual image pixels)
  double _left = 0.05;
  double _top = 0.05;
  double _right = 0.95;
  double _bottom = 0.95;

  static const double _handleSize = 24.0;
  static const double _minSize = 0.05;

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
        final containerW = constraints.maxWidth;
        final containerH = constraints.maxHeight;

        double renderW = containerW;
        double renderH = containerH;
        double offsetX = 0.0;
        double offsetY = 0.0;

        if (widget.imageSize != null &&
            widget.imageSize!.width > 0 &&
            widget.imageSize!.height > 0) {
          final fitted = applyBoxFit(
            BoxFit.contain,
            widget.imageSize!,
            Size(containerW, containerH),
          );
          renderW = fitted.destination.width;
          renderH = fitted.destination.height;
          offsetX = (containerW - renderW) / 2;
          offsetY = (containerH - renderH) / 2;
        }

        // Convert normalized image coordinates (0.0–1.0) to screen pixel positions
        final pxLeft = offsetX + (_left * renderW);
        final pxTop = offsetY + (_top * renderH);
        final pxRight = offsetX + (_right * renderW);
        final pxBottom = offsetY + (_bottom * renderH);
        final cropW = (pxRight - pxLeft).clamp(0.0, renderW);
        final cropH = (pxBottom - pxTop).clamp(0.0, renderH);

        return Stack(
          children: [
            // Darkened outside regions (including letterbox area)
            _buildDimOverlay(pxLeft, pxTop, pxRight, pxBottom, containerW, containerH),

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
                _DragHandle.topLeft, renderW, renderH),
            _buildHandle(pxRight - _handleSize / 2, pxTop - _handleSize / 2,
                _DragHandle.topRight, renderW, renderH),
            _buildHandle(pxLeft - _handleSize / 2, pxBottom - _handleSize / 2,
                _DragHandle.bottomLeft, renderW, renderH),
            _buildHandle(pxRight - _handleSize / 2, pxBottom - _handleSize / 2,
                _DragHandle.bottomRight, renderW, renderH),

            // Edge handles
            _buildHandle(pxLeft + cropW / 2 - _handleSize / 2,
                pxTop - _handleSize / 2, _DragHandle.top, renderW, renderH),
            _buildHandle(pxLeft + cropW / 2 - _handleSize / 2,
                pxBottom - _handleSize / 2, _DragHandle.bottom, renderW, renderH),
            _buildHandle(pxLeft - _handleSize / 2,
                pxTop + cropH / 2 - _handleSize / 2, _DragHandle.left, renderW, renderH),
            _buildHandle(pxRight - _handleSize / 2,
                pxTop + cropH / 2 - _handleSize / 2, _DragHandle.right, renderW, renderH),
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
      double x, double y, _DragHandle handle, double renderW, double renderH) {
    return Positioned(
      left: x,
      top: y,
      child: GestureDetector(
        onPanUpdate: (details) => _onHandleDrag(details.delta, handle, renderW, renderH),
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

  void _onHandleDrag(Offset delta, _DragHandle handle, double renderW, double renderH) {
    final dx = delta.dx / (renderW > 0 ? renderW : 1.0);
    final dy = delta.dy / (renderH > 0 ? renderH : 1.0);

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
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, top.clamp(0.0, size.height)), paint);
    // Bottom band
    canvas.drawRect(Rect.fromLTWH(0, bottom.clamp(0.0, size.height), size.width, (size.height - bottom).clamp(0.0, size.height)), paint);
    // Left band
    canvas.drawRect(Rect.fromLTWH(0, top.clamp(0.0, size.height), left.clamp(0.0, size.width), (bottom - top).clamp(0.0, size.height)), paint);
    // Right band
    canvas.drawRect(Rect.fromLTWH(right.clamp(0.0, size.width), top.clamp(0.0, size.height), (size.width - right).clamp(0.0, size.width), (bottom - top).clamp(0.0, size.height)), paint);
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
