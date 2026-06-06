class InvalClass {
  final int id; // Representing a unique group ID or primary schedule_id
  final List<int> scheduleIds; // List of actual schedule IDs
  final String date;
  final String subject;
  final String time;
  final String className;
  final String absentTeacher;
  final String reason;
  final String status;
  final int durationMinutes;

  InvalClass({
    required this.id,
    required this.scheduleIds,
    required this.date,
    required this.subject,
    required this.time,
    required this.className,
    required this.absentTeacher,
    required this.reason,
    required this.status,
    required this.durationMinutes,
  });

  factory InvalClass.fromJson(Map<String, dynamic> json) {
    // Parse list of integers safely
    final rawIds = json['schedule_ids'];
    List<int> ids = [];
    if (rawIds is List) {
      ids = rawIds.map((e) => int.tryParse(e.toString()) ?? 0).toList();
    } else if (rawIds is int) {
      ids = [rawIds];
    }

    return InvalClass(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      scheduleIds: ids,
      date: json['date']?.toString() ?? '',
      subject: json['subject']?.toString() ?? '',
      time: json['time']?.toString() ?? '',
      className: (json['class_name'] ?? json['className'])?.toString() ?? '',
      absentTeacher:
          (json['absent_teacher'] ?? json['teacherAbsent'])?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      durationMinutes:
          int.tryParse(json['duration_minutes']?.toString() ?? '0') ?? 0,
    );
  }
}
