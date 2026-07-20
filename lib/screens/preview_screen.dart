import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../modules/acquisition/image_acquisition_provider.dart';
import '../modules/enhancement/enhancement_state.dart';
import '../modules/enhancement/image_enhancement_service.dart';
import '../modules/enhancement/crop_overlay_widget.dart';

/// MOD-02 + MOD-03 — Preview Screen
/// Displays the acquired image with full enhancement controls:
/// rotate, crop, brightness, contrast, denoise, perspective (Sprint 3+).
class PreviewScreen extends ConsumerStatefulWidget {
  const PreviewScreen({super.key});

  @override
  ConsumerState<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends ConsumerState<PreviewScreen>
    with SingleTickerProviderStateMixin {
  _ActiveTool _activeTool = _ActiveTool.none;
  late AnimationController _panelController;
  late Animation<double> _panelSlide;

  @override
  void initState() {
    super.initState();
    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _panelSlide = CurvedAnimation(
      parent: _panelController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _panelController.dispose();
    super.dispose();
  }

  void _selectTool(_ActiveTool tool) {
    setState(() {
      if (_activeTool == tool) {
        _activeTool = _ActiveTool.none;
        _panelController.reverse();
      } else {
        _activeTool = tool;
        _panelController.forward();
      }
    });
  }

  Future<void> _onExtract() async {
    final imgState = ref.read(imageAcquisitionProvider);
    final enhState = ref.read(enhancementProvider);
    if (imgState.imagePath == null) return;

    // If no edits, go straight to processing with original
    if (!enhState.anyEdits) {
      if (mounted) context.go(AppRoutes.processing);
      return;
    }

    // Apply enhancements
    ref.read(enhancementProvider.notifier).setProcessing();
    try {
      final processedPath = await ImageEnhancementService.instance.applyEnhancements(
        sourcePath: imgState.imagePath!,
        state: enhState,
      );
      ref.read(enhancementProvider.notifier).setProcessed(processedPath);
      // Update acquisition state to point at enhanced image
      ref.read(imageAcquisitionProvider.notifier)
          .setImage(processedPath, imgState.source ?? ImageSource.gallery);
      if (mounted) context.go(AppRoutes.processing);
    } catch (e) {
      ref.read(enhancementProvider.notifier).setError(e.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1A1F2E),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: const Text('Enhancement failed. Using original image.',
                style: TextStyle(color: AppColors.textPrimaryDark)),
          ),
        );
        context.go(AppRoutes.processing);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imgState = ref.watch(imageAcquisitionProvider);
    final enhState = ref.watch(enhancementProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: _buildAppBar(imgState, enhState),
      body: imgState.hasImage
          ? _buildBody(imgState, enhState)
          : _NoImageBody(onBack: () => context.go(AppRoutes.home)),
      bottomNavigationBar: imgState.hasImage ? _buildBottomBar(enhState) : null,
    );
  }

  PreferredSizeWidget _buildAppBar(
    ImageAcquisitionState imgState,
    EnhancementState enhState,
  ) {
    return AppBar(
      backgroundColor: AppColors.surfaceDark,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded,
            color: AppColors.textPrimaryDark, size: 20),
        onPressed: () {
          ref.read(imageAcquisitionProvider.notifier).clearImage();
          ref.read(enhancementProvider.notifier).resetAll();
          context.go(AppRoutes.home);
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Image Preview',
              style: TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          if (imgState.source != null)
            Text(
              imgState.source == ImageSource.camera ? 'Camera capture' : 'Gallery import',
              style: const TextStyle(color: AppColors.textMutedDark, fontSize: 11),
            ),
        ],
      ),
      actions: [
        if (enhState.anyEdits)
          TextButton(
            key: const Key('btn_reset_enhancements'),
            onPressed: () => ref.read(enhancementProvider.notifier).resetAll(),
            child: const Text('Reset',
                style: TextStyle(color: AppColors.warning, fontSize: 13)),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: TextButton(
            key: const Key('btn_use_original'),
            onPressed: () => context.go(AppRoutes.processing),
            child: const Text('Skip',
                style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ),
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.borderDark),
      ),
    );
  }

  Widget _buildBody(ImageAcquisitionState imgState, EnhancementState enhState) {
    return Column(
      children: [
        // Image area (with optional crop overlay)
        Expanded(
          child: _buildImageArea(imgState.imagePath!, enhState),
        ),
        // Sliding enhancement detail panel
        SizeTransition(
          sizeFactor: _panelSlide,
          axisAlignment: -1,
          child: _buildDetailPanel(enhState),
        ),
        // Tool selector bar
        _buildToolBar(enhState),
      ],
    );
  }

  Widget _buildImageArea(String imagePath, EnhancementState enhState) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderDark),
        color: Colors.black,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Rotated image preview
            Transform.rotate(
              angle: (enhState.rotationDegrees * 3.14159265 / 180),
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_rounded,
                      color: AppColors.textMutedDark, size: 48),
                ),
              ),
            ),
            // Crop overlay (only when crop tool active)
            if (_activeTool == _ActiveTool.crop)
              CropOverlay(
                key: const Key('crop_overlay'),
                initialCrop: enhState.cropRect,
                onCropChanged: (rect) =>
                    ref.read(enhancementProvider.notifier).setCrop(rect),
              ),
            // Processing overlay
            if (enhState.isProcessing)
              Container(
                color: Colors.black54,
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppColors.accent),
                      SizedBox(height: 12),
                      Text('Applying enhancements...',
                          style: TextStyle(
                              color: AppColors.textPrimaryDark, fontSize: 13)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Tool selector bar ─────────────────────────────────────────────────────

  Widget _buildToolBar(EnhancementState enhState) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.borderDark)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ToolButton(
              key: const Key('btn_enhance_rotate'),
              icon: Icons.rotate_right_rounded,
              label: 'Rotate',
              isActive: _activeTool == _ActiveTool.rotate,
              hasEdit: enhState.hasRotation,
              onTap: () => _selectTool(_ActiveTool.rotate),
            ),
            const SizedBox(width: 8),
            _ToolButton(
              key: const Key('btn_enhance_crop'),
              icon: Icons.crop_rounded,
              label: 'Crop',
              isActive: _activeTool == _ActiveTool.crop,
              hasEdit: enhState.hasCrop,
              onTap: () => _selectTool(_ActiveTool.crop),
            ),
            const SizedBox(width: 8),
            _ToolButton(
              key: const Key('btn_enhance_brightness'),
              icon: Icons.brightness_6_rounded,
              label: 'Brightness',
              isActive: _activeTool == _ActiveTool.brightness,
              hasEdit: enhState.brightness != 0.0,
              onTap: () => _selectTool(_ActiveTool.brightness),
            ),
            const SizedBox(width: 8),
            _ToolButton(
              key: const Key('btn_enhance_contrast'),
              icon: Icons.contrast_rounded,
              label: 'Contrast',
              isActive: _activeTool == _ActiveTool.contrast,
              hasEdit: enhState.contrast != 0.0,
              onTap: () => _selectTool(_ActiveTool.contrast),
            ),
            const SizedBox(width: 8),
            _ToolButton(
              key: const Key('btn_enhance_noise'),
              icon: Icons.auto_fix_high_rounded,
              label: 'Denoise',
              isActive: _activeTool == _ActiveTool.denoise,
              hasEdit: enhState.hasNoise,
              onTap: () => _selectTool(_ActiveTool.denoise),
            ),
            const SizedBox(width: 8),
            _AutoEnhanceButton(
              key: const Key('btn_auto_enhance'),
              onTap: () async {
                final imgState = ref.read(imageAcquisitionProvider);
                if (imgState.imagePath == null) return;
                ref.read(enhancementProvider.notifier).setProcessing();
                try {
                  final path = await ImageEnhancementService.instance
                      .autoEnhance(imgState.imagePath!);
                  ref.read(enhancementProvider.notifier).setProcessed(path);
                  ref.read(imageAcquisitionProvider.notifier).setImage(
                        path, imgState.source ?? ImageSource.gallery);
                  if (mounted) setState(() => _activeTool = _ActiveTool.none);
                } catch (e) {
                  ref.read(enhancementProvider.notifier).setError(e.toString());
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Detail panel (slides in per tool) ────────────────────────────────────

  Widget _buildDetailPanel(EnhancementState enhState) {
    return Container(
      color: AppColors.cardDark,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: switch (_activeTool) {
        _ActiveTool.rotate => _RotationPanel(
            value: enhState.rotationDegrees,
            onRotateCW: () =>
                ref.read(enhancementProvider.notifier).rotate90Clockwise(),
            onRotateCCW: () =>
                ref.read(enhancementProvider.notifier).rotate90CounterClockwise(),
            onSlider: (v) =>
                ref.read(enhancementProvider.notifier).setRotation(v),
          ),
        _ActiveTool.crop => _CropPanel(
            hasCrop: enhState.hasCrop,
            onClear: () => ref.read(enhancementProvider.notifier).clearCrop(),
          ),
        _ActiveTool.brightness => _SliderPanel(
            label: 'Brightness',
            icon: Icons.brightness_6_rounded,
            value: enhState.brightness,
            min: -1.0,
            max: 1.0,
            onChanged: (v) =>
                ref.read(enhancementProvider.notifier).setBrightness(v),
          ),
        _ActiveTool.contrast => _SliderPanel(
            label: 'Contrast',
            icon: Icons.contrast_rounded,
            value: enhState.contrast,
            min: -1.0,
            max: 1.0,
            onChanged: (v) =>
                ref.read(enhancementProvider.notifier).setContrast(v),
          ),
        _ActiveTool.denoise => _DenoisePanel(
            value: enhState.noiseReductionRadius,
            onChanged: (v) =>
                ref.read(enhancementProvider.notifier).setNoiseReduction(v),
          ),
        _ActiveTool.none => const SizedBox.shrink(),
      },
    );
  }

  // ── Bottom extract bar ────────────────────────────────────────────────────

  Widget _buildBottomBar(EnhancementState enhState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(top: BorderSide(color: AppColors.borderDark)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          key: const Key('btn_extract_code'),
          onPressed: enhState.isProcessing ? null : _onExtract,
          icon: enhState.isProcessing
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      color: AppColors.backgroundDark, strokeWidth: 2),
                )
              : const Icon(Icons.document_scanner_rounded, size: 18),
          label: Text(enhState.anyEdits ? 'Apply & Extract Code' : 'Extract Code'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.backgroundDark,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle:
                const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

enum _ActiveTool { none, rotate, crop, brightness, contrast, denoise }

// ── Tool button ───────────────────────────────────────────────────────────────

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool hasEdit;
  final VoidCallback onTap;

  const _ToolButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.hasEdit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentGlow : AppColors.cardDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? AppColors.accent
                : hasEdit
                    ? AppColors.accent.withOpacity(0.5)
                    : AppColors.borderDark,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isActive ? AppColors.accent : AppColors.textSecondaryDark,
                size: 20),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(
                        color: isActive
                            ? AppColors.accent
                            : AppColors.textMutedDark,
                        fontSize: 10,
                        fontWeight: FontWeight.w500)),
                if (hasEdit) ...[
                  const SizedBox(width: 4),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoEnhanceButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AutoEnhanceButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: AppColors.accentGradient,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
            SizedBox(height: 4),
            Text('Auto',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ── Detail panels ─────────────────────────────────────────────────────────────

class _RotationPanel extends StatelessWidget {
  final double value;
  final VoidCallback onRotateCW;
  final VoidCallback onRotateCCW;
  final ValueChanged<double> onSlider;

  const _RotationPanel({
    required this.value,
    required this.onRotateCW,
    required this.onRotateCCW,
    required this.onSlider,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.rotate_right_rounded,
                color: AppColors.accent, size: 16),
            const SizedBox(width: 8),
            Text(
              'Rotation: ${value.round()}°',
              style: const TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            _QuickRotateBtn(
              key: const Key('btn_rotate_ccw'),
              icon: Icons.rotate_left_rounded,
              label: '-90°',
              onTap: onRotateCCW,
            ),
            const SizedBox(width: 8),
            _QuickRotateBtn(
              key: const Key('btn_rotate_cw'),
              icon: Icons.rotate_right_rounded,
              label: '+90°',
              onTap: onRotateCW,
            ),
          ],
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.accent,
            thumbColor: AppColors.accent,
            overlayColor: AppColors.accentGlow,
            inactiveTrackColor: AppColors.borderDark,
          ),
          child: Slider(
            key: const Key('slider_rotation'),
            value: value.clamp(-180.0, 180.0),
            min: -180,
            max: 180,
            divisions: 360,
            onChanged: onSlider,
          ),
        ),
      ],
    );
  }
}

class _QuickRotateBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _QuickRotateBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 16),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _CropPanel extends StatelessWidget {
  final bool hasCrop;
  final VoidCallback onClear;
  const _CropPanel({required this.hasCrop, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.crop_rounded, color: AppColors.accent, size: 16),
        const SizedBox(width: 8),
        const Expanded(
          child: Text(
            'Drag the handles on the image to crop',
            style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13),
          ),
        ),
        if (hasCrop)
          TextButton(
            key: const Key('btn_clear_crop'),
            onPressed: onClear,
            child: const Text('Clear',
                style: TextStyle(color: AppColors.warning, fontSize: 12)),
          ),
      ],
    );
  }
}

class _SliderPanel extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _SliderPanel({
    required this.label,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final displayValue = (value * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 16),
            const SizedBox(width: 8),
            Text('$label: ${displayValue > 0 ? "+$displayValue" : "$displayValue"}%',
                style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            const Spacer(),
            if (value != 0.0)
              GestureDetector(
                onTap: () => onChanged(0.0),
                child: const Text('Reset',
                    style: TextStyle(
                        color: AppColors.textMutedDark, fontSize: 12)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.accent,
            thumbColor: AppColors.accent,
            overlayColor: AppColors.accentGlow,
            inactiveTrackColor: AppColors.borderDark,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: 40,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _DenoisePanel extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _DenoisePanel({required this.value, required this.onChanged});

  static const _levels = ['Off', 'Light', 'Medium', 'Strong'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_fix_high_rounded,
                color: AppColors.accent, size: 16),
            const SizedBox(width: 8),
            Text('Noise Reduction: ${_levels[value]}',
                style: const TextStyle(
                    color: AppColors.textPrimaryDark,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: value == i ? AppColors.accentGlow : AppColors.cardDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: value == i ? AppColors.accent : AppColors.borderDark,
                    ),
                  ),
                  child: Text(_levels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: value == i
                              ? AppColors.accent
                              : AppColors.textMutedDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── No image fallback ─────────────────────────────────────────────────────────

class _NoImageBody extends StatelessWidget {
  final VoidCallback onBack;
  const _NoImageBody({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.borderDark),
            ),
            child: const Icon(Icons.image_not_supported_outlined,
                color: AppColors.textMutedDark, size: 36),
          ),
          const SizedBox(height: 20),
          const Text('No image selected',
              style: TextStyle(
                  color: AppColors.textSecondaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          const Text('Go back and capture or import an image.',
              style: TextStyle(color: AppColors.textMutedDark, fontSize: 13)),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            key: const Key('btn_no_image_back'),
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 16),
            label: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}
