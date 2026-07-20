import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';
import '../modules/acquisition/image_acquisition_service.dart';
import '../modules/acquisition/image_acquisition_provider.dart';

/// MOD-01 / MOD-02 — Home Screen
/// Entry point with real camera + gallery acquisition wired up.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onScanCode() async {
    ref.read(imageAcquisitionProvider.notifier).setLoading();
    final result = await ImageAcquisitionService.instance.captureFromCamera(context);
    if (!mounted) return;

    if (result.isSuccess) {
      ref.read(imageAcquisitionProvider.notifier)
          .setImage(result.imagePath!, result.source!);
      context.go(AppRoutes.preview);
    } else if (result.status == AcquisitionStatus.error) {
      ref.read(imageAcquisitionProvider.notifier)
          .setError(result.errorMessage ?? 'Unknown error');
      _showError(result.errorMessage ?? 'Failed to capture image.');
    } else {
      ref.read(imageAcquisitionProvider.notifier).clearImage();
    }
  }

  Future<void> _onImportImage() async {
    ref.read(imageAcquisitionProvider.notifier).setLoading();
    final result = await ImageAcquisitionService.instance.importFromGallery(context);
    if (!mounted) return;

    if (result.isSuccess) {
      ref.read(imageAcquisitionProvider.notifier)
          .setImage(result.imagePath!, result.source!);
      context.go(AppRoutes.preview);
    } else if (result.status == AcquisitionStatus.error) {
      ref.read(imageAcquisitionProvider.notifier)
          .setError(result.errorMessage ?? 'Unknown error');
      _showError(result.errorMessage ?? 'Failed to import image.');
    } else {
      ref.read(imageAcquisitionProvider.notifier).clearImage();
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1A1F2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Text(message,
            style: const TextStyle(color: AppColors.textPrimaryDark)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imgState = ref.watch(imageAcquisitionProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Stack(
        children: [
          // Background gradient
          Container(decoration: const BoxDecoration(gradient: AppColors.heroGradientDark)),
          // Radial glow
          Positioned(
            top: -80, left: -80, right: -80,
            child: Container(
              height: 400,
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  colors: [AppColors.accentGlow, Colors.transparent],
                  radius: 0.7,
                ),
              ),
            ),
          ),
          // Loading overlay
          if (imgState.isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppColors.accent),
                    SizedBox(height: 16),
                    Text(
                      'Preparing image...',
                      style: TextStyle(color: AppColors.textPrimaryDark, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          // Main content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    _buildAppBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 48),
                            _buildHeroSection(),
                            const SizedBox(height: 48),
                            _buildActionCards(imgState.isLoading),
                            const SizedBox(height: 32),
                            _buildPrivacyBadge(),
                            const SizedBox(height: 32),
                            _buildFeatureRow(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.code_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'SecureCode OCR',
                style: TextStyle(
                  color: AppColors.textPrimaryDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          _ThemeToggleButton(),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PrivacyPill(),
        SizedBox(height: 20),
        Text(
          'Extract Code\nFrom Any Image',
          style: TextStyle(
            color: AppColors.textPrimaryDark,
            fontSize: 38,
            fontWeight: FontWeight.w800,
            height: 1.15,
            letterSpacing: -1.0,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Capture or import a screenshot — get clean, editable source code in seconds. No cloud. No risk.',
          style: TextStyle(
            color: AppColors.textSecondaryDark,
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildActionCards(bool loading) {
    return Column(
      children: [
        _ActionCard(
          id: 'btn_scan_code',
          icon: Icons.camera_alt_rounded,
          label: 'Scan Code',
          subtitle: 'Capture with camera',
          gradient: AppColors.accentGradient,
          isPrimary: true,
          loading: loading,
          onTap: _onScanCode,
        ),
        const SizedBox(height: 12),
        _ActionCard(
          id: 'btn_import_image',
          icon: Icons.photo_library_rounded,
          label: 'Import Image',
          subtitle: 'Choose from gallery',
          gradient: const LinearGradient(
              colors: [Color(0xFF1A1F2E), Color(0xFF222840)]),
          isPrimary: false,
          loading: loading,
          onTap: _onImportImage,
        ),
      ],
    );
  }

  Widget _buildPrivacyBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.successGlow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline_rounded, size: 16, color: AppColors.success),
          SizedBox(width: 10),
          Text(
            AppConstants.privacyBadge,
            style: TextStyle(
              color: AppColors.success,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow() {
    return const Row(
      children: [
        Expanded(child: _FeatureChip(icon: Icons.offline_bolt_rounded, label: 'Works Offline')),
        SizedBox(width: 8),
        Expanded(child: _FeatureChip(icon: Icons.translate_rounded, label: '10+ Languages')),
        SizedBox(width: 8),
        Expanded(child: _FeatureChip(icon: Icons.edit_note_rounded, label: 'Built-in Editor')),
      ],
    );
  }
}

// ── Internal reusable widgets ─────────────────────────────────────────────────

class _PrivacyPill extends StatelessWidget {
  const _PrivacyPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accentGlow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_rounded, size: 14, color: AppColors.accent),
          SizedBox(width: 6),
          Text(
            'Privacy First · Offline by Default',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatefulWidget {
  final String id;
  final IconData icon;
  final String label;
  final String subtitle;
  final LinearGradient gradient;
  final bool isPrimary;
  final bool loading;
  final VoidCallback onTap;

  const _ActionCard({
    required this.id,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.isPrimary,
    required this.loading,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _pressCtrl,
      child: GestureDetector(
        key: Key(widget.id),
        onTapDown: widget.loading ? null : (_) => _pressCtrl.reverse(),
        onTapUp: widget.loading
            ? null
            : (_) {
                _pressCtrl.forward();
                widget.onTap();
              },
        onTapCancel: () => _pressCtrl.forward(),
        child: Opacity(
          opacity: widget.loading ? 0.6 : 1.0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(16),
              border: widget.isPrimary
                  ? null
                  : Border.all(color: AppColors.borderDark),
              boxShadow: widget.isPrimary
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withOpacity(0.25),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      )
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: widget.isPrimary
                          ? Colors.white.withOpacity(0.2)
                          : AppColors.accentGlow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.isPrimary ? Colors.white : AppColors.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.label,
                            style: TextStyle(
                              color: widget.isPrimary
                                  ? Colors.white
                                  : AppColors.textPrimaryDark,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            )),
                        const SizedBox(height: 2),
                        Text(widget.subtitle,
                            style: TextStyle(
                              color: widget.isPrimary
                                  ? Colors.white.withOpacity(0.75)
                                  : AppColors.textSecondaryDark,
                              fontSize: 13,
                            )),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: widget.isPrimary
                        ? Colors.white.withOpacity(0.75)
                        : AppColors.textMutedDark,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accent, size: 22),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondaryDark,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                height: 1.3,
              )),
        ],
      ),
    );
  }
}

class _ThemeToggleButton extends StatefulWidget {
  @override
  State<_ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<_ThemeToggleButton> {
  bool _isDark = true;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const Key('btn_theme_toggle'),
      onTap: () => setState(() => _isDark = !_isDark),
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderDark),
        ),
        child: Icon(
          _isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: AppColors.textSecondaryDark,
          size: 18,
        ),
      ),
    );
  }
}
