import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/course_model.dart';
import '../providers/course_provider.dart';
import 'course_students_screen.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final courseProvider = Provider.of<CourseProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Courses',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: courseProvider.courses.isEmpty
          ? const Center(
              child: Text('No courses found', style: TextStyle(fontSize: 18)),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courseProvider.courses.length,
              itemBuilder: (context, index) {
                final course = courseProvider.courses[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.menu_book)),
                    title: Text(
                      course.courseCode,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${course.courseName}\n'
                      'Instructor: ${course.instructor}\n'
                      'Students: ${course.studentIds.length}',
                    ),
                    isThreeLine: true,

                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CourseStudentsScreen(course: course),
                        ),
                      );
                    },

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit),
                          tooltip: 'Edit Course',
                          onPressed: () {
                            _showCourseDialog(
                              context,
                              courseProvider,
                              course: course,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          tooltip: 'Delete Course',
                          onPressed: () {
                            _confirmDelete(context, courseProvider, course);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCourseDialog(context, courseProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Course'),
      ),
    );
  }

  void _showCourseDialog(
    BuildContext context,
    CourseProvider provider, {
    CourseModel? course,
  }) {
    final codeController = TextEditingController(
      text: course?.courseCode ?? '',
    );

    final nameController = TextEditingController(
      text: course?.courseName ?? '',
    );

    final instructorController = TextEditingController(
      text: course?.instructor ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(course == null ? 'Add Course' : 'Edit Course'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: codeController,
                  decoration: const InputDecoration(
                    labelText: 'Course Code',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Course Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: instructorController,
                  decoration: const InputDecoration(
                    labelText: 'Instructor',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
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
                if (codeController.text.trim().isEmpty ||
                    nameController.text.trim().isEmpty ||
                    instructorController.text.trim().isEmpty) {
                  return;
                }

                if (course == null) {
                  await provider.addCourse(
                    CourseModel(
                      id: '',
                      courseCode: codeController.text.trim(),
                      courseName: nameController.text.trim(),
                      instructor: instructorController.text.trim(),
                      studentIds: [],
                    ),
                  );
                } else {
                  await provider.updateCourse(
                    course.copyWith(
                      courseCode: codeController.text.trim(),
                      courseName: nameController.text.trim(),
                      instructor: instructorController.text.trim(),
                    ),
                  );
                }

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: Text(course == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    CourseProvider provider,
    CourseModel course,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Course'),
          content: Text(
            'Are you sure you want to delete ${course.courseCode}?',
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
                await provider.deleteCourse(course.id);

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}
