class StudentModel {
  final String id;
  final String name;
  final String email;
  final String studentId;

  StudentModel({
    required this.id,
    required this.name,
    required this.email,
    required this.studentId,
  });

  Map<String, dynamic> toJson() {
    return {'name': name, 'email': email, 'studentId': studentId};
  }

  factory StudentModel.fromJson(String id, Map<String, dynamic> json) {
    return StudentModel(
      id: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      studentId: json['studentId'] ?? '',
    );
  }
}
