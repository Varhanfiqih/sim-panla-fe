import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../data/models/journal.dart';
import '../bloc/journal_bloc.dart';
import 'journal_form_page.dart';

/// Journal Student List Page - Attendance marking for a class
/// Design reference: stitch/s_06_journal_student_list
class JournalStudentListPage extends StatelessWidget {
  final int scheduleId;
  final String className;
  final String subjectName;
  final String timeSlot;

  const JournalStudentListPage({
    super.key,
    required this.scheduleId,
    required this.className,
    required this.subjectName,
    required this.timeSlot,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => JournalBloc()
        ..add(
          LoadJournalStudents(
            scheduleId: scheduleId,
            className: className,
            subjectName: subjectName,
            timeSlot: timeSlot,
          ),
        ),
      child: const _JournalStudentListView(),
    );
  }
}

class _JournalStudentListView extends StatelessWidget {
  const _JournalStudentListView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: BlocConsumer<JournalBloc, JournalState>(
        listener: (context, state) {
          if (state is JournalError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is JournalLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is JournalStudentsLoaded) {
            return _buildContent(context, state);
          }

          if (state is JournalError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(state.message, style: AppTextStyles.bodyLarge),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Kembali'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, JournalStudentsLoaded state) {
    return CustomScrollView(
      slivers: [
        // Hero Header Section
        SliverToBoxAdapter(child: _HeroHeader(state: state)),

        // Student List Header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Daftar Siswa', style: AppTextStyles.headlineSmall),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${state.students.length} Siswa',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Student List
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final studentState = state.students[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _StudentCard(
                  studentState: studentState,
                  onStatusChanged: (status) {
                    context.read<JournalBloc>().add(
                      UpdateStudentStatus(
                        studentId: studentState.student.id,
                        status: status,
                      ),
                    );
                  },
                ),
              );
            }, childCount: state.students.length),
          ),
        ),

        // Bottom padding for FAB
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

/// Hero header with class info and scan stats
class _HeroHeader extends StatelessWidget {
  final JournalStudentsLoaded state;

  const _HeroHeader({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0040DF), Color(0xFF4648D4)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button & title
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Jurnal Mengajar',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Class info
              Text(
                'SESI SAAT INI',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.className,
                style: AppTextStyles.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      state.subjectName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Flexible(
                    child: Text(
                      state.timeSlot,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Scan stats
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.sensors,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${state.totalSudahScan}/${state.students.length}',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Scan Gerbang',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Student attendance card with status toggle
class _StudentCard extends StatelessWidget {
  final StudentAttendanceState studentState;
  final ValueChanged<StudentStatus> onStatusChanged;

  const _StudentCard({
    required this.studentState,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final student = studentState.student;
    final isLocked = student.isLocked;
    final hasScan = student.sudahScanGerbang;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isLocked
            ? Border(
                left: BorderSide(
                  color: _getStatusColor(studentState.currentStatus),
                  width: 4,
                ),
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowAmbient,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Student info row
          Row(
            children: [
              // Avatar with scan indicator
              Stack(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isLocked
                          ? AppColors.surfaceContainerLow.withValues(alpha: 0.6)
                          : AppColors.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(student.name),
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isLocked
                              ? AppColors.onSurfaceVariant
                              : AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  // Scan badge
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: hasScan
                            ? AppColors.success
                            : AppColors.onSurfaceVariant,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Icon(
                        Icons.qr_code_scanner,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 16),

              // Name and info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: isLocked
                            ? AppColors.onSurfaceVariant
                            : AppColors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'NIS: ${student.nis}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: hasScan
                                ? AppColors.successContainer
                                : AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            hasScan ? 'Di Sekolah' : 'Belum Scan',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: hasScan
                                  ? AppColors.success
                                  : AppColors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Show locked reason if locked
                    if (isLocked && student.keteranganIzin != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.lock,
                            size: 12,
                            color: _getStatusColor(studentState.currentStatus),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Izin: ${student.keteranganIzin}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: _getStatusColor(
                                  studentState.currentStatus,
                                ),
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Status buttons
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                _StatusButton(
                  label: 'Hadir',
                  isSelected: studentState.currentStatus == StudentStatus.hadir,
                  isLocked: isLocked,
                  color: AppColors.primary,
                  onTap: () => onStatusChanged(StudentStatus.hadir),
                ),
                const SizedBox(width: 4),
                _StatusButton(
                  label: 'Alpa',
                  isSelected: studentState.currentStatus == StudentStatus.alpa,
                  isLocked: isLocked,
                  color: AppColors.error,
                  onTap: () => onStatusChanged(StudentStatus.alpa),
                ),
                const SizedBox(width: 4),
                _StatusButton(
                  label: 'Sakit',
                  isSelected: studentState.currentStatus == StudentStatus.sakit,
                  isLocked: isLocked,
                  color: AppColors.info,
                  onTap: () => onStatusChanged(StudentStatus.sakit),
                ),
                const SizedBox(width: 4),
                _StatusButton(
                  label: 'Izin',
                  isSelected: studentState.currentStatus == StudentStatus.izin,
                  isLocked: isLocked,
                  color: AppColors.izin,
                  onTap: () => onStatusChanged(StudentStatus.izin),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, 2).toUpperCase();
  }

  Color _getStatusColor(StudentStatus status) {
    switch (status) {
      case StudentStatus.hadir:
        return AppColors.success;
      case StudentStatus.alpa:
        return AppColors.error;
      case StudentStatus.sakit:
        return AppColors.info;
      case StudentStatus.izin:
        return AppColors.izin;
      default:
        return AppColors.onSurfaceVariant;
    }
  }
}

/// Status toggle button
class _StatusButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isLocked;
  final Color color;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.isSelected,
    required this.isLocked,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: isLocked ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color, color.withValues(alpha: 0.8)],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label.toUpperCase(),
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating action button to proceed
class JournalStudentListPageWithFAB extends StatelessWidget {
  final int scheduleId;
  final String className;
  final String subjectName;
  final String timeSlot;
  final String journalDate;

  const JournalStudentListPageWithFAB({
    super.key,
    required this.scheduleId,
    required this.className,
    required this.subjectName,
    required this.timeSlot,
    required this.journalDate,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => JournalBloc()
        ..add(
          LoadJournalStudents(
            scheduleId: scheduleId,
            className: className,
            subjectName: subjectName,
            timeSlot: timeSlot,
            journalDate: journalDate,
          ),
        ),
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: const _JournalStudentListView(),
        floatingActionButton: BlocBuilder<JournalBloc, JournalState>(
          builder: (context, state) {
            if (state is! JournalStudentsLoaded) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<JournalBloc>(),
                        child: const JournalFormPage(),
                      ),
                    ),
                  ).then((submitted) {
                    if (submitted == true && context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0040DF), Color(0xFF2D5BFF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0040DF).withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lanjut ke Form Jurnal',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}
