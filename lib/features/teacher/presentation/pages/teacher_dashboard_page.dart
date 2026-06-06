import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/bloc/bloc.dart';
import '../../../auth/data/models/user.dart';
import '../../data/repositories/grade_repository.dart';
import '../../data/models/schedule.dart';
import '../bloc/bloc.dart';
import 'check_in_page.dart';
import 'schedule_page.dart';
import 'inval/inval_page.dart';
import 'permission/permission_list_page.dart';
import 'notification_page.dart';
import 'grade_setup_page.dart';

/// Teacher Dashboard - Following stitch design (s_03_dashboard_guru_new_style)
class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _GradeCardData {
  final String classId;
  final String subjectName;
  final int completed;
  final int total;
  final bool isLocked;

  const _GradeCardData({
    required this.classId,
    required this.subjectName,
    required this.completed,
    required this.total,
    required this.isLocked,
  });
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage> {
  bool isCheckedIn = false; // Track check-in status
  bool? _isPresent;
  String? _attendanceReason;
  int? _notifStartedForUserId;
  int? _gradeLoadedForUserId;
  bool _gradeLoading = false;
  _GradeCardData? _gradeCard;

  final GradeRepository _gradeRepository = GradeRepository();
  late ValueNotifier<DateTime> _nowNotifier;
  Timer? _clockTimer;

  // Colors from stitch design
  static const Color _primary = Color(0xFF0040DF);
  static const Color _primaryContainer = Color(0xFF2D5BFF);
  static const Color _surface = Color(0xFFFAF8FF);
  static const Color _surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color _surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color _onSurface = Color(0xFF131B2E);
  static const Color _onSurfaceVariant = Color(0xFF434655);
  static const Color _outline = Color(0xFF737686);
  static const Color _outlineVariant = Color(0xFFC3C6D7);
  static const Color _tertiary = Color(0xFF7A1BC8);
  static const Color _tertiaryContainer = Color(0xFF943FE2);

  Future<void> _onRefresh() async {
    final attendanceBloc = context.read<AttendanceBloc>();
    final scheduleBloc = context.read<ScheduleBloc>();

    attendanceBloc.add(const CheckAttendanceStatus());
    scheduleBloc.add(const LoadSchedules());

    await Future.wait([
      attendanceBloc.stream.firstWhere(
        (state) => state is AttendanceStatusLoaded || state is AttendanceError,
      ),
      scheduleBloc.stream.firstWhere(
        (state) => state is ScheduleLoaded || state is ScheduleError,
      ),
    ]);
  }

  @override
  void initState() {
    super.initState();
    _nowNotifier = ValueNotifier<DateTime>(DateTime.now());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _nowNotifier.value = DateTime.now();
    });
    // Load check-in status and today's schedule when page loads
    context.read<AttendanceBloc>().add(const CheckAttendanceStatus());
    context.read<ScheduleBloc>().add(const LoadSchedules());
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _nowNotifier.dispose();
    super.dispose();
  }

  

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  void _ensureNotificationRealtime(User? user) {
    if (user == null) return;
    if (_notifStartedForUserId == user.id) return;

    _notifStartedForUserId = user.id;
    context.read<NotificationBloc>().add(NotificationStarted(user.id));
  }

  void _ensureGradeCard(User? user) {
    if (user == null || !user.isWaliKelas) return;
    if (_gradeLoadedForUserId == user.id || _gradeLoading) return;

    _gradeLoadedForUserId = user.id;
    _loadGradeCard(user);
  }

  Future<void> _loadGradeCard(User user) async {
    setState(() => _gradeLoading = true);
    try {
      final meta = await _gradeRepository.getMeta();
      if (meta.periods.isEmpty ||
          meta.subjects.isEmpty ||
          meta.categories.isEmpty) {
        if (!mounted) return;
        setState(() {
          _gradeCard = null;
          _gradeLoading = false;
        });
        return;
      }

      final periodId = meta.activePeriodId ?? meta.periods.first.id;
      final subject = meta.subjects.first;
      final category = meta.categories.first;
      final summary = await _gradeRepository.getSummary(
        periodId: periodId,
        subjectId: subject.id,
        categoryId: category.id,
        itemNo: 1,
      );

      if (!mounted) return;
      setState(() {
        _gradeCard = _GradeCardData(
          classId: meta.classId,
          subjectName: subject.name,
          completed: summary.completed,
          total: summary.totalStudents,
          isLocked: summary.isLocked,
        );
        _gradeLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _gradeLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttendanceBloc, AttendanceState>(
      listener: (context, attendanceState) {
        // Update check-in status when loaded
        if (attendanceState is AttendanceStatusLoaded) {
          setState(() {
            isCheckedIn = attendanceState.hasCheckedIn;
            _isPresent = attendanceState.isPresent;
            _attendanceReason = attendanceState.reason;
          });
        }

        // Show success message after check-in
        if (attendanceState is AttendanceCheckInSuccess) {
          setState(() {
            isCheckedIn = true;
            _isPresent = attendanceState.attendance.status == 'hadir';
            _attendanceReason = attendanceState.attendance.reason;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Konfirmasi kehadiran berhasil!',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFF10B981), // green-500
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        // Show error message
        if (attendanceState is AttendanceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                attendanceState.message,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
              backgroundColor: const Color(0xFFDC2626), // red-600
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          User? user;
          if (state is AuthAuthenticated) {
            user = state.user;
            _ensureNotificationRealtime(user);
            _ensureGradeCard(user);
          }

          final topPadding = MediaQuery.of(context).padding.top;
          final appBarHeight = topPadding + 72; // status bar + app bar content

          return Scaffold(
            backgroundColor: _surface,
            body: Stack(
              children: [
                // Main Content
                RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      // TopAppBar spacing
                      SliverToBoxAdapter(
                        child: SizedBox(height: appBarHeight + 16),
                      ),
                      // Content
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            // Check-In Banner
                            _buildCheckInBanner(user),
                            const SizedBox(height: 40),

                            // Metrics Bento Grid
                            _buildMetricsGrid(user),
                            const SizedBox(height: 40),

                            // Menu Utama (Quick Actions)
                            _buildMainMenu(user),
                            const SizedBox(height: 40),

                            // Today's Schedule
                            _buildScheduleSection(),
                            const SizedBox(height: 40),

                            // Jurnal Progress
                            _buildJournalProgressCard(user),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),

                // Fixed TopAppBar
                _buildTopAppBar(user),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopAppBar(User? user) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top + 16,
              24,
              16,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(179), // 0.7 opacity
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF131B2E).withAlpha(15), // 0.06 opacity
                  blurRadius: 40,
                ),
              ],
            ),
            child: Row(
              children: [
                // Profile Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: _primaryContainer.withAlpha(26), // 0.1 opacity
                    border: Border.all(
                      color: _primary.withAlpha(26), // 0.1 opacity
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Center(
                      child: Text(
                        user?.shortName.substring(0, 1).toUpperCase() ?? 'G',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _primary,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Greeting
                Expanded(
                  child: Text(
                    '${_getGreeting()}, ${user?.shortName ?? 'Guru'}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: _onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Notification Button
                BlocBuilder<NotificationBloc, NotificationState>(
                  builder: (context, notifState) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          final notificationBloc =
                              context.read<NotificationBloc>();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const NotificationPage(),
                            ),
                          ).then((_) {
                            if (!mounted) return;
                            notificationBloc.add(
                              const NotificationUnreadRequested(),
                            );
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: SizedBox(
                          width: 40,
                          height: 40,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              const Center(
                                child: Icon(
                                  Icons.notifications_outlined,
                                  color: _primaryContainer,
                                  size: 24,
                                ),
                              ),
                              if (notifState.unreadCount > 0)
                                Positioned(
                                  right: 2,
                                  top: 2,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDC2626),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      notifState.unreadCount > 99
                                          ? '99+'
                                          : '${notifState.unreadCount}',
                                      style: GoogleFonts.inter(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
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
    );
  }

  Widget _buildMainMenu(User? user) {
    if (user == null) return const SizedBox.shrink();

    // Setup base menus
    final menus = [
      {
        'icon': Icons.event_note_rounded,
        'label': 'Jadwal',
        'color': _primary,
        'bg': _primaryContainer.withAlpha(26),
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SchedulePage()),
        ),
      },
      {
        'icon': Icons.swap_horizontal_circle_rounded,
        'label': 'Inval',
        'color': const Color(0xFFF59E0B), // amber-500
        'bg': const Color(0xFFFEF3C7).withAlpha(76), // amber-100 0.3 opacity
        'onTap': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const InvalPage()),
        ),
      },
    ];

    // Conditionally add 'Perizinan' if user is Wali Kelas
    if (user.isWaliKelas) {
      menus.add({
        'icon': Icons.verified_user_rounded,
        'label': 'Perizinan',
        'color': const Color(0xFF10B981), // emerald-500
        'bg': const Color(0xFFD1FAE5).withAlpha(76), // emerald-100 0.3 opacity
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PermissionListPage()),
          );
        },
      });

      menus.add({
        'icon': Icons.grading_rounded,
        'label': 'Penilaian',
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFDBEAFE).withAlpha(76),
        'onTap': () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GradeSetupPage()),
          );
        },
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Menu Utama',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: _onSurface,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: menus.map((menu) {
            return Padding(
              padding: const EdgeInsets.only(right: 24.0),
              child: GestureDetector(
                onTap: menu['onTap'] as VoidCallback,
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: menu['bg'] as Color,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        menu['icon'] as IconData,
                        color: menu['color'] as Color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      menu['label'] as String,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCheckInBanner(User? user) {
    // Use state field isCheckedIn (updated via BlocListener)

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _primary, // #0040DF
            _tertiary, // #7A1BC8
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withAlpha(77), // 0.3 opacity
            blurRadius: 32,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative blur circle
          Positioned(
            right: -48,
            bottom: -48,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(26), // 0.1 opacity
              ),
            ),
          ),
          // Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Live badge & DateTime
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(51), // 0.2 opacity
                            borderRadius: BorderRadius.circular(9999),
                          ),
                          child: Text(
                            _attendanceBadgeText(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            DateFormat(
                              'EEEE, dd MMM',
                              'id_ID',
                            ).format(DateTime.now()),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withAlpha(204),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _attendanceTitleText(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _attendanceSubtitleText(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(204), // 0.8 opacity
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        ValueListenableBuilder<DateTime>(
                          valueListenable: _nowNotifier,
                          builder: (context, now, _) {
                            return Text(
                              DateFormat('HH:mm:ss').format(now),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withAlpha(230),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Check-in Button (circular)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isCheckedIn ? null : () => _handleCheckIn(),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(26), // 0.1 opacity
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _attendanceActionText(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(User? user) {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        int scheduleCount = 0;
        int doneCount = 0;
        int totalCount = 0;

        if (state is ScheduleLoaded) {
          totalCount = state.schedules.length;
          doneCount = state.schedules
              .where((s) => s.statusJurnal == JournalStatus.done)
              .length;
          scheduleCount = totalCount;
        }

        return Row(
          children: [
            // Metric 1 - Jadwal Hari Ini
            Expanded(
              child: _buildMetricCard(
                icon: Icons.bolt,
                iconBgColor: _primaryContainer.withAlpha(26),
                iconColor: _primary,
                label: 'JADWAL',
                value: '$scheduleCount',
                suffix: 'JP',
                subtitle: 'Jam Pelajaran',
              ),
            ),
            const SizedBox(width: 16),
            // Metric 2 - Jurnal Progress
            Expanded(
              child: _buildMetricCard(
                icon: Icons.task_alt,
                iconBgColor: _tertiaryContainer.withAlpha(26),
                iconColor: _tertiary,
                label: 'JURNAL',
                value: '$doneCount',
                suffix: '/$totalCount',
                subtitle: totalCount == doneCount && totalCount > 0
                    ? 'Semua selesai!'
                    : doneCount > 0
                    ? 'Hampir selesai'
                    : 'Belum diisi',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required String value,
    required String suffix,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF131B2E).withAlpha(10), // 0.04 opacity
            blurRadius: 40,
          ),
        ],
        border: Border.all(
          color: _outlineVariant.withAlpha(26), // 0.1 opacity
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: _outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 36,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -1,
                  color: _onSurface,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  suffix,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w300,
                    color: _onSurface.withAlpha(102), // 0.4 opacity
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _onSurfaceVariant.withAlpha(153), // 0.6 opacity
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSection() {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jadwal Hari Ini',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          color: _onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getFormattedDate(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: _onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SchedulePage(),
                        ),
                      );
                    },
                    child: Text(
                      'Lihat Semua',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Schedule Items from API
            if (state is ScheduleLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: _primary),
                ),
              )
            else if (state is ScheduleError)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Gagal memuat jadwal',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: _onSurfaceVariant,
                  ),
                ),
              )
            else if (state is ScheduleLoaded)
              if (state.schedules.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Tidak ada jadwal hari ini',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: _onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                // Show max 3 items on dashboard
                ...state.schedules.take(3).map((schedule) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildScheduleItemFromApi(schedule),
                  );
                }),
          ],
        );
      },
    );
  }

  /// Build schedule item from API data
  Widget _buildScheduleItemFromApi(ScheduleItem schedule) {
    // Convert JournalStatus to ScheduleStatus
    ScheduleStatus status;
    switch (schedule.statusJurnal) {
      case JournalStatus.done:
        status = ScheduleStatus.done;
        break;
      case JournalStatus.open:
        status = ScheduleStatus.open;
        break;
      case JournalStatus.locked:
        status = ScheduleStatus.locked;
        break;
    }

    return _buildScheduleItem(
      time: schedule.timeSlot.startTime,
      period: schedule.keterangan ?? '',
      title: schedule.subject,
      subtitle: 'Kelas ${schedule.className}',
      status: status,
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final days = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
    ];
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agt',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${days[now.weekday % 7]}, ${now.day} ${months[now.month - 1]}';
  }

  Widget _buildScheduleItem({
    required String time,
    required String period,
    required String title,
    required String subtitle,
    required ScheduleStatus status,
  }) {
    final isOpen = status == ScheduleStatus.open;
    final isDone = status == ScheduleStatus.done;
    final isLocked = status == ScheduleStatus.locked;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isOpen ? _surfaceContainerLowest : _surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: isOpen
            ? Border.all(color: _primary.withAlpha(26), width: 1)
            : null,
        boxShadow: isOpen
            ? [
                BoxShadow(
                  color: const Color(0xFF131B2E).withAlpha(10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Opacity(
        opacity: isLocked ? 0.6 : 1.0,
        child: Row(
          children: [
            // Left accent bar for open item
            if (isOpen)
              Container(
                width: 4,
                height: 48,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: _primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            // Time
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isOpen
                    ? _primaryContainer.withAlpha(26)
                    : isDone
                    ? Colors.white
                    : const Color(0xFFE2E8F0), // slate-200
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDone
                    ? [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    time.split(':')[0],
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isOpen ? _primary : _outline,
                    ),
                  ),
                  Text(
                    time.split(':')[1],
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      color: isOpen ? _primary : _onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Status Badge
            _buildStatusBadge(status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(ScheduleStatus status) {
    Color bgColor;
    Color textColor;
    String label;
    IconData? icon;

    switch (status) {
      case ScheduleStatus.done:
        bgColor = const Color(0xFFDCFCE7); // green-100
        textColor = const Color(0xFF15803D); // green-700
        label = 'SELESAI';
        break;
      case ScheduleStatus.open:
        bgColor = _primary;
        textColor = Colors.white;
        label = 'AKTIF';
        break;
      case ScheduleStatus.locked:
        bgColor = const Color(0xFFE2E8F0); // slate-200
        textColor = const Color(0xFF64748B); // slate-500
        label = 'TERKUNCI';
        icon = Icons.lock;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJournalProgressCard(User? user) {
    if (user == null || !user.isWaliKelas) {
      return const SizedBox.shrink();
    }

    final total = _gradeCard?.total ?? 0;
    final completed = _gradeCard?.completed ?? 0;
    final progress = total == 0 ? 0.0 : completed / total;
    final percent = (progress * 100).toInt();
    final title = _gradeCard?.isLocked == true
        ? 'Penilaian Terkunci'
        : 'Penilaian Kelas Wali';
    final subtitle = _gradeCard == null
        ? 'Belum ada data penilaian'
        : '${_gradeCard!.classId} • ${_gradeCard!.subjectName}';

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E7FF), // surface-container-high
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          // Decorative blur circle
          Positioned(
            right: -48,
            bottom: -48,
            child: Container(
              width: 192,
              height: 192,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _tertiary.withAlpha(13), // 0.05 opacity
              ),
            ),
          ),
          // Content
          Row(
            children: [
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                        color: const Color(
                          0xFF0035BD,
                        ), // on-secondary-fixed-variant
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF394B96),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Progress Bar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF07006C,
                              ).withAlpha(26), // 0.1 opacity
                              borderRadius: BorderRadius.circular(9999),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _tertiary,
                                  borderRadius: BorderRadius.circular(9999),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$percent%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Action Button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const GradeSetupPage(),
                          ),
                        ).then((_) {
                          _gradeLoadedForUserId = null;
                          _ensureGradeCard(user);
                        });
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _gradeCard?.isLocked == true
                                  ? 'Lihat Hasil Nilai'
                                  : 'Lanjutkan Input Nilai',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: const Color(
                                  0xFF07006C,
                                ), // on-secondary-fixed
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.play_circle,
                            size: 18,
                            color: Color(0xFF07006C),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              // Circular Progress
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background Circle
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        value: 1,
                        strokeWidth: 8,
                        backgroundColor: Colors.white.withAlpha(
                          51,
                        ), // 0.2 opacity
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.white.withAlpha(51),
                        ),
                      ),
                    ),
                    // Progress Circle
                    SizedBox(
                      width: 96,
                      height: 96,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 8,
                        backgroundColor: Colors.transparent,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          _tertiary,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    // Center Text
                    Text(
                      _gradeLoading ? '...' : '$completed/$total',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF07006C),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleCheckIn() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CheckInPage(),
    );
    // BLoC will handle the submission and update UI via listener
  }

  String _attendanceBadgeText() {
    if (!isCheckedIn) return 'BELUM CHECK-IN';
    if (_isPresent == false) {
      if (_isSakitReason) return 'IZIN SAKIT';
      if (_isDinasLuarReason) return 'DINAS LUAR';
      if (_isIzinReason) return 'IZIN';
      return 'TIDAK HADIR';
    }
    return 'SUDAH HADIR';
  }

  String _attendanceTitleText() {
    if (!isCheckedIn) return 'Konfirmasi Kehadiran';
    if (_isPresent == false) {
      if (_isSakitReason) return 'Semoga Lekas Sembuh';
      if (_isDinasLuarReason) return 'Tugas Dinas Tercatat';
      if (_isIzinReason) return 'Izin Tercatat';
      return 'Ketidakhadiran Tercatat';
    }
    return 'Selamat Mengajar!';
  }

  String _attendanceSubtitleText() {
    if (!isCheckedIn) return 'Tap tombol untuk check-in';
    if (_isPresent == false) {
      if (_isSakitReason) return 'Anda tercatat izin sakit hari ini';
      if (_isDinasLuarReason) return 'Anda tercatat dinas luar hari ini';
      if (_isIzinReason) return 'Anda tercatat izin hari ini';
      return 'Status ketidakhadiran Anda sudah tercatat';
    }
    return 'Anda sudah check-in hari ini';
  }

  String _attendanceActionText() {
    if (!isCheckedIn) return 'Presensi';
    if (_isPresent == false) {
      if (_isSakitReason) return 'Sakit';
      if (_isDinasLuarReason) return 'Dinas Luar';
      if (_isIzinReason) return 'Izin';
      return 'Tidak Hadir';
    }
    return 'Hadir';
  }

  String get _normalizedReason =>
      (_attendanceReason ?? '').trim().toLowerCase();
  bool get _isSakitReason => _normalizedReason.contains('sakit');
  bool get _isIzinReason => _normalizedReason.contains('izin');
  bool get _isDinasLuarReason =>
      _normalizedReason.contains('dinas') || _normalizedReason.contains('luar');
}

enum ScheduleStatus { done, open, locked }
