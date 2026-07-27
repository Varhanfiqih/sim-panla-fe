// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

JournalScheduleInfo _$JournalScheduleInfoFromJson(Map<String, dynamic> json) =>
    JournalScheduleInfo(
      id: (json['id'] as num).toInt(),
      kelas: json['kelas'] as String,
      mataPelajaran: json['mata_pelajaran'] as String,
      isInvalMock: json['is_inval_mock'] as bool,
    );

Map<String, dynamic> _$JournalScheduleInfoToJson(
        JournalScheduleInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'kelas': instance.kelas,
      'mata_pelajaran': instance.mataPelajaran,
      'is_inval_mock': instance.isInvalMock,
    };

JournalStudent _$JournalStudentFromJson(Map<String, dynamic> json) =>
    JournalStudent(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      nisn: json['nisn'] as String,
      nis: json['nis'] as String,
      classId: (json['class_id'] as num).toInt(),
      statusAwal: json['status_awal'] as String,
      isLocked: json['is_locked'] as bool,
      keteranganIzin: json['keterangan_izin'] as String?,
      sudahScanGerbang: json['sudah_scan_gerbang'] as bool,
    );

Map<String, dynamic> _$JournalStudentToJson(JournalStudent instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'nisn': instance.nisn,
      'nis': instance.nis,
      'class_id': instance.classId,
      'status_awal': instance.statusAwal,
      'is_locked': instance.isLocked,
      'keterangan_izin': instance.keteranganIzin,
      'sudah_scan_gerbang': instance.sudahScanGerbang,
    };

JournalStudentsResponse _$JournalStudentsResponseFromJson(
        Map<String, dynamic> json) =>
    JournalStudentsResponse(
      status: json['status'] as String,
      data: JournalStudentsData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JournalStudentsResponseToJson(
        JournalStudentsResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'data': instance.data,
    };

JournalStudentsData _$JournalStudentsDataFromJson(Map<String, dynamic> json) =>
    JournalStudentsData(
      schedule: JournalScheduleInfo.fromJson(
          json['schedule'] as Map<String, dynamic>),
      students: (json['students'] as List<dynamic>)
          .map((e) => JournalStudent.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalSudahScan: (json['total_sudah_scan'] as num).toInt(),
    );

Map<String, dynamic> _$JournalStudentsDataToJson(
        JournalStudentsData instance) =>
    <String, dynamic>{
      'schedule': instance.schedule,
      'students': instance.students,
      'total_sudah_scan': instance.totalSudahScan,
    };

StudentAttendanceEntry _$StudentAttendanceEntryFromJson(
        Map<String, dynamic> json) =>
    StudentAttendanceEntry(
      studentId: (json['student_id'] as num).toInt(),
      nis: json['nis'] as String?,
      nisn: json['nisn'] as String?,
      studentName: json['student_name'] as String?,
      status: json['status'] as String,
      notes:
          (json['notes'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$StudentAttendanceEntryToJson(
        StudentAttendanceEntry instance) =>
    <String, dynamic>{
      'student_id': instance.studentId,
      'nis': instance.nis,
      'nisn': instance.nisn,
      'student_name': instance.studentName,
      'status': instance.status,
      'notes': instance.notes,
    };

JournalSubmitResponse _$JournalSubmitResponseFromJson(
        Map<String, dynamic> json) =>
    JournalSubmitResponse(
      status: json['status'] as String,
      message: json['message'] as String,
      data: json['data'] == null
          ? null
          : JournalSubmitData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$JournalSubmitResponseToJson(
        JournalSubmitResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'data': instance.data,
    };

JournalSubmitData _$JournalSubmitDataFromJson(Map<String, dynamic> json) =>
    JournalSubmitData(
      journalId: (json['journal_id'] as num).toInt(),
    );

Map<String, dynamic> _$JournalSubmitDataToJson(JournalSubmitData instance) =>
    <String, dynamic>{
      'journal_id': instance.journalId,
    };
