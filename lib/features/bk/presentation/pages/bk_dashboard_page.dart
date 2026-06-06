import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/dio_client.dart';
import '../../../auth/data/models/user.dart';
import '../../../auth/presentation/bloc/bloc.dart';
import '../../../teacher/data/models/permission.dart';
import '../../../teacher/presentation/bloc/bloc.dart';
import '../../../teacher/presentation/pages/check_in_page.dart';
import '../../../teacher/presentation/pages/inval/inval_page.dart';
import '../../../teacher/presentation/pages/profile_page.dart';
import '../../../teacher/presentation/pages/qr_scanner_page.dart';
import '../../../teacher/presentation/pages/schedule_page.dart';
import '../../../teacher/presentation/bloc/permission/permission_bloc.dart';
import '../../../teacher/presentation/bloc/permission/permission_event.dart';
import '../../../teacher/presentation/bloc/permission/permission_state.dart';

class BkDashboardPage extends StatefulWidget {
  const BkDashboardPage({super.key});

  @override
  State<BkDashboardPage> createState() => _BkDashboardPageState();
}

class _BkDashboardPageState extends State<BkDashboardPage> {
  final Dio _dio = DioClient().dio;

  int _selectedNavIndex = 0;
  String _approvalFilter = 'Semua';
  bool _bkDataLoaded = false;
  bool _bkLoading = false;
  bool _hasCheckedIn = false;
  bool? _isPresent;
  String? _attendanceReason;
  late final ValueNotifier<DateTime> _nowNotifier;
  Timer? _clockTimer;

  List<_BkClassSummary> _classSummaries = const [];
  List<_BkWatchStudent> _watchStudents = const [];
  List<_BkStudentOption> _bkStudents = const [];
  List<_BkActionLog> _bkActions = const [];

  String _watchClassFilter = 'Semua';
  String _gradeFilter = 'All';

  static const int _lateThreshold = 3;
  static const int _alpaThreshold = 3;

  static const Color _primary = Color(0xFF2250E8);
  static const Color _primaryAlt = Color(0xFF3B6AF8);
  static const Color _bg = Color(0xFFF6F7FC);
  static const Color _ink = Color(0xFF121826);
  static const Color _muted = Color(0xFF8A93A8);
  static const Color _line = Color(0xFFE8ECF7);

  @override
  void initState() {
    super.initState();
    _nowNotifier = ValueNotifier<DateTime>(DateTime.now());
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _nowNotifier.value = DateTime.now();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<PermissionBloc>().add(LoadPermissions());
      context.read<AttendanceBloc>().add(const CheckAttendanceStatus());
      _loadBkData();
    });
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

  Future<void> _loadBkData() async {
    if (!mounted) return;
    setState(() => _bkLoading = true);

    try {
      final responses = await Future.wait([
        _dio.get('/bk/monitoring'),
        _dio.get('/bk/absentees'),
        _dio.get('/bk/actions'),
        _dio.get('/bk/students'),
      ]);

      final monitoring = responses[0].data;
      final absentees = responses[1].data;
      final actions = responses[2].data;
      final students = responses[3].data;
      final classData = (monitoring['data'] as List<dynamic>? ?? const [])
          .map((e) => _BkClassSummary.fromJson(e as Map<String, dynamic>))
          .toList();

      final watchData = (absentees['data'] as List<dynamic>? ?? const [])
          .map((e) => _BkWatchStudent.fromJson(e as Map<String, dynamic>))
          .toList();
      final actionData = (actions['data'] as List<dynamic>? ?? const [])
          .map((e) => _BkActionLog.fromJson(e as Map<String, dynamic>))
          .toList();
      final studentData = (students['data'] as List<dynamic>? ?? const [])
          .map((e) => _BkStudentOption.fromJson(e as Map<String, dynamic>))
          .where((e) => e.id > 0)
          .toList();

      if (!mounted) return;
      setState(() {
        _classSummaries = classData;
        _watchStudents = watchData;
        _bkActions = actionData;
        _bkStudents = studentData;
        _bkDataLoaded = true;
        _bkLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _bkDataLoaded = true;
        _bkLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data BK belum bisa dimuat sepenuhnya.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AttendanceBloc, AttendanceState>(
      listener: (context, state) {
        if (state is AttendanceStatusLoaded) {
          setState(() {
            _hasCheckedIn = state.hasCheckedIn;
            _isPresent = state.isPresent;
            _attendanceReason = state.reason;
          });
        } else if (state is AttendanceCheckInSuccess) {
          setState(() {
            _hasCheckedIn = true;
            _isPresent = state.attendance.status == 'hadir';
            _attendanceReason = state.attendance.reason;
          });
          context.read<ScheduleBloc>().add(const LoadSchedules());
        } else if (state is AttendanceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          User? user;
          if (authState is AuthAuthenticated) {
            user = authState.user;
          }

          final topPadding = MediaQuery.of(context).padding.top;
          final appBarHeight = topPadding + 72;

          final permissionState = context.watch<PermissionBloc>().state;
          final allPermissions = _extractPermissions(permissionState);
          final pendingBk = allPermissions
              .where((p) => p.isSubmittedToBk)
              .toList();
          final verifiedBk = allPermissions
              .where((p) => p.isVerifiedByBk)
              .toList();
          final approvedFinal = allPermissions
              .where((p) => p.isApprovedFinal)
              .toList();
          final rejected = allPermissions.where((p) => p.isRejected).toList();

          return Scaffold(
            backgroundColor: _bg,
            body: Stack(
              children: [
                _buildActiveTab(
                  user,
                  appBarHeight,
                  permissionState,
                  allPermissions,
                  pendingBk,
                  verifiedBk,
                  approvedFinal,
                  rejected,
                ),
                if (_selectedNavIndex <= 2) _buildTopBar(user),
                _buildBottomNavBar(),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Permission> _extractPermissions(PermissionState state) {
    if (state is PermissionLoaded) return state.permissions;
    return const [];
  }

  Widget _buildActiveTab(
    User? user,
    double appBarHeight,
    PermissionState permissionState,
    List<Permission> allPermissions,
    List<Permission> pendingBk,
    List<Permission> verifiedBk,
    List<Permission> approvedFinal,
    List<Permission> rejected,
  ) {
    if (_selectedNavIndex == 1) {
      return _buildApprovalTab(
        appBarHeight,
        permissionState,
        allPermissions,
        pendingBk,
      );
    }
    if (_selectedNavIndex == 2) {
      return _buildActionTab(appBarHeight, allPermissions, pendingBk);
    }
    if (_selectedNavIndex == 3) {
      return const ProfilePage();
    }
    if (_selectedNavIndex == 4) {
      return const SchedulePage();
    }
    if (_selectedNavIndex == 5) {
      return BlocProvider(
        create: (_) => QrScanBloc(),
        child: const QrScannerPage(),
      );
    }
    if (_selectedNavIndex == 6) {
      return const InvalPage();
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: appBarHeight + 14)),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 140),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildHero(),
              const SizedBox(height: 14),
              _buildCheckInCard(),
              const SizedBox(height: 14),
              _buildStatGrid(
                pendingBkCount: pendingBk.length,
                verifiedBkCount: verifiedBk.length,
                approvedCount: approvedFinal.length,
                rejectedCount: rejected.length,
              ),
              const SizedBox(height: 16),
              _buildQuickMenu(pendingBk.length),
              const SizedBox(height: 16),
              _buildPriorityList(pendingBk),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(User? user) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 12,
              16,
              12,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.86),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF111827).withValues(alpha: 0.06),
                  blurRadius: 30,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF0FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user?.shortName.substring(0, 1).toUpperCase() ?? 'B',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: _primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${_getGreeting()}, ${user?.shortName ?? 'Konselor'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: _ink,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: Color(0xFF2250E8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckInCard() {
    final isPresent = _hasCheckedIn && _isPresent == true;
    final isAbsent = _hasCheckedIn && _isPresent == false;
    final color = isPresent
        ? const Color(0xFF0F9D78)
        : isAbsent
        ? const Color(0xFFDC2626)
        : const Color(0xFFE57A00);
    final title = isPresent
        ? 'Sudah Check-In'
        : isAbsent
        ? 'Tercatat Tidak Hadir'
        : 'Belum Check-In';
    final description = isPresent
        ? 'Jurnal mengajar sudah dapat diisi.'
        : isAbsent
        ? (_attendanceReason ?? 'Jurnal mengajar dikunci hari ini.')
        : 'Lakukan presensi guru sebelum mengisi jurnal harian.';

    return InkWell(
      onTap: _hasCheckedIn ? null : _openCheckIn,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ValueListenableBuilder<DateTime>(
              valueListenable: _nowNotifier,
              builder: (context, now, _) {
                return Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(now),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _muted,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.access_time_rounded,
                      size: 15,
                      color: _muted,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      DateFormat('HH:mm:ss').format(now),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isPresent
                        ? Icons.check_circle_rounded
                        : isAbsent
                        ? Icons.cancel_rounded
                        : Icons.fingerprint_rounded,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description,
                        style: GoogleFonts.inter(fontSize: 12, color: _muted),
                      ),
                    ],
                  ),
                ),
                if (! _hasCheckedIn)
                  const Icon(Icons.chevron_right_rounded, color: _muted),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCheckIn() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => const CheckInPage(),
    );

    if (!mounted) return;
    context.read<AttendanceBloc>().add(const CheckAttendanceStatus());
    context.read<ScheduleBloc>().add(const LoadSchedules());
  }

  void _openJournalMenu() {
    if (! _hasCheckedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan check-in presensi guru terlebih dahulu.'),
        ),
      );
      _openCheckIn();
      return;
    }

    if (_isPresent != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Jurnal terkunci karena Anda tercatat tidak hadir.'),
        ),
      );
      return;
    }

    setState(() => _selectedNavIndex = 4);
  }

  Widget _buildHero() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _primaryAlt],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'OVERVIEW BK',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pusat Layanan Konseling',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 28,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Flow izin: guru submit -> pending BK -> lanjut approval final.',
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid({
    required int pendingBkCount,
    required int verifiedBkCount,
    required int approvedCount,
    required int rejectedCount,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.pending_actions_rounded,
                value: '$pendingBkCount',
                label: 'Pending BK',
                tone: const Color(0xFF2250E8),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                icon: Icons.verified_rounded,
                value: '$verifiedBkCount',
                label: 'Terverifikasi BK',
                tone: const Color(0xFF16A34A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statCard(
                icon: Icons.task_alt_rounded,
                value: '$approvedCount',
                label: 'Disetujui Final',
                tone: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _statCard(
                icon: Icons.cancel_outlined,
                value: '$rejectedCount',
                label: 'Ditolak',
                tone: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
    required Color tone,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: tone, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: _ink,
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              color: _muted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickMenu(int pendingCount) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _menuTile(
                  icon: Icons.fact_check_rounded,
                  label: 'Approval Izin ($pendingCount)',
                  desc: 'Verifikasi awal BK',
                  color: const Color(0xFF2250E8),
                  onTap: () => setState(() => _selectedNavIndex = 1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _menuTile(
                  icon: Icons.rule_folder_outlined,
                  label: 'Monitoring Kelas',
                  desc: 'Pantau & tindakan BK',
                  color: const Color(0xFF7C3AED),
                  onTap: () => setState(() => _selectedNavIndex = 2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _menuTile(
                  icon: Icons.menu_book_rounded,
                  label: 'Jurnal Mengajar',
                  desc: 'Jadwal & jurnal kelas',
                  color: const Color(0xFF0F9D78),
                  onTap: _openJournalMenu,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _menuTile(
                  icon: Icons.event_available_rounded,
                  label: 'Jadwal Inval',
                  desc: 'Lihat dan klaim kelas kosong',
                  color: const Color(0xFFDB2777),
                  onTap: () => setState(() => _selectedNavIndex = 6),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required String desc,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              desc,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: _muted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriorityList(List<Permission> pendingBk) {
    final topPending = pendingBk.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Prioritas Pending BK',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _selectedNavIndex = 1),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (topPending.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _line),
              ),
              child: Text(
                'Belum ada pengajuan yang menunggu verifikasi BK.',
                style: GoogleFonts.inter(color: _muted, fontSize: 13),
              ),
            )
          else
            ...topPending.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              return Padding(
                padding: EdgeInsets.only(
                  bottom: idx == topPending.length - 1 ? 0 : 10,
                ),
                child: _priorityItem(
                  initials: _initials(item.student.name),
                  name: item.student.name,
                  meta:
                      '${item.totalHari} hari • ${item.type.toUpperCase()} • ${item.student.classId}',
                  badge: 'Pending BK',
                  badgeColor: const Color(0xFF6D28D9),
                  badgeBg: const Color(0xFFEDE9FE),
                ),
              );
            }),
        ],
      ),
    );
  }

  String _initials(String fullName) {
    final parts = fullName
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .take(2)
        .toList();
    if (parts.isEmpty) return 'BK';
    return parts.map((e) => e[0]).join().toUpperCase();
  }

  Widget _priorityItem({
    required String initials,
    required String name,
    required String meta,
    required String badge,
    required Color badgeColor,
    required Color badgeBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE2E8F5),
            child: Text(
              initials,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2B4CC8),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                Text(
                  meta,
                  style: GoogleFonts.inter(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badge,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom > 0
          ? MediaQuery.of(context).padding.bottom + 12
          : 20,
      left: 0,
      right: 0,
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_primary, _primaryAlt],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildNavItem(
                    targetIndex: 0,
                    icon: Icons.home_rounded,
                    selectedIndexes: const {0},
                  ),
                  const SizedBox(width: 8),
                  _buildNavItem(
                    targetIndex: 4,
                    icon: Icons.menu_book_rounded,
                    selectedIndexes: const {4, 6},
                    onTap: _openJournalMenu,
                  ),
                  const SizedBox(width: 8),
                  _buildNavItem(
                    targetIndex: 5,
                    icon: Icons.qr_code_scanner_rounded,
                    selectedIndexes: const {5},
                    isPrimary: true,
                  ),
                  const SizedBox(width: 8),
                  _buildNavItem(
                    targetIndex: 1,
                    icon: Icons.fact_check_rounded,
                    selectedIndexes: const {1, 2},
                  ),
                  const SizedBox(width: 8),
                  _buildNavItem(
                    targetIndex: 3,
                    icon: Icons.person_rounded,
                    selectedIndexes: const {3},
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int targetIndex,
    required IconData icon,
    required Set<int> selectedIndexes,
    bool isPrimary = false,
    VoidCallback? onTap,
  }) {
    final isSelected = selectedIndexes.contains(_selectedNavIndex);
    return GestureDetector(
      onTap: onTap ?? () => setState(() => _selectedNavIndex = targetIndex),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(isPrimary ? 15 : 12),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isPrimary ? 18 : 16),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: isPrimary ? 25 : 22,
          color: isSelected ? _primary : Colors.white.withValues(alpha: 0.85),
        ),
      ),
    );
  }

  Widget _buildApprovalTab(
    double appBarHeight,
    PermissionState permissionState,
    List<Permission> allPermissions,
    List<Permission> pendingBk,
  ) {
    final successToday = allPermissions.where((p) => p.isApprovedFinal).length;
    final visitToday = pendingBk.length > 4 ? 4 : pendingBk.length;
    final reviewByFilter = _filterApprovalItems(allPermissions);

    return RefreshIndicator(
      onRefresh: () async {
        context.read<PermissionBloc>().add(LoadPermissions());
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, appBarHeight + 14, 16, 140),
        children: [
          Text(
            'RINGKASAN',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: const Color(0xFF8A93A8),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Alur Persetujuan Izin',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: _ink,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          _pipelineCard(
            icon: Icons.fact_check_rounded,
            value: pendingBk.length.toString(),
            subtitle: 'PENGAJUAN MENUNGGU VERIFIKASI',
            titleColor: Colors.white,
            subtitleColor: Colors.white.withValues(alpha: 0.85),
            background: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2250E8), Color(0xFF2D5BFF)],
            ),
            showPulse: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _miniPipelineCard(
                  icon: Icons.task_alt_rounded,
                  value: '$successToday',
                  subtitle: 'DISETUJUI HARI INI',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _miniPipelineCard(
                  icon: Icons.home_work_outlined,
                  value: '$visitToday',
                  subtitle: 'KUNJUNGAN BK HARI INI',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _approvalFilterBar(),
          const SizedBox(height: 12),
          if (permissionState is PermissionLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (permissionState is PermissionError)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _line),
              ),
              child: Text(
                'Gagal memuat data izin. Tarik layar untuk memuat ulang.',
                style: GoogleFonts.inter(color: const Color(0xFFB91C1C)),
              ),
            )
          else if (reviewByFilter.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _line),
              ),
              child: Text(
                'Tidak ada data izin pada filter ini.',
                style: GoogleFonts.inter(color: _muted),
              ),
            )
          else
            ...reviewByFilter.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _approvalItem(item),
              ),
            ),
        ],
      ),
    );
  }

  Widget _pipelineCard({
    required IconData icon,
    required String value,
    required String subtitle,
    required Color titleColor,
    required Color subtitleColor,
    required Gradient background,
    bool showPulse = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ),
          if (showPulse)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'AKTIF',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _miniPipelineCard({
    required IconData icon,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF2FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF2B4CC8)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                    color: const Color(0xFF7A8196),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _approvalFilterBar() {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterPill('Semua'),
          const SizedBox(width: 8),
          _filterPill('Menunggu BK'),
          const SizedBox(width: 8),
          _filterPill('Disetujui'),
          const SizedBox(width: 8),
          _filterPill('Ditolak'),
          const SizedBox(width: 8),
          _filterPill('Sakit'),
          const SizedBox(width: 8),
          _filterPill('Izin'),
          const SizedBox(width: 8),
          _filterPill('Hari Ini'),
        ],
      ),
    );
  }

  Widget _filterPill(String label) {
    final active = _approvalFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _approvalFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2250E8) : const Color(0xFFE8ECF9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF636B80),
          ),
        ),
      ),
    );
  }

  List<Permission> _filterApprovalItems(List<Permission> data) {
    if (_approvalFilter == 'Semua') return data;
    if (_approvalFilter == 'Menunggu BK') {
      return data.where((p) => p.isSubmittedToBk).toList();
    }
    if (_approvalFilter == 'Disetujui') {
      return data.where((p) => p.isApprovedFinal || p.isVerifiedByBk).toList();
    }
    if (_approvalFilter == 'Ditolak') {
      return data.where((p) => p.isRejected).toList();
    }
    if (_approvalFilter == 'Sakit') {
      return data.where((p) => p.type.toLowerCase() == 'sakit').toList();
    }
    if (_approvalFilter == 'Izin') {
      return data.where((p) => p.type.toLowerCase() == 'izin').toList();
    }
    if (_approvalFilter == 'Hari Ini') {
      final now = DateTime.now();
      return data.where((p) {
        final dt = DateTime.tryParse(p.createdAt)?.toLocal();
        if (dt == null) return false;
        return dt.year == now.year &&
            dt.month == now.month &&
            dt.day == now.day;
      }).toList();
    }
    return data;
  }

  Widget _approvalItem(Permission item) {
    final isPending = item.isSubmittedToBk;
    final status = _statusUi(item);
    final displayType = item.type.toLowerCase() == 'sakit' ? 'SAKIT' : 'IZIN';

    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: status.bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status.label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: status.fg,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF2FF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  displayType,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF2B4CC8),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _safeTime(item.createdAt),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: const Color(0xFF8A93A8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: const Color(0xFFE2E8F5),
                child: Text(
                  _initials(item.student.name),
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF2B4CC8),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.student.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: _ink,
                      ),
                    ),
                    Text(
                      '${item.student.classId} • #${item.id}',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: const Color(0xFF8A93A8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _showApprovalDetailBottomSheet(item),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFD9E0F2)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Text(
                    'Detail',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2250E8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: isPending
                      ? () {
                          context.read<PermissionBloc>().add(
                            ApprovePermissionByBk(item.id),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Memproses persetujuan BK...'),
                            ),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2250E8),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE2E8F0),
                    disabledForegroundColor: const Color(0xFF64748B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Text(
                    isPending ? 'Approve' : 'Selesai',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: isPending
                      ? () {
                          context.read<PermissionBloc>().add(
                            RejectPermissionByBk(item.id),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Memproses penolakan BK...'),
                            ),
                          );
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    foregroundColor: const Color(0xFFB91C1C),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: Text(
                    'Tolak',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (!isPending) {
      return card;
    }

    return Dismissible(
      key: ValueKey('approval-${item.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF16A34A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              'Approve BK',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 18),
        decoration: BoxDecoration(
          color: const Color(0xFFDC2626),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tolak BK',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.cancel_rounded, color: Colors.white),
          ],
        ),
      ),
      confirmDismiss: (direction) async {
        if (!mounted) return false;
        if (direction == DismissDirection.startToEnd) {
          context.read<PermissionBloc>().add(ApprovePermissionByBk(item.id));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Memproses persetujuan BK...')),
          );
        } else {
          context.read<PermissionBloc>().add(RejectPermissionByBk(item.id));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Memproses penolakan BK...')),
          );
        }
        return false;
      },
      child: card,
    );
  }

  ({String label, Color fg, Color bg}) _statusUi(Permission item) {
    if (item.isSubmittedToBk) {
      return (
        label: 'MENUNGGU BK',
        fg: const Color(0xFFB91C1C),
        bg: const Color(0xFFFEE2E2),
      );
    }
    if (item.isApprovedFinal || item.isVerifiedByBk) {
      return (
        label: 'DISETUJUI',
        fg: const Color(0xFF166534),
        bg: const Color(0xFFDCFCE7),
      );
    }
    if (item.isRejected) {
      return (
        label: 'DITOLAK',
        fg: const Color(0xFF991B1B),
        bg: const Color(0xFFFEE2E2),
      );
    }
    return (
      label: 'STATUS',
      fg: const Color(0xFF334155),
      bg: const Color(0xFFE2E8F0),
    );
  }

  void _showApprovalDetailBottomSheet(Permission item) {
    final notes = (item.keterangan ?? '').trim().isEmpty
        ? 'Tidak ada keterangan tambahan dari pengaju.'
        : item.keterangan!.trim();

    String dateRange = '-';
    final start = item.startDate == null
        ? null
        : DateTime.tryParse(item.startDate!);
    final end = item.endDate == null ? null : DateTime.tryParse(item.endDate!);
    if (start != null) {
      if (end != null && !end.isAtSameMomentAs(start)) {
        dateRange =
            '${DateFormat('dd MMM yyyy', 'id_ID').format(start)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(end)}';
      } else {
        dateRange = DateFormat('dd MMM yyyy', 'id_ID').format(start);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD3D9EA),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Detail Pengajuan',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _detailRow('Nama Siswa', item.student.name),
                  _detailRow('NIS', item.student.nis),
                  _detailRow('Kelas', item.student.classId),
                  _detailRow('Jenis', item.type.toUpperCase()),
                  _detailRow('Durasi', '${item.totalHari} hari'),
                  _detailRow('Rentang Tanggal', dateRange),
                  _detailRow('Diajukan', _formatDateTime(item.createdAt)),
                  _detailRow('Catatan Guru/Wali', notes),
                  _buildAttachmentSection(item.fotoUrl),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFD9E0F2)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: Text(
                            'Tutup',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2250E8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: item.isSubmittedToBk
                              ? () {
                                  Navigator.pop(ctx);
                                  context.read<PermissionBloc>().add(
                                    RejectPermissionByBk(item.id),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Memproses penolakan BK...',
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFFCA5A5)),
                            foregroundColor: const Color(0xFFB91C1C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: Text(
                            'Tolak',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: item.isSubmittedToBk
                              ? () {
                                  Navigator.pop(ctx);
                                  context.read<PermissionBloc>().add(
                                    ApprovePermissionByBk(item.id),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Memproses persetujuan BK...',
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2250E8),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFFE2E8F0),
                            disabledForegroundColor: const Color(0xFF64748B),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                            ),
                          ),
                          child: Text(
                            item.isSubmittedToBk ? 'Approve BK' : 'Selesai',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: const Color(0xFF8A93A8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(String raw) {
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
  }

  Widget _buildAttachmentSection(String? url) {
    final cleanUrl = (url ?? '').trim();
    if (cleanUrl.isEmpty) {
      return _detailRow('Lampiran', 'Tidak ada lampiran.');
    }

    final isImage = _isImageAttachment(cleanUrl);
    final fileName = _fileNameFromUrl(cleanUrl);

    if (isImage) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lampiran',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: const Color(0xFF8A93A8),
              ),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => _openAttachmentPreview(cleanUrl),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      cleanUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Text(
                          'Gagal memuat gambar lampiran.',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Lihat penuh',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              fileName,
              style: GoogleFonts.inter(
                color: const Color(0xFF475569),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Lampiran Dokumen',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: const Color(0xFF8A93A8),
            ),
          ),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.description_rounded, color: Color(0xFF2250E8)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        cleanUrl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openAttachmentPreview(cleanUrl),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: Text(
                'Buka Lampiran',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFD9E0F2)),
                foregroundColor: const Color(0xFF2250E8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool _isImageAttachment(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  String _fileNameFromUrl(String url) {
    final normalized = url.split('?').first;
    final parts = normalized.split('/');
    if (parts.isEmpty) return 'lampiran';
    return parts.last;
  }

  void _openAttachmentPreview(String url) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _AttachmentPreviewPage(url: url)),
    );
  }

  Widget _buildActionTab(
    double appBarHeight,
    List<Permission> allPermissions,
    List<Permission> pendingBk,
  ) {
    final totalAlpa = _classSummaries.fold<int>(
      0,
      (sum, k) => sum + k.totalAlpa,
    );
    final totalTerlambat = _classSummaries.fold<int>(
      0,
      (sum, k) => sum + k.totalTerlambat,
    );
    final totalIzin = allPermissions
        .where(
          (p) => {'izin', 'sakit', 'keluarga'}.contains(p.type.toLowerCase()),
        )
        .length;
    final pendingAction = _classSummaries
        .where(
          (k) =>
              k.totalAlpa >= _alpaThreshold ||
              k.totalTerlambat >= _lateThreshold,
        )
        .length;

    final classesByJenjang = _classesByJenjang();
    final classChips = [
      'All',
      ...classesByJenjang.map((e) => e.namaKelas),
    ];
    final activeClass = _watchClassFilter == 'Semua'
        ? 'All'
        : _watchClassFilter;
    final shownClasses = activeClass == 'All'
        ? classesByJenjang
        : classesByJenjang.where((k) => k.namaKelas == activeClass).toList();

    return ListView(
      padding: EdgeInsets.fromLTRB(16, appBarHeight + 14, 16, 140),
      children: [
        _tabTitle(
          'Monitoring Kelas',
          'Pantau kelas berdasarkan indikator harian.',
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _bkLoading ? null : () => _showCreateActionSheet(),
            icon: const Icon(Icons.add_task_rounded, size: 18),
            label: Text(
              'Tambah Tindakan BK',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2250E8),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _actionMetricCard(
                'Alpa',
                '$totalAlpa',
                const Color(0xFF111827),
                const Color(0xFFF1F3FA),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionMetricCard(
                'Terlambat',
                '$totalTerlambat',
                const Color(0xFF7C3AED),
                const Color(0xFFF1F3FA),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _actionMetricCard(
                'Izin',
                '$totalIzin',
                const Color(0xFF111827),
                const Color(0xFFF1F3FA),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionMetricCard(
                'Pending Action',
                '$pendingAction',
                Colors.white,
                const Color(0xFF2250E8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Classes Overview',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _watchChip(
                      label: 'All',
                      active: _gradeFilter == 'All',
                      onTap: () {
                        setState(() {
                          _gradeFilter = 'All';
                          _watchClassFilter = 'Semua';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _watchChip(
                      label: '7',
                      active: _gradeFilter == '7',
                      onTap: () {
                        setState(() {
                          _gradeFilter = '7';
                          _watchClassFilter = 'Semua';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _watchChip(
                      label: '8',
                      active: _gradeFilter == '8',
                      onTap: () {
                        setState(() {
                          _gradeFilter = '8';
                          _watchClassFilter = 'Semua';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    _watchChip(
                      label: '9',
                      active: _gradeFilter == '9',
                      onTap: () {
                        setState(() {
                          _gradeFilter = '9';
                          _watchClassFilter = 'Semua';
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final label = classChips[index];
                    return _watchChip(
                      label: label,
                      active: activeClass == label,
                      onTap: () {
                        setState(() {
                          _watchClassFilter = label == 'All' ? 'Semua' : label;
                        });
                      },
                    );
                  },
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemCount: classChips.length,
                ),
              ),
              const SizedBox(height: 12),
              if (_classSummaries.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5EAF7)),
                  ),
                  child: Text(
                    _bkDataLoaded
                        ? 'Belum ada data kelas untuk ditampilkan.'
                        : 'Memuat data kelas...',
                    style: GoogleFonts.inter(color: _muted, fontSize: 12),
                  ),
                )
              else
                ...shownClasses.map(
                  (k) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _classOverviewCard(k),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildActionHistorySection(),
      ],
    );
  }

  Widget _buildActionHistorySection() {
    final latestActions = _bkActions.take(8).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Riwayat Tindakan BK',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                ),
              ),
              const Spacer(),
              if (_bkLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (latestActions.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5EAF7)),
              ),
              child: Text(
                _bkDataLoaded
                    ? 'Belum ada tindakan BK yang tercatat.'
                    : 'Memuat riwayat tindakan BK...',
                style: GoogleFonts.inter(color: _muted, fontSize: 12),
              ),
            )
          else
            ...latestActions.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _actionHistoryItem(item),
              ),
            ),
        ],
      ),
    );
  }

  Widget _actionHistoryItem(_BkActionLog item) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFE2E8F5),
            child: Text(
              _initials(item.studentName),
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2B4CC8),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.actionLabel} • ${item.className} • ${item.date}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: const Color(0xFF8A93A8),
                  ),
                ),
                if (item.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    item.notes,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_BkClassSummary> _classesByJenjang() {
    final filtered = _classSummaries.where((k) {
      if (_gradeFilter == 'All') return true;
      return k.namaKelas.trim().startsWith(_gradeFilter);
    }).toList();
    filtered.sort((a, b) => a.namaKelas.compareTo(b.namaKelas));
    return filtered;
  }

  int _attendancePercent(_BkClassSummary k) {
    final penalty = (k.totalAlpa * 3) + (k.totalTerlambat * 2);
    final value = 100 - penalty;
    if (value < 0) return 0;
    if (value > 100) return 100;
    return value;
  }

  Widget _classOverviewCard(_BkClassSummary k) {
    final attendance = _attendancePercent(k);
    final urgent =
        k.totalAlpa >= _alpaThreshold || k.totalTerlambat >= _lateThreshold;

    final hue = (k.namaKelas.hashCode % 360).abs().toDouble();
    final avatarColorA = HSLColor.fromAHSL(1, hue, 0.55, 0.55).toColor();
    final avatarColorB = HSLColor.fromAHSL(
      1,
      (hue + 40) % 360,
      0.55,
      0.55,
    ).toColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FD),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8ECF7)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [avatarColorA, avatarColorB],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Class ${k.namaKelas}',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        color: _ink,
                        fontSize: 14,
                      ),
                    ),
                    if (urgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'URGENT',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFB91C1C),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '$attendance% Attendance',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF63708A),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A93A8)),
        ],
      ),
    );
  }

  Widget _watchChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF2250E8) : const Color(0xFFE8ECF9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : const Color(0xFF5B657D),
          ),
        ),
      ),
    );
  }

  Future<void> _showCreateActionSheet({_BkWatchStudent? initialStudent}) async {
    final studentOptions = _bkStudents.isNotEmpty
        ? _bkStudents
        : _watchStudents
              .map(
                (s) => _BkStudentOption(
                  id: s.studentId,
                  name: s.name,
                  nis: '',
                  classId: s.classId,
                ),
              )
              .where((s) => s.id > 0)
              .toList();

    if (studentOptions.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Daftar siswa BK belum tersedia.')),
      );
      return;
    }

    final notesController = TextEditingController();
    var selectedStudentId = initialStudent?.studentId ?? studentOptions.first.id;
    var selectedActionType = 'konseling';
    var selectedDate = DateTime.now();

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return StatefulBuilder(
            builder: (ctx, setModalState) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      16 + MediaQuery.of(ctx).viewInsets.bottom,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD3D9EA),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Form Tindakan BK',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          value: selectedStudentId,
                          isExpanded: true,
                          decoration: _inputDecoration('Siswa'),
                          items: studentOptions
                              .map(
                                (s) => DropdownMenuItem<int>(
                                  value: s.id,
                                  child: Text(
                                    '${s.name} • ${s.classId}',
                                    style: GoogleFonts.inter(fontSize: 13),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            if (v == null) return;
                            setModalState(() => selectedStudentId = v);
                          },
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: selectedActionType,
                          isExpanded: true,
                          decoration: _inputDecoration('Jenis Tindakan'),
                          items: const [
                            DropdownMenuItem(
                              value: 'konseling',
                              child: Text('Konseling'),
                            ),
                            DropdownMenuItem(
                              value: 'panggilan_ortu',
                              child: Text('Panggilan Orang Tua'),
                            ),
                            DropdownMenuItem(
                              value: 'home_visit',
                              child: Text('Home Visit'),
                            ),
                            DropdownMenuItem(
                              value: 'surat_peringatan',
                              child: Text('Surat Peringatan'),
                            ),
                            DropdownMenuItem(
                              value: 'lainnya',
                              child: Text('Lainnya'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setModalState(() => selectedActionType = v);
                          },
                        ),
                        const SizedBox(height: 10),
                        InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: ctx,
                              initialDate: selectedDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime.now().add(
                                const Duration(days: 1),
                              ),
                            );
                            if (picked == null) return;
                            setModalState(() => selectedDate = picked);
                          },
                          child: InputDecorator(
                            decoration: _inputDecoration('Tanggal Kejadian'),
                            child: Text(
                              DateFormat(
                                'dd MMM yyyy',
                                'id_ID',
                              ).format(selectedDate),
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: notesController,
                          maxLines: 4,
                          decoration: _inputDecoration('Catatan Tindakan').copyWith(
                            hintText:
                                'Contoh: Konseling awal, siswa mengakui alasan bolos...',
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Color(0xFFD9E0F2),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Batal',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2250E8),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final notes = notesController.text.trim();
                                  if (notes.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Catatan tindakan wajib diisi.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  Navigator.pop(ctx);
                                  await _submitBkAction(
                                    studentId: selectedStudentId,
                                    actionType: selectedActionType,
                                    notes: notes,
                                    date: selectedDate,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2250E8),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Simpan',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    } finally {
      notesController.dispose();
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: const Color(0xFF64748B),
      ),
      filled: true,
      fillColor: const Color(0xFFF9FAFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5EAF7)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5EAF7)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF2250E8), width: 1.2),
      ),
    );
  }

  Future<void> _submitBkAction({
    required int studentId,
    required String actionType,
    required String notes,
    required DateTime date,
  }) async {
    if (!mounted) return;

    try {
      setState(() => _bkLoading = true);
      await _dio.post(
        '/bk/action',
        data: {
          'student_id': studentId,
          'action_type': actionType,
          'notes': notes,
          'tanggal_kejadian': DateFormat('yyyy-MM-dd').format(date),
        },
      );

      await _loadBkData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tindakan BK berhasil disimpan.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _bkLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan tindakan BK: $e')),
      );
    }
  }

  Widget _tabTitle(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: GoogleFonts.inter(color: _muted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _actionMetricCard(
    String label,
    String value,
    Color valueColor,
    Color background,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: valueColor == Colors.white
                  ? Colors.white.withValues(alpha: 0.85)
                  : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              height: 1,
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String _safeTime(String createdAt) {
    final parsed = DateTime.tryParse(createdAt);
    if (parsed == null) return '-';
    final local = parsed.toLocal();
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

class _AttachmentPreviewPage extends StatelessWidget {
  const _AttachmentPreviewPage({required this.url});

  final String url;

  bool get _isImage {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    final name = url.split('?').first.split('/').last;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: Colors.white),
        ),
        title: Text(
          name.isEmpty ? 'Lampiran' : name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isImage
          ? Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Text(
                    'Gagal memuat gambar lampiran.',
                    style: GoogleFonts.inter(color: Colors.white70),
                  ),
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.description_rounded,
                      color: Colors.white,
                      size: 56,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pratinjau dokumen penuh belum tersedia.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      url,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _BkClassSummary {
  final String kelas;
  final String namaKelas;
  final int totalAlpa;
  final int totalTerlambat;
  final String? jamMasukPertama;
  final bool sudahAbsen;

  const _BkClassSummary({
    required this.kelas,
    required this.namaKelas,
    required this.totalAlpa,
    required this.totalTerlambat,
    required this.jamMasukPertama,
    required this.sudahAbsen,
  });

  factory _BkClassSummary.fromJson(Map<String, dynamic> json) {
    return _BkClassSummary(
      kelas: (json['kelas'] ?? '').toString(),
      namaKelas: (json['nama_kelas'] ?? json['kelas'] ?? '').toString(),
      totalAlpa: _asInt(json['total_alpa']),
      totalTerlambat: _asInt(json['total_terlambat']),
      jamMasukPertama: json['jam_masuk_pertama']?.toString(),
      sudahAbsen: json['sudah_absen'] == true,
    );
  }
}

class _BkWatchStudent {
  final int studentId;
  final String name;
  final String classId;
  final int totalMapelAlpa;
  final int totalTerlambat;
  final String jamMasukPertama;

  const _BkWatchStudent({
    required this.studentId,
    required this.name,
    required this.classId,
    required this.totalMapelAlpa,
    required this.totalTerlambat,
    required this.jamMasukPertama,
  });

  factory _BkWatchStudent.fromJson(Map<String, dynamic> json) {
    final student = (json['student'] as Map<String, dynamic>? ?? const {});
    return _BkWatchStudent(
      studentId: _asInt(student['id']),
      name: (student['name'] ?? '-').toString(),
      classId: (student['class_id'] ?? '-').toString(),
      totalMapelAlpa: _asInt(json['total_mapel_alpa']),
      totalTerlambat: _asInt(json['total_terlambat'] ?? 0),
      jamMasukPertama: (json['jam_masuk_pertama'] ?? '-').toString(),
    );
  }
}

class _BkStudentOption {
  final int id;
  final String name;
  final String nis;
  final String classId;

  const _BkStudentOption({
    required this.id,
    required this.name,
    required this.nis,
    required this.classId,
  });

  factory _BkStudentOption.fromJson(Map<String, dynamic> json) {
    return _BkStudentOption(
      id: _asInt(json['id']),
      name: (json['name'] ?? '-').toString(),
      nis: (json['nis'] ?? '').toString(),
      classId: (json['class_id'] ?? '-').toString(),
    );
  }
}

class _BkActionLog {
  final int id;
  final String actionType;
  final String notes;
  final String date;
  final String studentName;
  final String className;

  const _BkActionLog({
    required this.id,
    required this.actionType,
    required this.notes,
    required this.date,
    required this.studentName,
    required this.className,
  });

  factory _BkActionLog.fromJson(Map<String, dynamic> json) {
    final student = (json['student'] as Map<String, dynamic>? ?? const {});
    return _BkActionLog(
      id: _asInt(json['id']),
      actionType: (json['action_type'] ?? '-').toString(),
      notes: (json['notes'] ?? '').toString(),
      date: (json['tanggal'] ?? json['created_at'] ?? '-').toString(),
      studentName: (student['name'] ?? 'Siswa').toString(),
      className: (student['kelas'] ?? student['class_id'] ?? '-').toString(),
    );
  }

  String get actionLabel {
    switch (actionType) {
      case 'panggilan_ortu':
        return 'Panggilan Orang Tua';
      case 'home_visit':
        return 'Home Visit';
      case 'surat_peringatan':
        return 'Surat Peringatan';
      case 'konseling':
        return 'Konseling';
      case 'lainnya':
        return 'Lainnya';
      default:
        return actionType;
    }
  }
}

int _asInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '0') ?? 0;
}
