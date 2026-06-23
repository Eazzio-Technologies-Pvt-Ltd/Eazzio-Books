import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSuccess;
  final AppButtonVariant variant;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSuccess = false,
    this.variant = AppButtonVariant.primary,
    this.width,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.forward();
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null && !widget.isLoading) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEnabled = widget.onPressed != null && !widget.isLoading;

    Color bg;
    Color borderCol;
    Color textCol;
    List<BoxShadow>? shadow;

    switch (widget.variant) {
      case AppButtonVariant.primary:
        bg = isEnabled ? AppColors.primary : AppColors.textHint;
        borderCol = Colors.transparent;
        textCol = Colors.white;
        shadow = isEnabled ? AppShadows.button : null;
        break;
      case AppButtonVariant.secondary:
        bg = AppColors.primary.withOpacity(0.10);
        borderCol = AppColors.primary;
        textCol = AppColors.primary;
        shadow = null;
        break;
      case AppButtonVariant.ghost:
        bg = Colors.transparent;
        borderCol = Colors.transparent;
        textCol = AppColors.textSecondary;
        shadow = null;
        break;
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: isEnabled ? widget.onPressed : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width ?? double.infinity,
          height: 52, // Min height: 52px (thumb-friendly tap target)
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: borderCol != Colors.transparent ? Border.all(color: borderCol, width: 1.5) : null,
            boxShadow: shadow,
          ),
          alignment: Alignment.center,
          child: _buildChild(textCol),
        ),
      ),
    );
  }

  Widget _buildChild(Color textColor) {
    if (widget.isSuccess) {
      return const Icon(
        Icons.check_circle_outline,
        color: Colors.white,
        size: 24,
      );
    }

    if (widget.isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.variant == AppButtonVariant.primary ? Colors.white : AppColors.primary,
          ),
        ),
      );
    }

    return Text(
      widget.text,
      style: AppTextStyles.bodyLarge.copyWith(
        color: textColor,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
