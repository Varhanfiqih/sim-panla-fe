import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/models/journal_history.dart';
import '../../data/repositories/journal_repository.dart';
import '../../data/models/journal.dart';

class JournalHistoryDetailPage extends StatefulWidget {
  final int journalId;
  final String subjectName;
  final String className;
  final String date;
  final String timeSlot;

  const JournalHistoryDetailPage({
    super.key,
    required this.journalId,
    required this.subjectName,
    required this.className,
    required this.date,
    required this.timeSlot,
  });

  @override
  State<JournalHistoryDetailPage> createState() =>
      _JournalHistoryDetailPageState();
}

class _JournalHistoryDetailPageState extends State<JournalHistoryDetailPage> {
  static const Color _surface = Color(0xFFFAF8FF);
  static const Color _primary = Color(0xFF0040DF);
  static const Color _primaryContainer = Color(0xFF2D5BFF);
  static const Color _onSurface = Color(0xFF131B2E);
  static const Color _onSurfaceVariant = Color(0xFF434655);
  static const Color _surfaceContainerLow = Color(0xFFF2F3FF);
  static const Color _surfaceContainerHighest = Color(0xFFDAE2FD);
  static const Color _surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color _surfaceContainerHigh = Color(0xFFE2E7FF);

  final _repository = JournalRepository();
  final _editMaterialController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditSheetOpen = false;
  String? _error;
  String? _editCleanliness;
  JournalHistoryData? _detail;

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  @override
  void dispose() {
    _editMaterialController.dispose();
    super.dispose();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _repository.getJournalHistory(widget.journalId);
      if (!mounted) return;

      if (response.status == 'success' && response.data != null) {
        setState(() {
          _detail = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.message ?? 'Data riwayat jurnal tidak tersedia';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator(color: _primary))
          else if (_error != null)
            _buildErrorState()
          else
            SingleChildScrollView(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 70,
                bottom: 120,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroHeader(),
                    const SizedBox(height: 24),
                    _buildSummaryCards(),
                    const SizedBox(height: 24),
                    _buildAttendanceList(),
                  ],
                ),
              ),
            ),
          _buildTopAppBar(),
        ],
      ),
    );
  }

  Widget _buildTopAppBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            height: MediaQuery.of(context).padding.top + 60,
            padding: EdgeInsets.fromLTRB(
              24,
              MediaQuery.of(context).padding.top,
              24,
              0,
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
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: _surfaceContainerHigh,
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: _onSurface,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Detail Jurnal',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _primary,
                    ),
                  ),
                ),
                if (_detail != null && !_isLoading && _error == null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isSaving ? null : _openEditSheet,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: _surfaceContainerHigh,
                        ),
                        child: _isSaving
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _primary,
                                ),
                              )
                            : const Icon(
                                Icons.edit,
                                color: _onSurface,
                                size: 20,
                              ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openEditSheet() async {
    final detail = _detail;
    if (detail == null) return;

    _editMaterialController.text = detail.material;
    _editCleanliness = detail.cleanliness;
    _isEditSheetOpen = true;

    // Build the editable list from journal history first, then enrich it
    // with the full class list when the schedule endpoint is available.
    List<StudentAttendanceState>? sheetStudents = _studentsFromHistory(detail);
    if (detail.scheduleId != null) {
      try {
        final studentsData = await _repository.getStudents(
          detail.scheduleId!,
          date: _historyDateParam(detail),
        );
        sheetStudents = studentsData.students
            .map((s) => StudentAttendanceState.fromStudent(s))
            .toList();

        // Apply existing absensi status from detail using stable student ids.
        for (final a in detail.absensi) {
          final match = sheetStudents.firstWhere(
            (ss) =>
                ss.student.id == a.studentId ||
                (a.nisn != null && ss.student.nisn == a.nisn) ||
                (a.nis != null && ss.student.nis == a.nis),
            orElse: () => StudentAttendanceState.fromStudent(
              JournalStudent(
                id: -1,
                name: '',
                nisn: '',
                nis: '',
                classId: 0,
                statusAwal: 'none',
                isLocked: false,
                sudahScanGerbang: false,
              ),
            ),
          );
          if (match.student.id != -1) {
            match.currentStatus = _statusFromJournalValue(a.status);
            match.notes = _notesFromJournalValue(a.notes);
          }
        }
      } catch (e) {
        // Keep the history-based list available when the full class fetch fails.
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Row(
                      children: [
                        Text(
                          'Edit Jurnal',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _onSurface,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _editMaterialController,
                      minLines: 4,
                      maxLines: 7,
                      decoration: InputDecoration(
                        labelText: 'Materi Pelajaran',
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: _surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _normalizeCleanliness(_editCleanliness),
                      decoration: InputDecoration(
                        labelText: 'Kebersihan Kelas',
                        filled: true,
                        fillColor: _surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'sudah_bersih',
                          child: Text('Bersih'),
                        ),
                        DropdownMenuItem(value: 'kotor', child: Text('Kotor')),
                      ],
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              setSheetState(() => _editCleanliness = value);
                            },
                    ),
                    const SizedBox(height: 24),
                    if (sheetStudents != null) ...[
                      Text(
                        'Edit Kehadiran Siswa',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ubah status siswa jika ada koreksi pada riwayat jurnal.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: _onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 280,
                        child: ListView.builder(
                          itemCount: sheetStudents.length,
                          itemBuilder: (ctx, i) {
                            final s = sheetStudents![i];
                            return _buildEditableAttendanceItem(
                              state: s,
                              enabled: !_isSaving && !s.student.isLocked,
                              onChanged: (value) {
                                if (value == null) return;
                                setSheetState(() => s.currentStatus = value);
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _surfaceContainerLow,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 18,
                              color: _onSurfaceVariant,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Data siswa tidak dapat dimuat. Anda masih dapat mengubah materi dan kebersihan kelas.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: _onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _saveEdit(
                                  sheetContext,
                                  setSheetState,
                                  sheetStudents,
                                ),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
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
        );
      },
    ).whenComplete(() => _isEditSheetOpen = false);
  }

  Future<void> _saveEdit(
    BuildContext sheetContext,
    void Function(void Function()) setSheetState,
    List<StudentAttendanceState>? sheetStudents,
  ) async {
    final material = _editMaterialController.text.trim();
    if (material.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Materi pelajaran wajib diisi')),
      );
      return;
    }

    setState(() => _isSaving = true);
    setSheetState(() {});

    try {
      final attendances = sheetStudents?.map((s) => s.toEntry()).toList();

      await _repository.updateJournalHistory(
        journalId: widget.journalId,
        materi: material,
        kebersihanKelas: _editCleanliness,
        attendances: attendances,
      );

      if (!mounted) return;
      setState(() => _isSaving = false);
      if (_isEditSheetOpen) {
        setSheetState(() {});
        if (sheetContext.mounted) {
          Navigator.pop(sheetContext);
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jurnal berhasil diperbarui')),
      );
      await _loadDetail();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      if (_isEditSheetOpen) {
        setSheetState(() {});
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  Future<void> _openSingleAttendanceEdit(JournalHistoryAbsensi item) async {
    final detail = _detail;
    if (detail == null) return;

    final resolvedStudentId = await _resolveStudentId(item, detail);
    if (!mounted) return;

    var selectedStatus = _statusFromJournalValue(item.status);
    if (selectedStatus == StudentStatus.none) {
      selectedStatus = StudentStatus.hadir;
    }

    final saved = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Edit Kehadiran',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: _onSurface,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _isSaving
                              ? null
                              : () => Navigator.pop(sheetContext, false),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.studentName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NIS: ${item.nis ?? '-'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<StudentStatus>(
                      value: selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Status Kehadiran',
                        filled: true,
                        fillColor: _surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: StudentStatus.values
                          .where((status) => status != StudentStatus.none)
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status.displayName),
                            ),
                          )
                          .toList(),
                      onChanged: _isSaving
                          ? null
                          : (value) {
                              if (value == null) return;
                              setSheetState(() => selectedStatus = value);
                            },
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                setState(() => _isSaving = true);
                                setSheetState(() {});

                                try {
                                  await _repository.updateJournalHistory(
                                    journalId: widget.journalId,
                                    materi: detail.material,
                                    kebersihanKelas: detail.cleanliness,
                                    attendances: [
                                      StudentAttendanceEntry(
                                        studentId: resolvedStudentId,
                                        nis: item.nis,
                                        nisn: item.nisn,
                                        studentName: item.studentName,
                                        status: selectedStatus.jsonValue,
                                        notes: _notesFromJournalValue(
                                          item.notes,
                                        ),
                                      ),
                                    ],
                                  );

                                  if (!mounted) return;
                                  setState(() => _isSaving = false);
                                  if (sheetContext.mounted) {
                                    Navigator.pop(sheetContext, true);
                                  }
                                } catch (e) {
                                  if (!mounted) return;
                                  setState(() => _isSaving = false);
                                  setSheetState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        e
                                            .toString()
                                            .replaceAll('Exception: ', ''),
                                      ),
                                    ),
                                  );
                                }
                              },
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(_isSaving ? 'Menyimpan...' : 'Simpan'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted) return;
    if (saved == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Status kehadiran berhasil diperbarui')),
      );
      await _loadDetail();
    }
  }

  Future<int> _resolveStudentId(
    JournalHistoryAbsensi item,
    JournalHistoryData detail,
  ) async {
    if (item.studentId > 0) return item.studentId;
    if (detail.scheduleId == null) return 0;

    try {
      final studentsData = await _repository.getStudents(
        detail.scheduleId!,
        date: _historyDateParam(detail),
      );

      final itemNis = item.nis?.trim();
      final itemNisn = item.nisn?.trim();
      final itemName = item.studentName.trim().toLowerCase();

      for (final student in studentsData.students) {
        final sameId = student.id > 0 && student.id == item.studentId;
        final sameNis =
            itemNis != null && itemNis.isNotEmpty && student.nis == itemNis;
        final sameNisn = itemNisn != null &&
            itemNisn.isNotEmpty &&
            student.nisn == itemNisn;
        final sameName = student.name.trim().toLowerCase() == itemName;

        if (sameId || sameNis || sameNisn || sameName) {
          return student.id;
        }
      }
    } catch (_) {
      return 0;
    }

    return 0;
  }

  String? _normalizeCleanliness(String? value) {
    final raw = (value ?? '').trim().toLowerCase();
    if (raw == 'bersih' || raw == 'sudah_bersih') return 'sudah_bersih';
    if (raw == 'kurang bersih' || raw == 'kotor') return 'kotor';
    return null;
  }

  String _historyDateParam(JournalHistoryData detail) {
    return detail.createdAt.length >= 10
        ? detail.createdAt.substring(0, 10)
        : widget.date;
  }

  StudentStatus _statusFromJournalValue(String status) {
    switch (status) {
      case 'KBM_Hadir':
        return StudentStatus.hadir;
      case 'KBM_Alpa':
        return StudentStatus.alpa;
      case 'KBM_Sakit':
        return StudentStatus.sakit;
      case 'KBM_Izin':
        return StudentStatus.izin;
      case 'KBM_Sakit_atau_Izin':
        return StudentStatus.sakitAtauIzin;
      default:
        return StudentStatus.none;
    }
  }

  List<String> _notesFromJournalValue(String? notes) {
    final value = notes?.trim();
    if (value == null || value.isEmpty) return [];

    return value
        .split(',')
        .map((note) => note.trim())
        .where((note) => note.isNotEmpty)
        .toList();
  }

  List<StudentAttendanceState>? _studentsFromHistory(
    JournalHistoryData detail,
  ) {
    final students = detail.absensi
        .where((item) => item.studentId > 0)
        .map(
          (item) => StudentAttendanceState(
            student: JournalStudent(
              id: item.studentId,
              name: item.studentName,
              nisn: item.nisn ?? '',
              nis: item.nis ?? '',
              classId: 0,
              statusAwal: item.status,
              isLocked: false,
              sudahScanGerbang: false,
            ),
            currentStatus: _statusFromJournalValue(item.status),
            notes: _notesFromJournalValue(item.notes),
          ),
        )
        .toList();

    return students.isEmpty ? null : students;
  }

  Widget _buildEditableAttendanceItem({
    required StudentAttendanceState state,
    required bool enabled,
    required ValueChanged<StudentStatus?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: state.student.isLocked
              ? const Color(0xFFFFC857)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.student.name,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  state.student.isLocked
                      ? 'Dikunci oleh izin wali kelas'
                      : 'NIS: ${state.student.nis.isEmpty ? '-' : state.student.nis}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          DropdownButtonHideUnderline(
            child: DropdownButton<StudentStatus>(
              value: state.currentStatus,
              borderRadius: BorderRadius.circular(14),
              items: StudentStatus.values
                  .where((status) => status != StudentStatus.none)
                  .map(
                    (status) => DropdownMenuItem(
                      value: status,
                      child: Text(status.displayName),
                    ),
                  )
                  .toList(),
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    final detail = _detail!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_primary, _primaryContainer],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withAlpha(77),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DETAIL JURNAL',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: Colors.white.withAlpha(204),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail.subject,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.school, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                'Kelas ${detail.className}',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withAlpha(230),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildHeroChip(
                Icons.calendar_today,
                _formatCreatedAt(detail.createdAt),
              ),
              _buildHeroChip(
                Icons.access_time,
                '${detail.timeSlot.startTime} - ${detail.timeSlot.endTime}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withAlpha(25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final detail = _detail!;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book, color: _primary, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    'Materi Pelajaran',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                detail.material.isEmpty ? '-' : detail.material,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  height: 1.6,
                  color: _onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.cleaning_services, color: _primary, size: 20),
              const SizedBox(width: 12),
              Text(
                'Kebersihan Kelas',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _onSurface,
                ),
              ),
              const Spacer(),
              _buildCleanlinessBadge(detail.cleanliness),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCleanlinessBadge(String? cleanliness) {
    final raw = (cleanliness ?? '').trim().toLowerCase();
    final label = raw == 'sudah_bersih'
        ? 'Bersih'
        : raw == 'kotor'
        ? 'Kurang Bersih'
        : (cleanliness == null || cleanliness.isEmpty)
        ? '-'
        : cleanliness;

    final isClean = raw == 'sudah_bersih' || raw == 'bersih';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isClean ? const Color(0xFFDFF5E6) : const Color(0xFFFFE5E1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isClean ? const Color(0xFF1B7A3A) : const Color(0xFFB3261E),
        ),
      ),
    );
  }

  Widget _buildAttendanceList() {
    final detail = _detail!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.group, color: _primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'Kehadiran Siswa',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (detail.absensi.isEmpty)
            Text(
              'Belum ada data kehadiran siswa.',
              style: GoogleFonts.inter(fontSize: 14, color: _onSurfaceVariant),
            )
          else
            ...detail.absensi.map(_buildStudentItem),
        ],
      ),
    );
  }

  Widget _buildStudentItem(JournalHistoryAbsensi item) {
    final statusLabel = _statusLabel(item.status);
    final statusColor = _statusColor(item.status);

    final initials = item.studentName
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .take(2)
        .map((e) => e[0].toUpperCase())
        .join();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSaving ? null : () => _openSingleAttendanceEdit(item),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _surfaceContainerLowest,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(5),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: _surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    initials.isEmpty ? 'S' : initials,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      color: _primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.studentName,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.bold,
                        color: _onSurface,
                      ),
                    ),
                    Text(
                      'NIS: ${item.nis ?? '-'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ketuk untuk edit status',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: _primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.edit, size: 16, color: _onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 44),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Terjadi kesalahan',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: _onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadDetail,
              child: const Text('Muat ulang'),
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(String status) {
    final s = status.toLowerCase();
    if (s.contains('hadir')) return 'HADIR';
    if (s.contains('sakit')) return 'SAKIT';
    if (s.contains('izin')) return 'IZIN';
    if (s.contains('alpa')) return 'ALPA';
    return status.toUpperCase();
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('hadir')) return const Color(0xFF1B7A3A);
    if (s.contains('sakit')) return const Color(0xFFB26A00);
    if (s.contains('izin')) return const Color(0xFF0B66D0);
    if (s.contains('alpa')) return const Color(0xFFB3261E);
    return _onSurfaceVariant;
  }

  String _formatCreatedAt(String raw) {
    final dt = DateTime.tryParse(raw);
    if (dt == null) return widget.date;

    const months = [
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

    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
