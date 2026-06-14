import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../auth/presentation/bloc/bloc.dart';
import '../../../auth/data/models/user.dart';

/// Placeholder Home Page for testing login flow
/// Will be replaced with actual dashboard implementation
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        User? user;
        if (state is AuthAuthenticated) {
          user = state.user;
        }

        return Scaffold(
          backgroundColor: AppColors.surface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppDimensions.spacing3),
                Text(
                  'SIM PANLA',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(
                  Icons.logout_outlined,
                  color: AppColors.onSurfaceVariant,
                ),
                onPressed: () {
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                },
              ),
              const SizedBox(width: AppDimensions.spacing2),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.spacing4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  AppCard.elevated(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.primaryFixed,
                              child: Text(
                                user?.name.substring(0, 1).toUpperCase() ?? 'U',
                                style: AppTextStyles.headlineMedium.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppDimensions.spacing4),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selamat Datang!',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(
                                    height: AppDimensions.spacing1,
                                  ),
                                  Text(
                                    user?.name ?? 'User',
                                    style: AppTextStyles.titleLarge,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppDimensions.spacing4),
                        // User Info
                        Container(
                          padding: const EdgeInsets.all(AppDimensions.spacing3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                          child: Column(
                            children: [
                              _buildInfoRow('NIP', user?.nip ?? '-'),
                              const SizedBox(height: AppDimensions.spacing2),
                              _buildInfoRow('Role', user?.role ?? '-'),
                              if (user?.isWaliKelas == true) ...[
                                const SizedBox(height: AppDimensions.spacing2),
                                _buildInfoRow(
                                  'Wali Kelas',
                                  user?.waliKelas ?? '-',
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacing6),
                  // Status Card
                  Text('Status', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppDimensions.spacing3),
                  AppCard.metric(
                    accentBarColor: AppColors.success,
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.successContainer,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusMd,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: AppColors.success,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: AppDimensions.spacing4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Login Berhasil!',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(height: AppDimensions.spacing1),
                              Text(
                                'Anda telah berhasil login ke sistem.',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppDimensions.spacing6),
                  // Coming Soon
                  Text('Fitur Mendatang', style: AppTextStyles.titleMedium),
                  const SizedBox(height: AppDimensions.spacing3),
                  _buildFeatureItem(
                    Icons.fingerprint,
                    'Check-in/Check-out',
                    'Presensi harian guru',
                  ),
                  const SizedBox(height: AppDimensions.spacing3),
                  _buildFeatureItem(
                    Icons.calendar_today_outlined,
                    'Jadwal Mengajar',
                    'Lihat jadwal harian',
                  ),
                  const SizedBox(height: AppDimensions.spacing3),
                  _buildFeatureItem(
                    Icons.book_outlined,
                    'Jurnal Mengajar',
                    'Catat aktivitas mengajar',
                  ),
                  const SizedBox(height: AppDimensions.spacing3),
                  _buildFeatureItem(
                    Icons.people_outline,
                    'Absensi Siswa',
                    'Kelola kehadiran siswa',
                  ),
                  const SizedBox(height: AppDimensions.spacing8),
                  // Logout Button
                  AppButton(
                    text: 'Logout',
                    onPressed: () {
                      context.read<AuthBloc>().add(AuthLogoutRequested());
                    },
                    variant: AppButtonVariant.outline,
                    icon: Icons.logout,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return AppCard.standard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primaryFixed,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppDimensions.spacing4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.titleSmall),
                const SizedBox(height: AppDimensions.spacing1),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppDimensions.spacing2,
              vertical: AppDimensions.spacing1,
            ),
            decoration: BoxDecoration(
              color: AppColors.warningContainer,
              borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
            ),
            child: Text(
              'Soon',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.onWarningContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
