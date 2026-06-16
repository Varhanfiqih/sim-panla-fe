import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../data/models/app_notification.dart';
import '../../data/repositories/notification_repository.dart';
import '../bloc/bloc.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final NotificationRepository _repository = NotificationRepository();
  bool _loading = true;
  List<AppNotification> _items = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _repository.getNotifications(limit: 50);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
      context.read<NotificationBloc>().add(const NotificationUnreadRequested());
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _markAllRead() async {
    await _repository.clearAll();
    if (!mounted) return;
    setState(() => _items = const []);
    context.read<NotificationBloc>().add(const NotificationUnreadRequested());
  }

  Future<void> _markOneRead(AppNotification item) async {
    if (item.isRead) return;
    await _repository.markRead(item.id);
    if (!mounted) return;
    setState(() {
      _items = _items
          .map(
            (e) => e.id == item.id
                ? AppNotification(
                    id: e.id,
                    userId: e.userId,
                    type: e.type,
                    title: e.title,
                    body: e.body,
                    data: e.data,
                    isRead: true,
                    createdAt: e.createdAt,
                  )
                : e,
          )
          .toList();
    });
    context.read<NotificationBloc>().add(const NotificationUnreadRequested());
  }

  @override
  Widget build(BuildContext context) {
    final todayItems = _items.where((e) => _isToday(e.createdAt)).toList();
    final yesterdayItems = _items
        .where((e) => _isYesterday(e.createdAt))
        .toList();
    final olderItems = _items
        .where((e) => !_isToday(e.createdAt) && !_isYesterday(e.createdAt))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FC),
      appBar: AppBar(
        title: Text(
          'Notifikasi',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _items.isNotEmpty ? _markAllRead : null,
            child: const Text('Bersihkan Semua'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 140),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔔', style: TextStyle(fontSize: 44)),
                              const SizedBox(height: 10),
                              Text(
                                'Belum ada notifikasi',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1C2435),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Nanti notifikasi penting akan muncul di sini 🙂',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF737686),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      children: [
                        if (todayItems.isNotEmpty) ...[
                          _buildSectionHeader('Hari Ini', todayItems),
                          const SizedBox(height: 10),
                          ...todayItems.map(_buildNotificationCard),
                        ],
                        if (yesterdayItems.isNotEmpty ||
                            olderItems.isNotEmpty) ...[
                          const SizedBox(height: 18),
                          _buildSectionHeader('Kemarin', const []),
                          const SizedBox(height: 10),
                          ...yesterdayItems.map(_buildNotificationCard),
                          ...olderItems.map(_buildNotificationCard),
                        ],
                      ],
                    ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, List<AppNotification> items) {
    final unread = items.where((e) => !e.isRead).length;
    return Row(
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1C2435),
          ),
        ),
        const Spacer(),
        if (title == 'Hari Ini' && unread > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE7ECFF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              '$unread BARU',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2B4CC8),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildNotificationCard(AppNotification item) {
    final accent = _typeColor(item.type);
    final icon = _typeIcon(item.type);
    final bg = _typeSoftBg(item.type);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _markOneRead(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: accent, size: 23),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1C2435),
                              ),
                            ),
                          ),
                          Text(
                            _timeAgo(item.createdAt),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF7A8199),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            item.isRead
                                ? Icons.notifications_none_rounded
                                : Icons.notifications_active_rounded,
                            size: 14,
                            color: const Color(0xFF2B4CC8),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: const Color(0xFF434655),
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatDateTime(item.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF8A90A5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'teacher_checkin':
        return const Color(0xFF1F9D59);
      case 'journal_submitted':
        return const Color(0xFF2B4CC8);
      case 'inval_claim':
        return const Color(0xFFE11D48);
      case 'inval_available':
        return const Color(0xFFF59E0B);
      case 'permission_submitted':
        return const Color(0xFFF59E0B);
      case 'permission_approved':
        return const Color(0xFF16A34A);
      case 'permission_rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  Color _typeSoftBg(String type) {
    switch (type) {
      case 'teacher_checkin':
        return const Color(0xFFDFF7E9);
      case 'journal_submitted':
        return const Color(0xFFE7ECFF);
      case 'inval_claim':
        return const Color(0xFFFFE4E6);
      case 'inval_available':
        return const Color(0xFFFFF4D6);
      case 'permission_submitted':
        return const Color(0xFFFFF4D6);
      case 'permission_approved':
        return const Color(0xFFDCFCE7);
      case 'permission_rejected':
        return const Color(0xFFFEE2E2);
      default:
        return const Color(0xFFE9EDF5);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'teacher_checkin':
        return Icons.check_circle_rounded;
      case 'journal_submitted':
        return Icons.calendar_today_rounded;
      case 'inval_claim':
        return Icons.warning_amber_rounded;
      case 'inval_available':
        return Icons.event_repeat_rounded;
      case 'permission_submitted':
        return Icons.assignment_rounded;
      case 'permission_approved':
        return Icons.verified_rounded;
      case 'permission_rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return raw;
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt.toLocal());
  }

  String _timeAgo(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    final dt = DateTime.tryParse(raw);
    if (dt == null) return '-';

    final diff = DateTime.now().difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'baru';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}d';
  }

  bool _isToday(String? raw) {
    final dt = DateTime.tryParse(raw ?? '');
    if (dt == null) return false;
    final now = DateTime.now();
    final local = dt.toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  bool _isYesterday(String? raw) {
    final dt = DateTime.tryParse(raw ?? '');
    if (dt == null) return false;
    final y = DateTime.now().subtract(const Duration(days: 1));
    final local = dt.toLocal();
    return local.year == y.year && local.month == y.month && local.day == y.day;
  }
}
