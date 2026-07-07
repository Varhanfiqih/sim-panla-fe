part of 'journal_bloc.dart';

/// Base class for all journal states
abstract class JournalState {}

/// Initial state
class JournalInitial extends JournalState {}

/// Loading students data
class JournalLoading extends JournalState {}

/// Students loaded, ready for attendance
class JournalStudentsLoaded extends JournalState {
  final JournalScheduleInfo schedule;
  final List<StudentAttendanceState> students;
  final int totalSudahScan;
  final String material;
  final String cleanliness;
  final File? attachment;

  // Extra info from navigation
  final String className;
  final String subjectName;
  final String timeSlot;
  final String? journalDate;

  JournalStudentsLoaded({
    required this.schedule,
    required this.students,
    required this.totalSudahScan,
    this.material = '',
    this.cleanliness = 'Bersih',
    this.attachment,
    required this.className,
    required this.subjectName,
    required this.timeSlot,
    this.journalDate,
  });

  /// Count attendance by status
  int countByStatus(StudentStatus status) {
    return students.where((s) => s.currentStatus == status).length;
  }

  /// Summary getters
  int get hadirCount => countByStatus(StudentStatus.hadir);
  int get alpaCount => countByStatus(StudentStatus.alpa);
  int get sakitCount => countByStatus(StudentStatus.sakit);
  int get izinCount => countByStatus(StudentStatus.izin);

  /// Create copy with updated fields
  JournalStudentsLoaded copyWith({
    JournalScheduleInfo? schedule,
    List<StudentAttendanceState>? students,
    int? totalSudahScan,
    String? material,
    String? cleanliness,
    File? attachment,
    bool clearAttachment = false,
    String? className,
    String? subjectName,
    String? timeSlot,
    String? journalDate,
  }) {
    return JournalStudentsLoaded(
      schedule: schedule ?? this.schedule,
      students: students ?? this.students,
      totalSudahScan: totalSudahScan ?? this.totalSudahScan,
      material: material ?? this.material,
      cleanliness: cleanliness ?? this.cleanliness,
      attachment: clearAttachment ? null : (attachment ?? this.attachment),
      className: className ?? this.className,
      subjectName: subjectName ?? this.subjectName,
      timeSlot: timeSlot ?? this.timeSlot,
      journalDate: journalDate ?? this.journalDate,
    );
  }
}

/// Submitting journal
class JournalSubmitting extends JournalState {}

/// Journal submitted successfully
class JournalSubmitSuccess extends JournalState {
  final int journalId;
  final String message;

  JournalSubmitSuccess({required this.journalId, required this.message});
}

/// Error state
class JournalError extends JournalState {
  final String message;

  JournalError(this.message);
}
