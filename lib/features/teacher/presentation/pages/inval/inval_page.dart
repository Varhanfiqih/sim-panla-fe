import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/services/local_notification_service.dart';
import '../../../data/models/app_notification.dart';
import '../../../data/models/inval_class.dart';
import '../../../data/models/inval_history_item.dart';
import '../../bloc/inval/inval_bloc.dart';
import '../../bloc/inval/inval_event.dart';
import '../../bloc/inval/inval_state.dart';

class InvalPage extends StatefulWidget {
  const InvalPage({super.key});

  @override
  State<InvalPage> createState() => _InvalPageState();
}

class _InvalPageState extends State<InvalPage> {
  @override
  void initState() {
    super.initState();
    // Fetch inval classes on initialization
    context.read<InvalBloc>().add(const LoadInvalClasses());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8FF),
      appBar: AppBar(
        title: Text(
          'Jadwal Inval',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: const Color(0xFF131B2E), // on-surface
          ),
        ),
        backgroundColor: const Color(0xFFFAF8FF),
        elevation: 0,
        centerTitle: false,
      ),
      body: BlocConsumer<InvalBloc, InvalState>(
        listener: (context, state) {
          if (state is InvalClaimSuccess) {
            LocalNotificationService().show(
              AppNotification(
                id: DateTime.now().millisecondsSinceEpoch.remainder(1000000000),
                userId: 0,
                type: 'inval_claim',
                title: 'Jadwal Inval Berhasil Diambil',
                body: state.message,
                data: const {'source': 'local_inval_claim'},
                isRead: false,
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.primary,
              ),
            );
          } else if (state is InvalClaimError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is InvalLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InvalError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat kelas inval:\n${state.message}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<InvalBloc>().add(const LoadInvalClasses()),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          List<InvalClass> classes = [];
          List<InvalHistoryItem> history = [];
          if (state is InvalLoaded) {
            classes = state.classes;
            history = state.history;
          } else if (state is InvalClaimSuccess || state is InvalClaimError) {
            // Keep showing previous list while transitioning
            final currentState = context.read<InvalBloc>().state;
            if (currentState is InvalLoaded) {
              classes = currentState.classes;
              history = currentState.history;
            }
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<InvalBloc>().add(const LoadInvalClasses());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.spacing6,
                vertical: AppDimensions.spacing8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(classes.length),
                  const SizedBox(height: AppDimensions.spacing8),
                  _buildStatsOverview(classes),
                  const SizedBox(height: AppDimensions.spacing8),
                  _buildClassesList(classes),
                  const SizedBox(height: AppDimensions.spacing8),
                  _buildHistorySection(history),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'JADWAL INVAL',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                  color: AppColors.primary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Kelas Kosong Hari Ini',
                style: GoogleFonts.plusJakartaSans(
                  fontSize:
                      28, // Using a bit smaller than 3xl for mobile screens
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.5,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            count.toString(),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.onPrimaryContainer,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsOverview(List<InvalClass> classes) {
    final totalMinutes = classes.fold<int>(
      0,
      (total, item) => total + item.durationMinutes,
    );
    final totalHours = totalMinutes / 60;
    final hasUrgent = classes.any(_isUrgent);

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: 'Total Jam',
            value: '${totalHours.toStringAsFixed(1)}h',
            iconData: Icons.schedule_rounded,
            valueColor: AppColors.primary,
          ),
        ),
        const SizedBox(width: AppDimensions.spacing4),
        Expanded(
          child: _buildStatCard(
            title: 'Kebutuhan',
            value: classes.isEmpty
                ? 'Aman'
                : hasUrgent
                ? 'Urgent'
                : 'Tersedia',
            iconData: Icons.emergency_rounded,
            valueColor: classes.isEmpty
                ? const Color(0xFF198754)
                : const Color(0xFF7A1BC8),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData iconData,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing6),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: valueColor,
                ),
              ),
            ],
          ),
          Positioned(
            right: -24,
            bottom: -24,
            child: Icon(
              iconData,
              size: 72,
              color: AppColors.onSurfaceVariant.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesList(List<InvalClass> classes) {
    if (classes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            'Tidak ada kelas kosong saat ini',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Column(
      children: List.generate(classes.length, (index) {
        final item = classes[index];
        final isFirst =
            index == 0; // The first item gets the glass card emphasis

        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacing4),
          child: isFirst ? _buildGlassCard(item) : _buildStandardCard(item),
        );
      }),
    );
  }

  Widget _buildHistorySection(List<InvalHistoryItem> history) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Riwayat Klaim Hari Ini',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        if (history.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.spacing5),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
            ),
            child: Text(
              'Belum ada riwayat klaim kelas inval hari ini.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          )
        else
          ...history.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.spacing4),
              child: _buildHistoryCard(entry.value, entry.key == 0),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryCard(InvalHistoryItem item, bool isFirst) {
    final claimedLabel = item.claimedAt == null || item.claimedAt!.isEmpty
        ? 'Diklaim'
        : 'Diklaim ${item.claimedAt}';

    final card = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _subjectTag(item.subject).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'CLAIMED',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                item.time,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          item.subject,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.meeting_room_rounded,
              size: 16,
              color: AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                item.className,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.spacing4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFE8EDF8),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Diambil oleh ${item.claimedByName}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0035BD),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'NIP ${item.claimedByNip} • $claimedLabel',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (isFirst) {
      return Container(
        padding: const EdgeInsets.all(AppDimensions.spacing5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: const Color(0xFFC3C6D7).withValues(alpha: 0.15)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F131B2E),
              blurRadius: 40,
              offset: Offset(0, 40),
              spreadRadius: -15,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          child: Container(color: Colors.white.withValues(alpha: 0.4), child: card),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: card,
    );
  }

  Widget _buildGlassCard(InvalClass item) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        border: Border.all(color: const Color(0xFFC3C6D7).withValues(alpha: 0.15)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F131B2E), // 6% opacity shadow
            blurRadius: 40,
            offset: Offset(0, 40),
            spreadRadius: -15,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        child: Container(
          color: Colors.white.withValues(alpha: 0.4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildCardHeader(item, showUrgent: _isUrgent(item)),
              const SizedBox(height: AppDimensions.spacing5),
              _buildAvatarGroup(),
              const SizedBox(height: AppDimensions.spacing5),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () => _claimClass(item),
                  icon: const Icon(Icons.add_task_rounded),
                  label: const Text('Ambil Kelas'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusMd,
                      ),
                    ),
                    textStyle: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
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

  Widget _buildStandardCard(InvalClass item) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.spacing5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCardHeader(item, showUrgent: _isUrgent(item)),
          const SizedBox(height: AppDimensions.spacing5),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () => _claimClass(item),
              icon: const Icon(Icons.touch_app_rounded),
              label: const Text('Ambil Kelas'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerHigh,
                foregroundColor: const Color(
                  0xFF0035BD,
                ), // on-primary-fixed-variant
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
                ),
                textStyle: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardHeader(InvalClass item, {required bool showUrgent}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      _subjectTag(item.subject).toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  if (showUrgent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'URGENT',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                item.subject,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.meeting_room_rounded,
                    size: 16,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      item.className,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.time,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'SESI X',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _isUrgent(InvalClass item) {
    final start = _parseStartTimeToday(item.time);
    if (start == null) return false;

    final now = DateTime.now();
    final deadline = now.add(const Duration(minutes: 60));
    return start.isBefore(deadline);
  }

  DateTime? _parseStartTimeToday(String timeRange) {
    final parts = timeRange.split('-');
    if (parts.isEmpty) return null;

    final start = parts.first.trim();
    final hhmm = start.split(':');
    if (hhmm.length != 2) return null;

    final hour = int.tryParse(hhmm[0]);
    final minute = int.tryParse(hhmm[1]);
    if (hour == null || minute == null) return null;

    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  String _subjectTag(String subject) {
    final trimmed = subject.trim();
    if (trimmed.isEmpty) return 'Mapel';

    final words = trimmed.split(' ');
    return words.take(2).join(' ');
  }

  Widget _buildAvatarGroup() {
    return Row(
      children: [
        SizedBox(
          height: 28,
          width: 80, // added width bound
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _buildAvatarItem(
                'https://ui-avatars.com/api/?name=St&background=random',
                0,
              ),
              _buildAvatarItem(
                'https://ui-avatars.com/api/?name=Ma&background=random',
                1,
              ),
              Positioned(
                left: 2 * 20.0, // overlap offset
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+28',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(
          width: AppDimensions.spacing2,
        ), // adjusted padding after avatars
        Text(
          '32 Siswa menunggu',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarItem(String url, int index) {
    return Positioned(
      left: index * 20.0,
      child: ClipOval(
        child: SizedBox(
          width: 28,
          height: 28,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 28,
                height: 28,
                color: AppColors.surfaceContainerHighest,
                alignment: Alignment.center,
                child: const Icon(Icons.person, size: 14),
              );
            },
          ),
        ),
      ),
    );
  }

  void _claimClass(InvalClass item) {
    if (item.scheduleIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID Jadwal tidak valid.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Show confirmation dialog before claiming
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Konfirmasi',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Apakah Anda yakin ingin mengambil kelas inval ${item.subject} di ${item.className}?',
          style: GoogleFonts.inter(),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<InvalBloc>().add(
                ClaimInvalClassEvent(item.scheduleIds),
              );
            },
            child: const Text('Ambil Kelas'),
          ),
        ],
      ),
    );
  }
}
