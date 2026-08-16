import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/course_model.dart';

class CourseProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String collectionName = 'courses';

  List<CourseModel> courses = [];

  bool isLoading = false;

  // READ
  void getCourses() {
    isLoading = true;
    notifyListeners();

    _firestore.collection(collectionName).snapshots().listen((snapshot) {
      courses = snapshot.docs.map((doc) {
        return CourseModel.fromJson(doc.id, doc.data());
      }).toList();

      isLoading = false;
      notifyListeners();
    });
  }

  // CREATE
  Future<void> addCourse(CourseModel course) async {
    final docRef = await _firestore
        .collection(collectionName)
        .add(course.toJson());

    final savedCourse = course.copyWith();

    final index = courses.indexWhere((item) => item.id == course.id);

    if (index != -1) {
      courses[index] = CourseModel(
        id: docRef.id,
        courseCode: savedCourse.courseCode,
        courseName: savedCourse.courseName,
        instructor: savedCourse.instructor,
        studentIds: savedCourse.studentIds,
      );
      notifyListeners();
    }
  }

  // UPDATE
  Future<void> updateCourse(CourseModel course) async {
    await _firestore
        .collection(collectionName)
        .doc(course.id)
        .update(course.toJson());
  }

  // DELETE
  Future<void> deleteCourse(String id) async {
    await _firestore.collection(collectionName).doc(id).delete();
  }

  // ADD STUDENT TO COURSE
  Future<void> addStudentToCourse(String courseId, String studentId) async {
    await _firestore.collection(collectionName).doc(courseId).update({
      'studentIds': FieldValue.arrayUnion([studentId]),
    });
  }

  // REMOVE STUDENT FROM COURSE
  Future<void> removeStudentFromCourse(
    String courseId,
    String studentId,
  ) async {
    await _firestore.collection(collectionName).doc(courseId).update({
      'studentIds': FieldValue.arrayRemove([studentId]),
    });
  }

  // GET STUDENT IDS FOR A COURSE
  List<String> getStudentIdsForCourse(String courseId) {
    final course = courses.cast<CourseModel?>().firstWhere(
      (course) => course?.id == courseId,
      orElse: () => null,
    );

    return course?.studentIds ?? [];
  }
}
