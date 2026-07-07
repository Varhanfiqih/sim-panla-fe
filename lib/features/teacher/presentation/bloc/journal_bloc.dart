import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/journal.dart';
import '../../data/repositories/journal_repository.dart';

part 'journal_event.dart';
part 'journal_state.dart';

class JournalBloc extends Bloc<JournalEvent, JournalState> {
  final JournalRepository _repository;

  JournalBloc({JournalRepository? repository})
    : _repository = repository ?? JournalRepository(),
      super(JournalInitial()) {
    on<LoadJournalStudents>(_onLoadStudents);
    on<UpdateStudentStatus>(_onUpdateStudentStatus);
    on<UpdateMaterial>(_onUpdateMaterial);
    on<UpdateCleanliness>(_onUpdateCleanliness);
    on<SetAttachment>(_onSetAttachment);
    on<SubmitJournal>(_onSubmitJournal);
    on<ResetJournal>(_onResetJournal);
  }

  Future<void> _onLoadStudents(
    LoadJournalStudents event,
    Emitter<JournalState> emit,
  ) async {
    emit(JournalLoading());

    try {
      final data = await _repository.getStudents(
        event.scheduleId,
        date: event.journalDate,
      );

      // Convert to StudentAttendanceState with initial status
      final studentStates = data.students
          .map((s) => StudentAttendanceState.fromStudent(s))
          .toList();

      emit(
        JournalStudentsLoaded(
          schedule: data.schedule,
          students: studentStates,
          totalSudahScan: data.totalSudahScan,
          className: event.className,
          subjectName: event.subjectName,
          timeSlot: event.timeSlot,
          journalDate: event.journalDate,
        ),
      );
    } catch (e) {
      emit(JournalError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  void _onUpdateStudentStatus(
    UpdateStudentStatus event,
    Emitter<JournalState> emit,
  ) {
    final currentState = state;
    if (currentState is JournalStudentsLoaded) {
      // Find and update the student
      final updatedStudents = currentState.students.map((s) {
        if (s.student.id == event.studentId && !s.student.isLocked) {
          s.currentStatus = event.status;
        }
        return s;
      }).toList();

      emit(currentState.copyWith(students: updatedStudents));
    }
  }

  void _onUpdateMaterial(UpdateMaterial event, Emitter<JournalState> emit) {
    final currentState = state;
    if (currentState is JournalStudentsLoaded) {
      emit(currentState.copyWith(material: event.material));
    }
  }

  void _onUpdateCleanliness(
    UpdateCleanliness event,
    Emitter<JournalState> emit,
  ) {
    final currentState = state;
    if (currentState is JournalStudentsLoaded) {
      emit(currentState.copyWith(cleanliness: event.cleanliness));
    }
  }

  void _onSetAttachment(SetAttachment event, Emitter<JournalState> emit) {
    final currentState = state;
    if (currentState is JournalStudentsLoaded) {
      if (event.file == null) {
        emit(currentState.copyWith(clearAttachment: true));
      } else {
        emit(currentState.copyWith(attachment: event.file));
      }
    }
  }

  Future<void> _onSubmitJournal(
    SubmitJournal event,
    Emitter<JournalState> emit,
  ) async {
    final currentState = state;
    if (currentState is! JournalStudentsLoaded) return;

    // Validation
    if (currentState.material.trim().isEmpty) {
      emit(JournalError('Materi pembelajaran harus diisi'));
      // Restore the previous state after error
      emit(currentState);
      return;
    }

    emit(JournalSubmitting());

    try {
      // Build attendance entries
      final attendances = currentState.students
          .map((s) => s.toEntry())
          .toList();

      final request = JournalSubmitRequest(
        scheduleId: currentState.schedule.id,
        materi: currentState.material,
        kebersihanKelas: currentState.cleanliness,
        isInval: currentState.schedule.isInvalMock,
        attendances: attendances,
        journalDate: currentState.journalDate,
      );

      final response = await _repository.submitJournal(
        request,
        attachment: currentState.attachment,
      );

      if (response.status == 'success') {
        emit(
          JournalSubmitSuccess(
            journalId: response.data?.journalId ?? 0,
            message: response.message,
          ),
        );
      } else {
        emit(JournalError(response.message));
        emit(currentState);
      }
    } catch (e) {
      emit(JournalError(e.toString().replaceAll('Exception: ', '')));
      emit(currentState);
    }
  }

  void _onResetJournal(ResetJournal event, Emitter<JournalState> emit) {
    emit(JournalInitial());
  }
}
