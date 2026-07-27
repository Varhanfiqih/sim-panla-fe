// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JournalHistoryResponse _$JournalHistoryResponseFromJson(
  Map<String, dynamic> json,
) => JournalHistoryResponse(
  status: json['status'] as String,
  data: json['data'] == null
      ? null
      : JournalHistoryData.fromJson(json['data'] as Map<String, dynamic>),
  message: json['message'] as String?,
);

Map<String, dynamic> _$JournalHistoryResponseToJson(
  JournalHistoryResponse instance,
) => <String, dynamic>{
  'status': instance.status,
  'data': instance.data,
  'message': instance.message,
};

JournalHistoryData _$JournalHistoryDataFromJson(Map<String, dynamic> json) =>
    JournalHistoryData(
      journalId: (json['journal_id'] as num).toInt(),
      createdAt: json['created_at'] as String,
      subject: json['subject'] as String,
      className: json['class_name'] as String,
      timeSlot: JournalHistoryTimeSlot.fromJson(
        json['time_slot'] as Map<String, dynamic>,
      ),
      material: json['material'] as String,
      cleanliness: json['cleanliness'] as String?,
      isInval: json['is_inval'] as bool,
      attachmentUrl: json['attachment_url'] as String?,
      totalAbsen: (json['total_absen'] as num).toInt(),
      absensi: (json['absensi'] as List<dynamic>)
          .map((e) => JournalHistoryAbsensi.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$JournalHistoryDataToJson(JournalHistoryData instance) =>
    <String, dynamic>{
      'journal_id': instance.journalId,
      'created_at': instance.createdAt,
      'subject': instance.subject,
      'class_name': instance.className,
      'time_slot': instance.timeSlot,
      'material': instance.material,
      'cleanliness': instance.cleanliness,
      'is_inval': instance.isInval,
      'attachment_url': instance.attachmentUrl,
      'total_absen': instance.totalAbsen,
      'absensi': instance.absensi,
    };

JournalHistoryTimeSlot _$JournalHistoryTimeSlotFromJson(
  Map<String, dynamic> json,
) => JournalHistoryTimeSlot(
  startTime: json['start_time'] as String,
  endTime: json['end_time'] as String,
);

Map<String, dynamic> _$JournalHistoryTimeSlotToJson(
  JournalHistoryTimeSlot instance,
) => <String, dynamic>{
  'start_time': instance.startTime,
  'end_time': instance.endTime,
};

JournalHistoryAbsensi _$JournalHistoryAbsensiFromJson(
  Map<String, dynamic> json,
) => JournalHistoryAbsensi(
  studentId: _toInt(json['student_id']),
  studentName: json['student_name'] as String,
  nisn: json['nisn'] as String?,
  nis: json['nis'] as String?,
  status: json['status'] as String,
  notes: json['notes'] as String?,
);

Map<String, dynamic> _$JournalHistoryAbsensiToJson(
  JournalHistoryAbsensi instance,
) => <String, dynamic>{
  'student_id': instance.studentId,
  'student_name': instance.studentName,
  'nisn': instance.nisn,
  'nis': instance.nis,
  'status': instance.status,
  'notes': instance.notes,
};
