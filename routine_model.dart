class RoutineModel {
  final String id;
  final String courseId;
  final String day;
  final String time;

  RoutineModel({
    required this.id,
    required this.courseId,
    required this.day,
    required this.time,
  });

  Map<String, dynamic> toJson() {
    return {'courseId': courseId, 'day': day, 'time': time};
  }

  factory RoutineModel.fromJson(String id, Map<String, dynamic> json) {
    return RoutineModel(
      id: id,
      courseId: json['courseId'] ?? '',
      day: json['day'] ?? '',
      time: json['time'] ?? '',
    );
  }
}
