import 'package:json_annotation/json_annotation.dart';

part 'journal.g.dart';

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

/// Enum for student attendance status in KBM
enum StudentStatus {
  @JsonValue('none')
  none,
  @JsonValue('KBM_Hadir')
  hadir,
  @JsonValue('KBM_Alpa')
  alpa,
  @JsonValue('KBM_Sakit')
  sakit,
  @JsonValue('KBM_Izin')
  izin,
  @JsonValue('KBM_Sakit_atau_Izin')
  sakitAtauIzin,
}

/// Extension to get display name for StudentStatus
extension StudentStatusExtension on StudentStatus {
  String get displayName {
    switch (this) {
      case StudentStatus.none:
        return 'Belum';
      case StudentStatus.hadir:
        return 'Hadir';
      case StudentStatus.alpa:
        return 'Alpa';
      case StudentStatus.sakit:
        return 'Sakit';
      case StudentStatus.izin:
        return 'Izin';
      case StudentStatus.sakitAtauIzin:
        return 'Sakit/Izin';
    }
  }

  String get jsonValue {
    switch (this) {
      case StudentStatus.none:
        return 'none';
      case StudentStatus.hadir:
        return 'KBM_Hadir';
      case StudentStatus.alpa:
        return 'KBM_Alpa';
      case StudentStatus.sakit:
        return 'KBM_Sakit';
      case StudentStatus.izin:
        return 'KBM_Izin';
      case StudentStatus.sakitAtauIzin:
        return 'KBM_Sakit_atau_Izin';
    }
  }
}

/// Schedule info for journal
@JsonSerializable()
class JournalScheduleInfo {
  final int id;
  final String kelas;

  @JsonKey(name: 'mata_pelajaran')
  final String mataPelajaran;

  @JsonKey(name: 'is_inval_mock')
  final bool isInvalMock;

  JournalScheduleInfo({
    required this.id,
    required this.kelas,
    required this.mataPelajaran,
    required this.isInvalMock,
  });

  factory JournalScheduleInfo.fromJson(Map<String, dynamic> json) {
    return JournalScheduleInfo(
      id: _toInt(json['id']),
      kelas: json['kelas']?.toString() ?? '',
      mataPelajaran: json['mata_pelajaran']?.toString() ?? '',
      isInvalMock:
          json['is_inval_mock'] == true ||
          json['is_inval_mock'] == 'true' ||
          json['is_inval_mock'] == 1,
    );
  }

  Map<String, dynamic> toJson() => _$JournalScheduleInfoToJson(this);
}

/// Student model with attendance status
@JsonSerializable()
class JournalStudent {
  final int id;
  final String name;
  final String nisn;
  final String nis;

  @JsonKey(name: 'class_id')
  final int classId;

  @JsonKey(name: 'status_awal')
  final String statusAwal;

  @JsonKey(name: 'is_locked')
  final bool isLocked;

  @JsonKey(name: 'keterangan_izin')
  final String? keteranganIzin;

  @JsonKey(name: 'sudah_scan_gerbang')
  final bool sudahScanGerbang;

  JournalStudent({
    required this.id,
    required this.name,
    required this.nisn,
    required this.nis,
    required this.classId,
    required this.statusAwal,
    required this.isLocked,
    this.keteranganIzin,
    required this.sudahScanGerbang,
  });

  factory JournalStudent.fromJson(Map<String, dynamic> json) {
    return JournalStudent(
      id: _toInt(json['id']),
      name: json['name']?.toString() ?? '',
      nisn: json['nisn']?.toString() ?? '',
      nis: json['nis']?.toString() ?? '',
      classId: _toInt(json['class_id']),
      statusAwal: json['status_awal']?.toString() ?? 'none',
      isLocked:
          json['is_locked'] == true ||
          json['is_locked'] == 'true' ||
          json['is_locked'] == 1,
      keteranganIzin: json['keterangan_izin']?.toString(),
      sudahScanGerbang:
          json['sudah_scan_gerbang'] == true ||
          json['sudah_scan_gerbang'] == 'true' ||
          json['sudah_scan_gerbang'] == 1,
    );
  }

  Map<String, dynamic> toJson() => _$JournalStudentToJson(this);

  /// Parse status_awal string to StudentStatus enum
  StudentStatus get initialStatus {
    switch (statusAwal) {
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
}

/// Response from GET /journal/students/{schedule_id}
@JsonSerializable()
class JournalStudentsResponse {
  final String status;
  final JournalStudentsData data;

  JournalStudentsResponse({required this.status, required this.data});

  factory JournalStudentsResponse.fromJson(Map<String, dynamic> json) =>
      _$JournalStudentsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$JournalStudentsResponseToJson(this);
}

@JsonSerializable()
class JournalStudentsData {
  final JournalScheduleInfo schedule;
  final List<JournalStudent> students;

  @JsonKey(name: 'total_sudah_scan')
  final int totalSudahScan;

  JournalStudentsData({
    required this.schedule,
    required this.students,
    required this.totalSudahScan,
  });

  factory JournalStudentsData.fromJson(Map<String, dynamic> json) {
    return JournalStudentsData(
      schedule: JournalScheduleInfo.fromJson(
        json['schedule'] as Map<String, dynamic>,
      ),
      students:
          (json['students'] as List<dynamic>?)
              ?.map((e) => JournalStudent.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalSudahScan: _toInt(json['total_sudah_scan']),
    );
  }

  Map<String, dynamic> toJson() => _$JournalStudentsDataToJson(this);
}

/// Student attendance entry for submission
@JsonSerializable()
class StudentAttendanceEntry {
  @JsonKey(name: 'student_id')
  final int studentId;

  final String status;

  final List<String>? notes;

  StudentAttendanceEntry({
    required this.studentId,
    required this.status,
    this.notes,
  });

  factory StudentAttendanceEntry.fromJson(Map<String, dynamic> json) =>
      _$StudentAttendanceEntryFromJson(json);

  Map<String, dynamic> toJson() => _$StudentAttendanceEntryToJson(this);
}

/// Request body for POST /journal/store
class JournalSubmitRequest {
  final int scheduleId;
  final String materi;
  final String? kebersihanKelas;
  final String? koordinat;
  final bool isInval;
  final List<StudentAttendanceEntry> attendances;
  final String? attachmentPath;

  JournalSubmitRequest({
    required this.scheduleId,
    required this.materi,
    this.kebersihanKelas,
    this.koordinat,
    required this.isInval,
    required this.attendances,
    this.attachmentPath,
  });

  Map<String, dynamic> toFormData() {
    return {
      'schedule_id': scheduleId.toString(),
      'materi': materi,
      'kebersihan_kelas': kebersihanKelas ?? '',
      'koordinat': koordinat ?? '',
      'is_inval': isInval ? 1 : 0,
      'attendances': attendances.map((e) => e.toJson()).toList(),
    };
  }
}

/// Response from POST /journal/store
@JsonSerializable()
class JournalSubmitResponse {
  final String status;
  final String message;
  final JournalSubmitData? data;

  JournalSubmitResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory JournalSubmitResponse.fromJson(Map<String, dynamic> json) =>
      _$JournalSubmitResponseFromJson(json);

  Map<String, dynamic> toJson() => _$JournalSubmitResponseToJson(this);
}

@JsonSerializable()
class JournalSubmitData {
  @JsonKey(name: 'journal_id')
  final int journalId;

  JournalSubmitData({required this.journalId});

  factory JournalSubmitData.fromJson(Map<String, dynamic> json) =>
      _$JournalSubmitDataFromJson(json);

  Map<String, dynamic> toJson() => _$JournalSubmitDataToJson(this);
}

/// Local state model for tracking student attendance in UI
class StudentAttendanceState {
  final JournalStudent student;
  StudentStatus currentStatus;
  List<String> notes;

  StudentAttendanceState({
    required this.student,
    required this.currentStatus,
    List<String>? notes,
  }) : notes = notes ?? [];

  /// Create from JournalStudent with initial status
  factory StudentAttendanceState.fromStudent(JournalStudent student) {
    // If locked or has scan, default to the initial status
    // Otherwise default to Hadir (common case)
    StudentStatus status = student.initialStatus;
    if (status == StudentStatus.none) {
      status = StudentStatus.hadir; // Default to Hadir for unmarked students
    }
    return StudentAttendanceState(student: student, currentStatus: status);
  }

  /// Convert to submission entry
  StudentAttendanceEntry toEntry() {
    return StudentAttendanceEntry(
      studentId: student.id,
      status: currentStatus.jsonValue,
      notes: notes.isNotEmpty ? notes : null,
    );
  }
}
