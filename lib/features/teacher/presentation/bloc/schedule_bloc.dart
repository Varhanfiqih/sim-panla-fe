import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/models/schedule.dart';
import '../../data/repositories/schedule_repository.dart';
import 'package:intl/intl.dart';

part 'schedule_event.dart';
part 'schedule_state.dart';

class ScheduleBloc extends Bloc<ScheduleEvent, ScheduleState> {
  final ScheduleRepository _repository;

  ScheduleBloc({ScheduleRepository? repository})
    : _repository = repository ?? ScheduleRepository(),
      super(ScheduleInitial()) {
    on<LoadSchedules>(_onLoadSchedules);
    on<ChangeDate>(_onChangeDate);
  }

  Future<void> _onLoadSchedules(
    LoadSchedules event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleLoading());

    try {
      final response = await _repository.getSchedules(date: event.date);

      // Parse date from response
      final selectedDate = DateTime.parse(response.tanggal);

      emit(
        ScheduleLoaded(
          schedules: response.data,
          selectedDate: selectedDate,
          dayName: response.hariIni,
        ),
      );
    } catch (e) {
      emit(ScheduleError(_errorMessage(e)));
    }
  }

  Future<void> _onChangeDate(
    ChangeDate event,
    Emitter<ScheduleState> emit,
  ) async {
    emit(ScheduleLoading());

    try {
      // Format date as yyyy-MM-dd
      final dateStr = DateFormat('yyyy-MM-dd').format(event.date);
      final response = await _repository.getSchedules(date: dateStr);

      emit(
        ScheduleLoaded(
          schedules: response.data,
          selectedDate: event.date,
          dayName: response.hariIni,
        ),
      );
    } catch (e) {
      emit(ScheduleError(_errorMessage(e)));
    }
  }

  String _errorMessage(Object error) {
    if (error is ApiException) return error.message;
    final message = error.toString();
    return message.replaceFirst(RegExp(r'^Exception:\s*'), '');
  }
}
