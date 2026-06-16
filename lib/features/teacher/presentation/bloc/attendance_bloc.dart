import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/repositories/attendance_repository.dart';
import 'attendance_event.dart';
import 'attendance_state.dart';

class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository _repository;

  AttendanceBloc({AttendanceRepository? repository})
    : _repository = repository ?? AttendanceRepository(),
      super(const AttendanceInitial()) {
    on<CheckAttendanceStatus>(_onCheckAttendanceStatus);
    on<SubmitCheckIn>(_onSubmitCheckIn);
  }

  /// Handle check attendance status event
  Future<void> _onCheckAttendanceStatus(
    CheckAttendanceStatus event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());

    try {
      final status = await _repository.getCheckInStatus();

      emit(
        AttendanceStatusLoaded(
          hasCheckedIn: status.hasCheckedIn,
          isPresent: status.isPresent,
          reason: status.reason,
        ),
      );
    } catch (e) {
      emit(AttendanceError(message: _errorMessage(e)));
    }
  }

  /// Handle submit check-in event
  Future<void> _onSubmitCheckIn(
    SubmitCheckIn event,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());

    try {
      final attendance = await _repository.submitCheckIn(
        status: event.status,
        reason: event.reason,
        description: event.description,
      );

      emit(AttendanceCheckInSuccess(attendance: attendance));

      // After successful check-in, reload status
      add(const CheckAttendanceStatus());
    } catch (e) {
      emit(AttendanceError(message: _errorMessage(e)));
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    final message = error.toString();
    return message.replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}
