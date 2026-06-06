import 'package:flutter/material.dart';

/// Academic Pulse Design System - Color Palette
/// Creative North Star: "The Modern Curator"
/// Authoritative Blue with sophisticated neutral surfaces
class AppColors {
  AppColors._();

  // ============ PRIMARY COLORS ============
  /// Deep authoritative blue - Main brand color
  static const Color primary = Color(0xFF0040A1);

  /// Lighter variant for gradients and CTAs
  static const Color primaryContainer = Color(0xFF0056D2);

  /// Very light blue for large background areas
  static const Color primaryFixed = Color(0xFFE3F2FD);

  /// Text on primary color
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Text on primary container
  static const Color onPrimaryContainer = Color(0xFF001A41);

  // ============ SURFACE HIERARCHY ============
  /// Base layer - Main background
  static const Color surface = Color(0xFFF7F9FC);

  /// Sectioning layer - Slightly darker for grouping
  static const Color surfaceContainerLow = Color(0xFFF2F4F7);

  /// Content/Card layer - White for cards
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);

  /// Interaction layer - Hover/Active states
  static const Color surfaceBright = Color(0xFFF7F9FC);

  /// Highest elevation - Modals, dialogs
  static const Color surfaceContainerHighest = Color(0xFFEDF1F5);

  /// High contrast surface
  static const Color surfaceContainerHigh = Color(0xFFE8ECEF);

  // ============ TEXT COLORS ============
  /// Primary text - Not pure black for premium feel
  static const Color onSurface = Color(0xFF191C1E);

  /// Secondary text - Metadata, labels
  static const Color onSurfaceVariant = Color(0xFF424654);

  /// Tertiary text - Disabled, hints
  static const Color onSurfaceTertiary = Color(0xFF73777F);

  // ============ STATUS COLORS ============
  /// Success - Hadir, Completed
  static const Color success = Color(0xFF4CAF50);
  static const Color successContainer = Color(0xFFCBE7F5);
  static const Color onSuccessContainer = Color(0xFF005234);

  /// Error - Alpa, Failed
  static const Color error = Color(0xFFD32F2F);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onErrorContainer = Color(0xFF93000A);

  /// Warning - Terlambat, Pending
  static const Color warning = Color(0xFFFF9800);
  static const Color warningContainer = Color(0xFFFFE0B2);
  static const Color onWarningContainer = Color(0xFF7F4E00);

  /// Info - Izin, Sakit
  static const Color info = Color(0xFF2196F3);
  static const Color infoContainer = Color(0xFFBBDEFB);
  static const Color onInfoContainer = Color(0xFF001D36);

  // ============ SECONDARY ACCENT ============
  /// Secondary color for variety
  static const Color secondary = Color(0xFF006A6A);
  static const Color secondaryContainer = Color(0xFFCBE7F5);
  static const Color onSecondaryContainer = Color(0xFF002020);

  /// Tertiary color
  static const Color tertiary = Color(0xFF9C4146);
  static const Color tertiaryContainer = Color(0xFFFFDAD8);
  static const Color onTertiaryContainer = Color(0xFF400009);

  // ============ OUTLINE & BORDERS ============
  /// Ghost border - 15% opacity for accessibility
  static const Color outlineVariant = Color(0xFFC3C6D6);
  static const Color outline = Color(0xFF73777F);

  // ============ SPECIAL EFFECTS ============
  /// Scrim for modals with blur
  static Color scrim = const Color(0xFF000000).withValues(alpha: 0.32);

  /// Shadow with blue tint (Y: 8px, Blur: 24px)
  static Color shadowTinted = const Color(0xFF0040A1).withValues(alpha: 0.06);

  /// Primary shadow for buttons
  static Color shadowPrimary = const Color(0xFF0040A1).withValues(alpha: 0.12);

  /// Ambient shadow
  static Color shadowAmbient = const Color(0xFF000000).withValues(alpha: 0.04);

  // ============ GRADIENT DEFINITIONS ============
  /// Primary gradient for CTAs and hero headers
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryContainer],
  );

  /// Subtle surface gradient
  static const LinearGradient surfaceGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [surfaceContainerLowest, surface],
  );

  // ============ SEMANTIC COLORS FOR ATTENDANCE ============
  /// Hadir - Present
  static const Color hadir = success;
  static const Color hadirContainer = successContainer;

  /// Alpa - Absent without permission
  static const Color alpa = error;
  static const Color alpaContainer = errorContainer;

  /// Sakit - Sick
  static const Color sakit = info;
  static const Color sakitContainer = infoContainer;

  /// Izin - Permission
  static const Color izin = Color(0xFF9C27B0);
  static const Color izinContainer = Color(0xFFF3E5F5);

  /// Terlambat - Late
  static const Color terlambat = warning;
  static const Color terlambatContainer = warningContainer;
}
