import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Card widget following Academic Pulse design system
/// Features:
/// - NO 1px borders (uses tonal layering)
/// - Surface color hierarchy for depth
/// - Optional accent bar on left edge (4px blue pill)
/// - Optional elevation with blue-tinted shadow
/// - Glassmorphism variant for floating elements
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? borderRadius;
  final bool hasAccentBar;
  final Color? accentBarColor;
  final bool hasElevation;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.hasAccentBar = false,
    this.accentBarColor,
    this.hasElevation = false,
    this.onTap,
  });

  /// Standard card with white background
  const AppCard.standard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.hasAccentBar = false,
    this.accentBarColor,
    this.onTap,
  }) : backgroundColor = AppColors.surfaceContainerLowest,
       borderRadius = AppDimensions.radiusMd,
       hasElevation = false;

  /// Elevated card with shadow
  const AppCard.elevated({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.hasAccentBar = false,
    this.accentBarColor,
    this.onTap,
  }) : backgroundColor = AppColors.surfaceContainerLowest,
       borderRadius = AppDimensions.radiusMd,
       hasElevation = true;

  /// Metric card for dashboard (with accent bar)
  const AppCard.metric({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.accentBarColor,
    this.onTap,
  }) : backgroundColor = AppColors.surfaceContainerLowest,
       borderRadius = AppDimensions.radiusMd,
       hasElevation = true,
       hasAccentBar = true;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.radiusMd,
        ),
        boxShadow: hasElevation
            ? [
                BoxShadow(
                  color: AppColors.shadowTinted,
                  offset: const Offset(0, 8),
                  blurRadius: AppDimensions.elevation3,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.radiusMd,
        ),
        child: Row(
          children: [
            // Accent Bar (optional)
            if (hasAccentBar)
              Container(
                width: AppDimensions.accentBarWidth,
                decoration: BoxDecoration(
                  color: accentBarColor ?? AppColors.primary,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppDimensions.radiusFull),
                    bottomLeft: Radius.circular(AppDimensions.radiusFull),
                  ),
                ),
              ),
            // Content
            Expanded(
              child: Padding(
                padding:
                    padding ?? const EdgeInsets.all(AppDimensions.spacing4),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );

    // Wrap with InkWell if tappable
    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppDimensions.radiusMd,
          ),
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Glassmorphism card for modals and floating elements
class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final double blur;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = AppDimensions.blurMedium,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.radiusMd,
        ),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.15),
          width: AppDimensions.ghostBorderWidth,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.radiusMd,
        ),
        child: BackdropFilter(
          filter: ColorFilter.mode(
            Colors.white.withValues(alpha: 0.1),
            BlendMode.lighten,
          ),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(AppDimensions.spacing4),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Section card with tonal layering (darker background)
class AppSectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final String? title;
  final Widget? action;

  const AppSectionCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.title,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppDimensions.spacing4),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null || action != null)
            Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacing3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (title != null)
                    Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  if (action != null) action!,
                ],
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Outlined card with ghost border
class AppOutlinedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final VoidCallback? onTap;

  const AppOutlinedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(AppDimensions.spacing4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppDimensions.radiusMd,
        ),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.15),
          width: AppDimensions.ghostBorderWidth,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            borderRadius ?? AppDimensions.radiusMd,
          ),
          child: card,
        ),
      );
    }

    return card;
  }
}
