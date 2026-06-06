import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';

/// Button variants following Academic Pulse design system
enum AppButtonVariant {
  primary, // Gradient primary button (main CTAs)
  secondary, // Surface-based secondary button
  outline, // Ghost border outline button
  text, // Text-only button
}

/// Custom button widget following Academic Pulse design system
/// Features:
/// - Primary gradient (primary → primary-container)
/// - No harsh borders, uses surface shifts
/// - Proper loading states
/// - Icon support
class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  final bool iconRight;
  final double? width;
  final double? height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.iconRight = false,
    this.width,
    this.height,
  });

  /// Primary button with gradient (main CTAs)
  const AppButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.iconRight = false,
    this.width,
    this.height,
  }) : variant = AppButtonVariant.primary;

  /// Secondary button with surface color
  const AppButton.secondary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.iconRight = false,
    this.width,
    this.height,
  }) : variant = AppButtonVariant.secondary;

  /// Outline button with ghost border
  const AppButton.outline({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.iconRight = false,
    this.width,
    this.height,
  }) : variant = AppButtonVariant.outline;

  /// Text-only button
  const AppButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
    this.iconRight = false,
    this.width,
    this.height,
  }) : variant = AppButtonVariant.text;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;

    return SizedBox(
      width: isFullWidth ? double.infinity : width,
      height: height ?? AppDimensions.buttonHeightMd,
      child: AnimatedOpacity(
        opacity: isDisabled ? 0.5 : 1.0,
        duration: const Duration(milliseconds: AppDimensions.animationFast),
        child: _buildButton(context),
      ),
    );
  }

  Widget _buildButton(BuildContext context) {
    switch (variant) {
      case AppButtonVariant.primary:
        return _buildPrimaryButton(context);
      case AppButtonVariant.secondary:
        return _buildSecondaryButton(context);
      case AppButtonVariant.outline:
        return _buildOutlineButton(context);
      case AppButtonVariant.text:
        return _buildTextButton(context);
    }
  }

  /// Primary button with gradient background
  Widget _buildPrimaryButton(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowPrimary,
            offset: const Offset(0, 8),
            blurRadius: AppDimensions.elevation3,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing6,
              vertical: AppDimensions.spacing4,
            ),
            child: _buildButtonContent(
              textColor: AppColors.onPrimary,
              iconColor: AppColors.onPrimary,
            ),
          ),
        ),
      ),
    );
  }

  /// Secondary button with surface background
  Widget _buildSecondaryButton(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing6,
            vertical: AppDimensions.spacing4,
          ),
          child: _buildButtonContent(
            textColor: AppColors.primary,
            iconColor: AppColors.primary,
          ),
        ),
      ),
    );
  }

  /// Outline button with ghost border
  Widget _buildOutlineButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.15),
          width: AppDimensions.ghostBorderWidth,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing6,
              vertical: AppDimensions.spacing4,
            ),
            child: _buildButtonContent(
              textColor: AppColors.primary,
              iconColor: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }

  /// Text-only button
  Widget _buildTextButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing4,
            vertical: AppDimensions.spacing3,
          ),
          child: _buildButtonContent(
            textColor: AppColors.primary,
            iconColor: AppColors.primary,
          ),
        ),
      ),
    );
  }

  /// Build button content (text + icon + loading)
  Widget _buildButtonContent({
    required Color textColor,
    required Color iconColor,
  }) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          width: AppDimensions.iconSm,
          height: AppDimensions.iconSm,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(textColor),
          ),
        ),
      );
    }

    final textWidget = Text(
      text,
      style: AppTextStyles.labelLarge.copyWith(color: textColor),
      textAlign: TextAlign.center,
    );

    if (icon == null) {
      return Center(child: textWidget);
    }

    final iconWidget = Icon(icon, size: AppDimensions.iconSm, color: iconColor);

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!iconRight) ...[
          iconWidget,
          const SizedBox(width: AppDimensions.spacing2),
        ],
        Flexible(child: textWidget),
        if (iconRight) ...[
          const SizedBox(width: AppDimensions.spacing2),
          iconWidget,
        ],
      ],
    );
  }
}
