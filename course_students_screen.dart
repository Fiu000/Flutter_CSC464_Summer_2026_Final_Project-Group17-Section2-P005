import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_model.dart';
import '../models/student_model.dart';
import '../providers/course_provider.dart';
import '../providers/student_provider.dart';

class CourseStudentsScreen extends StatelessWidget {
  final CourseModel course;

  const CourseStudentsScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);
    final studentProvider = Provider.of<StudentProvider>(context);

    final currentCourse = courseProvider.courses.firstWhere(
      (item) => item.id == course.id,
      orElse: () => course,
    );

    final enrolledStudents = studentProvider.students
        .where((student) => currentCourse.studentIds.contains(student.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${currentCourse.courseCode} - Students',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: enrolledStudents.isEmpty
          ? const Center(
              child: Text(
                'No students enrolled in this course.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: enrolledStudents.length,
              itemBuilder: (context, index) {
                final student = enrolledStudents[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(
                      student.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      'Student ID: ${student.studentId}\n'
                      'Email: ${student.email}',
                    ),
                    isThreeLine: true,
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      tooltip: 'Remove from course',
                      onPressed: () {
                        _removeStudent(
                          context,
                          courseProvider,
                          currentCourse,
                          student,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showAddStudentDialog(
            context,
            courseProvider,
            studentProvider,
            currentCourse,
          );
        },
        icon: const Icon(Icons.person_add),
        label: const Text('Add Student'),
      ),
    );
  }

  void _showAddStudentDialog(
    BuildContext context,
    CourseProvider courseProvider,
    StudentProvider studentProvider,
    CourseModel currentCourse,
  ) {
    final availableStudents = studentProvider.students
        .where((student) => !currentCourse.studentIds.contains(student.id))
        .toList();

    if (availableStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available students to add.')),
      );
      return;
    }

    StudentModel? selectedStudent;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Student to Course'),
              content: DropdownButtonFormField<StudentModel>(
                initialValue: selectedStudent,
                decoration: const InputDecoration(
                  labelText: 'Select Student',
                  border: OutlineInputBorder(),
                ),
                items: availableStudents.map((student) {
                  return DropdownMenuItem<StudentModel>(
                    value: student,
                    child: Text('${student.studentId} - ${student.name}'),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStudent = value;
                  });
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: selectedStudent == null
                      ? null
                      : () async {
                          await courseProvider.addStudentToCourse(
                            currentCourse.id,
                            selectedStudent!.id,
                          );

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _removeStudent(
    BuildContext context,
    CourseProvider courseProvider,
    CourseModel currentCourse,
    StudentModel student,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Remove Student'),
          content: Text(
            'Remove ${student.name} from '
            '${currentCourse.courseCode}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await courseProvider.removeStudentFromCourse(
                  currentCourse.id,
                  student.id,
                );

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
}
