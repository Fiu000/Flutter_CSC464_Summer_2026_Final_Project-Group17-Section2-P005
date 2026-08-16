import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/student_model.dart';

class StudentProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String collectionName = 'students';

  List<StudentModel> students = [];

  bool isLoading = false;

  // READ
  void getStudents() {
    isLoading = true;
    notifyListeners();

    _firestore.collection(collectionName).snapshots().listen((snapshot) {
      students = snapshot.docs.map((doc) {
        return StudentModel.fromJson(doc.id, doc.data());
      }).toList();

      isLoading = false;
      notifyListeners();
    });
  }

  // CREATE
  Future<void> addStudent(StudentModel student) async {
    final docRef = _firestore.collection(collectionName).doc();

    final newStudent = StudentModel(
      id: docRef.id,
      name: student.name,
      email: student.email,
      studentId: student.studentId,
    );

    await docRef.set(newStudent.toJson());
  }

  // UPDATE
  Future<void> updateStudent(StudentModel student) async {
    await _firestore
        .collection(collectionName)
        .doc(student.id)
        .update(student.toJson());
  }

  // DELETE
  Future<void> deleteStudent(String id) async {
    await _firestore.collection(collectionName).doc(id).delete();
  }
}
