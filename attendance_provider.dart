import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/attendance_model.dart';

class AttendanceProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String collectionName = 'attendance';

  List<AttendanceModel> attendances = [];

  bool isLoading = false;

  // READ ALL ATTENDANCE
  void getAttendances() {
    isLoading = true;
    notifyListeners();

    _firestore
        .collection(collectionName)
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
          attendances = snapshot.docs.map((doc) {
            return AttendanceModel.fromJson(doc.id, doc.data());
          }).toList();

          isLoading = false;
          notifyListeners();
        });
  }

  // GET ATTENDANCE FOR ONE COURSE
  List<AttendanceModel> getCourseAttendance(String courseId) {
    return attendances
        .where((attendance) => attendance.courseId == courseId)
        .toList();
  }

  // CREATE
  Future<void> addAttendance(AttendanceModel attendance) async {
    final docRef = _firestore.collection(collectionName).doc();

    final newAttendance = AttendanceModel(
      id: docRef.id,
      courseId: attendance.courseId,
      date: attendance.date,
      records: attendance.records,
    );

    await docRef.set(newAttendance.toJson());
  }

  // UPDATE
  Future<void> updateAttendance(AttendanceModel attendance) async {
    await _firestore
        .collection(collectionName)
        .doc(attendance.id)
        .update(attendance.toJson());
  }

  // DELETE
  Future<void> deleteAttendance(String id) async {
    await _firestore.collection(collectionName).doc(id).delete();
  }

  // TOTAL CLASSES FOR A COURSE
  int getTotalClasses(String courseId) {
    return attendances
        .where((attendance) => attendance.courseId == courseId)
        .length;
  }

  // CLASSES ATTENDED BY A STUDENT
  int getStudentAttendedClasses(String courseId, String studentId) {
    int attended = 0;

    final courseAttendance = attendances.where(
      (attendance) => attendance.courseId == courseId,
    );

    for (final attendance in courseAttendance) {
      if (attendance.records[studentId] == 'Present') {
        attended++;
      }
    }

    return attended;
  }

  // ATTENDANCE PERCENTAGE
  double getAttendancePercentage(String courseId, String studentId) {
    final totalClasses = getTotalClasses(courseId);

    if (totalClasses == 0) {
      return 0;
    }

    final attendedClasses = getStudentAttendedClasses(courseId, studentId);

    return (attendedClasses / totalClasses) * 100;
  }
}
