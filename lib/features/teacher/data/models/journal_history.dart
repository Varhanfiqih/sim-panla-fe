import 'package:json_annotation/json_annotation.dart';

part 'journal_history.g.dart';

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

@JsonSerializable()
class JournalHistoryResponse {
  final String status;
  final JournalHistoryData? data;
  final String? message;

  JournalHistoryResponse({required this.status, this.data, this.message});

  factory JournalHistoryResponse.fromJson(Map<String, dynamic> json) =>
      _$JournalHistoryResponseFromJson(json);

  Map<String, dynamic> toJson() => _$JournalHistoryResponseToJson(this);
}

@JsonSerializable()
class JournalHistoryData {
  @JsonKey(name: 'journal_id')
  final int journalId;

  @JsonKey(name: 'schedule_id')
  final int? scheduleId;

  @JsonKey(name: 'created_at')
  final String createdAt;

  final String subject;

  @JsonKey(name: 'class_name')
  final String className;

  @JsonKey(name: 'time_slot')
  final JournalHistoryTimeSlot timeSlot;

  final String material;
  final String? cleanliness;

  @JsonKey(name: 'is_inval')
  final bool isInval;

  @JsonKey(name: 'attachment_url')
  final String? attachmentUrl;

  @JsonKey(name: 'total_absen')
  final int totalAbsen;

  final List<JournalHistoryAbsensi> absensi;

  JournalHistoryData({
    required this.journalId,
    required this.createdAt,
    required this.subject,
    required this.className,
    required this.timeSlot,
    required this.material,
    this.scheduleId,
    this.cleanliness,
    required this.isInval,
    this.attachmentUrl,
    required this.totalAbsen,
    required this.absensi,
  });

  factory JournalHistoryData.fromJson(Map<String, dynamic> json) {
    return JournalHistoryData(
      journalId: _toInt(json['journal_id']),
      scheduleId: json['schedule_id'] != null ? _toInt(json['schedule_id']) : null,
      createdAt: json['created_at']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      className: json['class_name']?.toString() ?? '',
      timeSlot: JournalHistoryTimeSlot.fromJson(
        json['time_slot'] as Map<String, dynamic>,
      ),
      material: json['material']?.toString() ?? '',
      cleanliness: json['cleanliness']?.toString(),
      isInval:
          json['is_inval'] == true ||
          json['is_inval'] == 'true' ||
          json['is_inval'] == 1,
      attachmentUrl: json['attachment_url']?.toString(),
      totalAbsen: _toInt(json['total_absen']),
      absensi:
          (json['absensi'] as List<dynamic>?)
              ?.map(
                (e) =>
                    JournalHistoryAbsensi.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => _$JournalHistoryDataToJson(this);
}

@JsonSerializable()
class JournalHistoryTimeSlot {
  @JsonKey(name: 'start_time')
  final String startTime;

  @JsonKey(name: 'end_time')
  final String endTime;

  JournalHistoryTimeSlot({required this.startTime, required this.endTime});

  factory JournalHistoryTimeSlot.fromJson(Map<String, dynamic> json) =>
      _$JournalHistoryTimeSlotFromJson(json);

  Map<String, dynamic> toJson() => _$JournalHistoryTimeSlotToJson(this);
}

@JsonSerializable()
class JournalHistoryAbsensi {
  @JsonKey(name: 'student_id')
  final int studentId;

  @JsonKey(name: 'student_name')
  final String studentName;

  final String? nisn;
  final String? nis;

  final String status;
  final String? notes;

  JournalHistoryAbsensi({
    required this.studentId,
    required this.studentName,
    this.nisn,
    this.nis,
    required this.status,
    this.notes,
  });

  factory JournalHistoryAbsensi.fromJson(Map<String, dynamic> json) =>
      _$JournalHistoryAbsensiFromJson(json);

  Map<String, dynamic> toJson() => _$JournalHistoryAbsensiToJson(this);
}
