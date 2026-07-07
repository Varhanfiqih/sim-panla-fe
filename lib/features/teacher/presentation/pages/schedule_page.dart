import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../auth/presentation/bloc/bloc.dart';
import '../../../auth/data/models/user.dart';
import '../../data/models/schedule.dart';
import '../bloc/bloc.dart';
import 'journal_student_list_page.dart';
import 'journal_history_detail_page.dart';
import 'notification_page.dart';

/// Schedule Page - Following stitch design (s_05_schedule_screen_new_style)
class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  int? _notifStartedForUserId;

  // Colors from stitch design
  static const Color _primary = Color(0xFF0040DF);
  static const Color _primaryContainer = Color(0xFF2D5BFF);
  static const Color _surface = Color(0xFFFAF8FF);
  static const Color _surfaceContainerHigh = Color(0xFFE2E7FF);
  static const Color _surfaceContainerHighest = Color(0xFFDAE2FD);
  static const Color _onSurface = Color(0xFF131B2E);
  static const Color _onSurfaceVariant = Color(0xFF434655);
  static const Color _outline = Color(0xFF737686);
  static const Color _outlineVariant = Color(0xFFC3C6D7);
  static const Color _primaryFixed = Color(0xFFDDE1FF);
  static const Color _onPrimaryFixedVariant = Color(0xFF0035BD);
  static const Color _tertiaryFixed = Color(0xFFF0DBFF);
  static const Color _onTertiaryFixedVariant = Color(0xFF6900B3);
  static const Color _errorContainer = Color(0xFFFFDAD6);
  static const Color _onErrorContainer = Color(0xFF93000A);

  Future<void> _onRefresh() async {
    final scheduleBloc = context.read<ScheduleBloc>();
    String? dateParam;

    final currentState = scheduleBloc.state;
    if (currentState is ScheduleLoaded) {
      final d = currentState.selectedDate;
      dateParam =
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    scheduleBloc.add(LoadSchedules(date: dateParam));
    await scheduleBloc.stream.firstWhere(
      (state) => state is ScheduleLoaded || state is ScheduleError,
    );
  }

  void _ensureNotificationRealtime(User? user) {
    if (user == null) return;
    if (_notifStartedForUserId == user.id) return;

    _notifStartedForUserId = user.id;
    context.read<NotificationBloc>().add(NotificationStarted(user.id));
  }

  @override
  void initState() {
    super.initState();
    // Load today's schedule
    context.read<ScheduleBloc>().add(const LoadSchedules());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        User? user;
        if (authState is AuthAuthenticated) {
          user = authState.user;
          _ensureNotificationRealtime(user);
        }

        final topPadding = MediaQuery.of(context).padding.top;
        final appBarHeight = topPadding + 72;

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
                          // Header Section
                          _buildHeaderSection(),
                          const SizedBox(height: 32),

                          // Date Picker
                          _buildDatePicker(),
                          const SizedBox(height: 32),

                          // Schedule Timeline
                          _buildScheduleTimeline(),
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
              color: Colors.white.withAlpha(179),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF131B2E).withAlpha(15),
                  blurRadius: 40,
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: _surfaceContainerHigh,
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: _onSurface,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                // Title
                Expanded(
                  child: Text(
                    'Jadwal Mengajar',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: _onSurface,
                    ),
                  ),
                ),
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

  Widget _buildHeaderSection() {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        int scheduleCount = 0;
        String monthYear = _getMonthYear();

        if (state is ScheduleLoaded) {
          scheduleCount = state.schedules.length;
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jadwal',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    height: 1,
                    color: _onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Anda memiliki $scheduleCount jadwal hari ini',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _tertiaryFixed,
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                monthYear.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: _onTertiaryFixedVariant,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _getMonthYear() {
    final selectedDate = _selectedDate();
    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${months[selectedDate.month - 1]} ${selectedDate.year}';
  }

  DateTime _selectedDate() {
    final state = context.read<ScheduleBloc>().state;
    if (state is ScheduleLoaded) {
      return state.selectedDate;
    }

    return DateTime.now();
  }

  String _formatDateParam(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  void _reloadSelectedDate() {
    context.read<ScheduleBloc>().add(
      LoadSchedules(date: _formatDateParam(_selectedDate())),
    );
  }

  Widget _buildDatePicker() {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        DateTime selectedDate = DateTime.now();
        if (state is ScheduleLoaded) {
          selectedDate = state.selectedDate;
        }

        // Generate dates around the selected date so the picker does not jump
        // back to today after choosing another day.
        final dates = List.generate(7, (index) {
          return selectedDate.add(Duration(days: index - 3));
        });

        return SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: dates.length,
            itemBuilder: (context, index) {
              final date = dates[index];
              final isSelected = _isSameDay(date, selectedDate);
              final isToday = _isSameDay(date, DateTime.now());

              return Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : 8,
                  right: index == dates.length - 1 ? 0 : 8,
                ),
                child: _buildDateItem(date, isSelected, isToday),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildDateItem(DateTime date, bool isSelected, bool isToday) {
    final dayNames = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    final dayName = dayNames[date.weekday % 7];

    return GestureDetector(
      onTap: () {
        context.read<ScheduleBloc>().add(ChangeDate(date));
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isSelected ? 72 : 64,
        height: isSelected ? 112 : 96,
        margin: EdgeInsets.only(top: isSelected ? 0 : 8),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primary, _primaryContainer],
                )
              : null,
          color: isSelected ? null : _surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primary.withAlpha(51),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: isSelected
                    ? Colors.white.withAlpha(204)
                    : _onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              date.day.toString(),
              style: GoogleFonts.plusJakartaSans(
                fontSize: isSelected ? 24 : 20,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : _onSurface,
              ),
            ),
            if (isToday && isSelected) ...[
              const SizedBox(height: 8),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildScheduleTimeline() {
    return BlocBuilder<ScheduleBloc, ScheduleState>(
      builder: (context, state) {
        if (state is ScheduleLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(48),
              child: CircularProgressIndicator(color: _primary),
            ),
          );
        }

        if (state is ScheduleError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: Column(
                children: [
                  Icon(Icons.error_outline, size: 48, color: _outline),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: _onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      context.read<ScheduleBloc>().add(const LoadSchedules());
                    },
                    child: Text(
                      'Coba Lagi',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: _primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is ScheduleLoaded) {
          if (state.schedules.isEmpty) {
            return _buildEmptyState();
          }

          return Stack(
            children: [
              // Vertical timeline line
              Positioned(
                left: 23,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 2,
                  decoration: BoxDecoration(
                    color: _outlineVariant.withAlpha(51),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              // Schedule items
              Column(
                children: state.schedules.asMap().entries.map((entry) {
                  final index = entry.key;
                  final schedule = entry.value;
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == state.schedules.length - 1 ? 0 : 24,
                    ),
                    child: _buildTimelineItem(schedule),
                  );
                }).toList(),
              ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _surfaceContainerHigh,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(Icons.event_busy_outlined, size: 40, color: _outline),
            ),
            const SizedBox(height: 24),
            Text(
              'Tidak ada jadwal',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: _onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Anda tidak memiliki jadwal mengajar pada tanggal yang dipilih',
              style: GoogleFonts.inter(fontSize: 14, color: _onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(ScheduleItem schedule) {
    bool isDone = schedule.statusJurnal == JournalStatus.done;
    bool isOpen = schedule.statusJurnal == JournalStatus.open;
    bool isLocked = schedule.statusJurnal == JournalStatus.locked;

    // OVERRIDE DARI FRONTEND: Cek apakah user sudah absen masuk hari ini.
    // Ini memastikan tombol tetap terkunci meskipun API Production mengembalikan 'OPEN'.
    final attState = context.read<AttendanceBloc>().state;
    if (attState is AttendanceStatusLoaded &&
        !attState.hasCheckedIn &&
        isOpen) {
      isOpen = false;
      isLocked = true;
      schedule = ScheduleItem(
        id: schedule.id,
        statusJurnal: JournalStatus.locked,
        subject: schedule.subject,
        className: schedule.className,
        timeSlot: schedule.timeSlot,
        keterangan: 'Belum Check-In',
        journalId: schedule.journalId,
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Container(
          width: 48,
          height: 48,
          margin: const EdgeInsets.only(top: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isOpen
                ? _primary
                : isDone
                ? _surfaceContainerHighest
                : _surfaceContainerHigh,
            border: Border.all(color: _surface, width: 4),
            boxShadow: isOpen
                ? [
                    BoxShadow(
                      color: _primary.withAlpha(77),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Icon(
            isDone
                ? Icons.check_circle
                : isOpen
                ? Icons.play_arrow
                : Icons.lock,
            color: isOpen
                ? Colors.white
                : isDone
                ? _primary
                : _onSurfaceVariant,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        // Card content
        Expanded(child: _buildScheduleCard(schedule, isDone, isOpen, isLocked)),
      ],
    );
  }

  Widget _buildScheduleCard(
    ScheduleItem schedule,
    bool isDone,
    bool isOpen,
    bool isLocked,
  ) {
    // Override lagi di dalam card jika state masih OPEN (kalau _buildScheduleCard dipanggil langsung tanpa lewat _buildTimelineItem)
    final attState = context.read<AttendanceBloc>().state;
    if (attState is AttendanceStatusLoaded &&
        !attState.hasCheckedIn &&
        isOpen) {
      isOpen = false;
      isLocked = true;
    }
    return Opacity(
      opacity: isLocked ? 0.6 : 1.0,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(179),
          borderRadius: BorderRadius.circular(16),
          border: isOpen
              ? Border.all(color: _primaryContainer.withAlpha(51), width: 1)
              : Border.all(color: _outlineVariant.withAlpha(51), width: 1),
          boxShadow: isOpen
              ? [
                  BoxShadow(
                    color: const Color(0xFF131B2E).withAlpha(31),
                    blurRadius: 40,
                  ),
                ]
              : [
                  BoxShadow(
                    color: const Color(0xFF131B2E).withAlpha(15),
                    blurRadius: 40,
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${schedule.timeSlot.startTime} — ${schedule.timeSlot.endTime}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    color: isOpen ? _primary : _onSurfaceVariant,
                  ),
                ),
                _buildStatusBadge(schedule.statusJurnal),
              ],
            ),
            const SizedBox(height: 12),
            // Subject name
            Text(
              schedule.subject,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: _onSurface,
              ),
            ),
            const SizedBox(height: 8),
            // Class info
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: _onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Kelas ${schedule.className}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: _onSurfaceVariant,
                  ),
                ),
                if (schedule.keterangan != null &&
                    schedule.keterangan!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _tertiaryFixed,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      schedule.keterangan!,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: _onTertiaryFixedVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            // Action button for OPEN or LOCKED status
            if (isOpen || isLocked) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (isLocked) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            schedule.keterangan ??
                                'Silakan Check-In terlebih dahulu.',
                          ),
                          backgroundColor: _errorContainer,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    } else if (isOpen) {
                      Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => JournalStudentListPageWithFAB(
                            scheduleId: schedule.id,
                            className: schedule.className,
                            subjectName: schedule.subject,
                            timeSlot:
                                '${schedule.timeSlot.startTime} - ${schedule.timeSlot.endTime}',
                            journalDate: _formatDateParam(_selectedDate()),
                          ),
                        ),
                      ).then((submitted) {
                        if (!mounted) return;
                        if (submitted == true) {
                          _reloadSelectedDate();
                        }
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOpen ? _primary : Colors.grey.shade300,
                    foregroundColor: isOpen
                        ? Colors.white
                        : Colors.grey.shade600,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isLocked ? 'Terkunci (Belum Check-In)' : 'Isi Jurnal',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
            // Action button for DONE status
            if (isDone) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    // Navigate to Journal History Detail Page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => JournalHistoryDetailPage(
                          journalId: schedule.journalId ?? 0,
                          subjectName: schedule.subject,
                          className: schedule.className,
                          date: _formatDateParam(_selectedDate()),
                          timeSlot:
                              '${schedule.timeSlot.startTime} - ${schedule.timeSlot.endTime}',
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primary,
                    side: const BorderSide(color: _primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Lihat Riwayat Jurnal',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(JournalStatus status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case JournalStatus.done:
        bgColor = _surfaceContainerHigh;
        textColor = _onSurfaceVariant;
        label = 'SELESAI';
        break;
      case JournalStatus.open:
        bgColor = _primaryFixed;
        textColor = _onPrimaryFixedVariant;
        label = 'AKTIF';
        break;
      case JournalStatus.locked:
        bgColor = _errorContainer;
        textColor = _onErrorContainer;
        label = 'TERKUNCI';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: textColor,
        ),
      ),
    );
  }
}
