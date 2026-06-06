import 'package:json_annotation/json_annotation.dart';

part 'schedule.g.dart';

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Enum for journal status
enum JournalStatus {
  @JsonValue('DONE')
  done,
  @JsonValue('OPEN')
  open,
  @JsonValue('LOCKED')
  locked,
}

/// Time slot model
@JsonSerializable()
class TimeSlot {
  @JsonKey(name: 'start_time')
  final String startTime;

  @JsonKey(name: 'end_time')
  final String endTime;

  TimeSlot({required this.startTime, required this.endTime});

  factory TimeSlot.fromJson(Map<String, dynamic> json) =>
      _$TimeSlotFromJson(json);

  Map<String, dynamic> toJson() => _$TimeSlotToJson(this);
}

/// Schedule item model from API
@JsonSerializable()
class ScheduleItem {
  final int id;

  @JsonKey(name: 'status_jurnal')
  final JournalStatus statusJurnal;

  final String subject;

  final String className;

  @JsonKey(name: 'time_slot')
  final TimeSlot timeSlot;

  final String? keterangan;

  @JsonKey(name: 'journal_id')
  final int? journalId;

  ScheduleItem({
    required this.id,
    required this.statusJurnal,
    required this.subject,
    required this.className,
    required this.timeSlot,
    this.keterangan,
    this.journalId,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) {
    JournalStatus status;
    final statusStr = json['status_jurnal']?.toString();
    if (statusStr == 'DONE') {
      status = JournalStatus.done;
    } else if (statusStr == 'OPEN') {
      status = JournalStatus.open;
    } else {
      status = JournalStatus.locked;
    }

    return ScheduleItem(
      id: _toInt(json['id']),
      statusJurnal: status,
      subject: json['subject']?.toString() ?? '',
      className: json['className']?.toString() ?? '',
      timeSlot: TimeSlot.fromJson(json['time_slot'] as Map<String, dynamic>),
      keterangan: json['keterangan']?.toString(),
      journalId: json['journal_id'] != null ? _toInt(json['journal_id']) : null,
    );
  }

  Map<String, dynamic> toJson() => _$ScheduleItemToJson(this);
}

/// API Response wrapper for schedules
@JsonSerializable()
class ScheduleResponse {
  final String status;

  @JsonKey(name: 'hari_ini')
  final String hariIni;

  final String tanggal;

  final List<ScheduleItem> data;

  ScheduleResponse({
    required this.status,
    required this.hariIni,
    required this.tanggal,
    required this.data,
  });

  factory ScheduleResponse.fromJson(Map<String, dynamic> json) =>
      _$ScheduleResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ScheduleResponseToJson(this);
}
