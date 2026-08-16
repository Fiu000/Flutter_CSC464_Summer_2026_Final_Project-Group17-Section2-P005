class AttendanceModel {
  final String id;
  final String courseId;
  final DateTime date;
  final Map<String, String> records;

  AttendanceModel({
    required this.id,
    required this.courseId,
    required this.date,
    required this.records,
  });

  Map<String, dynamic> toJson() {
    return {'courseId': courseId, 'date': date, 'records': records};
  }

  factory AttendanceModel.fromJson(String id, Map<String, dynamic> json) {
    return AttendanceModel(
      id: id,
      courseId: json['courseId'] ?? '',
      date: json['date'] is DateTime ? json['date'] : json['date'].toDate(),
      records: Map<String, String>.from(json['records'] ?? {}),
    );
  }
}
