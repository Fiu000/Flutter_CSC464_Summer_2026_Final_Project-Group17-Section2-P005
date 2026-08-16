import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/routine_model.dart';

class RoutineProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String collectionName = 'routines';

  List<RoutineModel> routines = [];

  bool isLoading = false;

  // READ
  void getRoutines() {
    isLoading = true;
    notifyListeners();

    _firestore.collection(collectionName).snapshots().listen((snapshot) {
      routines = snapshot.docs.map((doc) {
        return RoutineModel.fromJson(doc.id, doc.data());
      }).toList();

      isLoading = false;
      notifyListeners();
    });
  }

  // CREATE
  Future<void> addRoutine(RoutineModel routine) async {
    await _firestore
        .collection(collectionName)
        .doc(routine.id)
        .set(routine.toJson());
  }

  // UPDATE
  Future<void> updateRoutine(RoutineModel routine) async {
    await _firestore
        .collection(collectionName)
        .doc(routine.id)
        .update(routine.toJson());
  }

  // DELETE
  Future<void> deleteRoutine(String id) async {
    await _firestore.collection(collectionName).doc(id).delete();
  }
}
