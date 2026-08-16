class CourseModel {
  final String id;
  final String courseCode;
  final String courseName;
  final String instructor;
  final List<String> studentIds;

  CourseModel({
    required this.id,
    required this.courseCode,
    required this.courseName,
    required this.instructor,
    required this.studentIds,
  });

  Map<String, dynamic> toJson() {
    return {
      'courseCode': courseCode,
      'courseName': courseName,
      'instructor': instructor,
      'studentIds': studentIds,
    };
  }

  factory CourseModel.fromJson(String id, Map<String, dynamic> json) {
    return CourseModel(
      id: id,
      courseCode: json['courseCode'] ?? '',
      courseName: json['courseName'] ?? '',
      instructor: json['instructor'] ?? '',
      studentIds: List<String>.from(json['studentIds'] ?? []),
    );
  }

  CourseModel copyWith({
    String? courseCode,
    String? courseName,
    String? instructor,
    List<String>? studentIds,
  }) {
    return CourseModel(
      id: id,
      courseCode: courseCode ?? this.courseCode,
      courseName: courseName ?? this.courseName,
      instructor: instructor ?? this.instructor,
      studentIds: studentIds ?? this.studentIds,
    );
  }
}
