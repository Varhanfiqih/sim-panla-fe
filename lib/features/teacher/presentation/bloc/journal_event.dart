part of 'journal_bloc.dart';

/// Base class for all journal events
abstract class JournalEvent {}

/// Load students for a schedule
class LoadJournalStudents extends JournalEvent {
  final int scheduleId;
  final String className;
  final String subjectName;
  final String timeSlot;
  final String? journalDate;

  LoadJournalStudents({
    required this.scheduleId,
    required this.className,
    required this.subjectName,
    required this.timeSlot,
    this.journalDate,
  });
}

/// Update a student's attendance status
class UpdateStudentStatus extends JournalEvent {
  final int studentId;
  final StudentStatus status;

  UpdateStudentStatus({required this.studentId, required this.status});
}

/// Update material text (materi)
class UpdateMaterial extends JournalEvent {
  final String material;

  UpdateMaterial(this.material);
}

/// Update cleanliness selection
class UpdateCleanliness extends JournalEvent {
  final String cleanliness;

  UpdateCleanliness(this.cleanliness);
}

/// Set attachment file
class SetAttachment extends JournalEvent {
  final File? file;

  SetAttachment(this.file);
}

/// Submit the journal
class SubmitJournal extends JournalEvent {}

/// Reset journal state (after successful submission or cancel)
class ResetJournal extends JournalEvent {}
