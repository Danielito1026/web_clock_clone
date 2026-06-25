import 'package:flutter/material.dart';

enum Severity { success, error, warning, info, secondary }

class CustomSnackbar extends StatefulWidget {
  final String title;
  final String message;
  final String details;
  final Severity? severity;
  final Color? snackbarColor;
  final Duration duration;

  const CustomSnackbar({
    super.key,
    required this.title,
    required this.message,
    required this.details,
    this.severity,
    this.snackbarColor,
    this.duration = const Duration(seconds: 3),
  });

  @override
  State<CustomSnackbar> createState() => _CustomSnackbarState();
}

class _CustomSnackbarState extends State<CustomSnackbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ── Severity helpers ──────────────────────────────────────────────────────

  Color _accentColor() {
    switch (widget.severity) {
      case Severity.success:
        return const Color(0xFF4ADE80);
      case Severity.error:
        return const Color(0xFFF87171);
      case Severity.warning:
        return const Color(0xFFFB923C);
      case Severity.info:
        return const Color(0xFF60A5FA);
      case Severity.secondary:
        return const Color(0xFFC084FC);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _icon() {
    switch (widget.severity) {
      case Severity.success:
        return Icons.check_circle_outline_rounded;
      case Severity.error:
        return Icons.error_outline_rounded;
      case Severity.warning:
        return Icons.warning_amber_rounded;
      case Severity.info:
        return Icons.info_outline_rounded;
      case Severity.secondary:
        return Icons.access_time_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _titleColor() {
    switch (widget.severity) {
      case Severity.success:
        return const Color(0xFF16A34A);
      case Severity.error:
        return const Color(0xFFDC2626);
      case Severity.warning:
        return const Color(0xFFD97706);
      case Severity.info:
        return const Color(0xFF2563EB);
      case Severity.secondary:
        return const Color(0xFF9333EA);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _iconBgColor() {
    switch (widget.severity) {
      case Severity.success:
        return const Color(0xFFF0FDF4);
      case Severity.error:
        return const Color(0xFFFEF2F2);
      case Severity.warning:
        return const Color(0xFFFFFBEB);
      case Severity.info:
        return const Color(0xFFEFF6FF);
      case Severity.secondary:
        return const Color(0xFFFAF5FF);
      default:
        return const Color(0xFFF8FAFC);
    }
  }

  Color _borderColor() {
    switch (widget.severity) {
      case Severity.success:
        return const Color(0xFFBBF7D0);
      case Severity.error:
        return const Color(0xFFFECACA);
      case Severity.warning:
        return const Color(0xFFFDE68A);
      case Severity.info:
        return const Color(0xFFBFDBFE);
      case Severity.secondary:
        return const Color(0xFFE9D5FF);
      default:
        return const Color(0xFFE2E8F0);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final accent = widget.snackbarColor ?? _accentColor();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // White card with tinted border
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _borderColor(), width: 1),
                  ),
                ),
              ),

              // Left accent bar
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(width: 4, color: accent),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 14,
                  top: 12,
                  bottom: 16,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon badge
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _iconBgColor(),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(_icon(), size: 15, color: _titleColor()),
                    ),
                    const SizedBox(width: 10),

                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title.toUpperCase(),
                            style: TextStyle(
                              color: _titleColor(),
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.message,
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.details,
                            style: const TextStyle(
                              color: Color.fromARGB(255, 102, 107, 114),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Progress drain bar
              Positioned(
                left: 4,
                right: 0,
                bottom: 0,
                child: Container(
                  height: 2,
                  color: const Color(0xFFF0F0F0),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.0, end: 0.0),
                    duration: widget.duration,
                    builder: (_, value, _) => FractionallySizedBox(
                      widthFactor: value,
                      alignment: Alignment.centerLeft,
                      child: Container(color: accent.withValues(alpha: .7)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
