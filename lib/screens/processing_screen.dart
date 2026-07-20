import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../modules/acquisition/image_acquisition_provider.dart';
import '../modules/ocr/ocr_provider.dart';

/// MOD-04 — Processing Screen
/// Displays OCR scanning animation, live pipeline progress, real-time metrics,
/// and automatically navigates to EditorScreen upon completion.
class ProcessingScreen extends ConsumerStatefulWidget {
  const ProcessingScreen({super.key});

  @override
  ConsumerState<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends ConsumerState<ProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    // Trigger OCR pipeline on screen mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startOcr();
    });
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  void _startOcr() {
    final imgState = ref.read(imageAcquisitionProvider);
    if (imgState.imagePath != null) {
      ref.read(ocrProvider.notifier).runOcrPipeline(imgState.imagePath!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final imgState = ref.watch(imageAcquisitionProvider);
    final ocrState = ref.watch(ocrProvider);

    // Auto navigate when OCR completes
    ref.listen<OcrState>(ocrProvider, (previous, next) {
      if (next.isSuccess && mounted) {
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) context.go(AppRoutes.editor);
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: AppColors.textPrimaryDark, size: 20),
          onPressed: () => context.go(AppRoutes.preview),
        ),
        title: const Text(
          'Extracting Code',
          style: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.borderDark),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image container with scanning laser overlay
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      children: [
                        if (imgState.imagePath != null)
                          Positioned.fill(
                            child: Image.file(
                              File(imgState.imagePath!),
                              fit: BoxFit.contain,
                            ),
                          )
                        else
                          const Center(
                            child: Icon(Icons.document_scanner_rounded,
                                color: AppColors.textMutedDark, size: 48),
                          ),

                        // Scanning Laser Effect
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: _scanAnimation.value *
                                  (MediaQuery.of(context).size.height * 0.4),
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent.withOpacity(0.8),
                                      blurRadius: 12,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Progress & Status section
              _buildProgressSection(ocrState),

              const SizedBox(height: 20),

              // Metrics Card (Timing & Confidence)
              if (ocrState.isSuccess) _buildMetricsCard(ocrState),

              if (ocrState.status == OcrStatus.error) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _startOcr,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry Extraction'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.backgroundDark,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSection(OcrState ocrState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ocrState.currentStepMessage,
                style: const TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(ocrState.progress * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: ocrState.progress,
              backgroundColor: AppColors.cardDark,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCard(OcrState ocrState) {
    final result = ocrState.rawResult!;
    final confidencePct = (result.averageConfidence * 100).round();
    final timeMs = result.processingTime.inMilliseconds;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _MetricTile(
            icon: Icons.text_snippet_outlined,
            value: '${result.rawText.length}',
            label: 'Chars',
          ),
          Container(width: 1, height: 28, color: AppColors.borderDark),
          _MetricTile(
            icon: Icons.speed_rounded,
            value: '${timeMs}ms',
            label: 'Time',
          ),
          Container(width: 1, height: 28, color: AppColors.borderDark),
          _MetricTile(
            icon: Icons.verified_rounded,
            value: '$confidencePct%',
            label: 'Confidence',
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetricTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.accent),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.textPrimaryDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMutedDark,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
