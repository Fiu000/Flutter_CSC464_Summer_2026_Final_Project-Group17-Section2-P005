import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/attendance_model.dart';
import '../models/course_model.dart';
import '../models/student_model.dart';
import '../providers/attendance_provider.dart';
import '../providers/course_provider.dart';
import '../providers/student_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AttendanceProvider>().getAttendances();
      context.read<CourseProvider>().getCourses();
      context.read<StudentProvider>().getStudents();
    });
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // ============================================================
  // TAKE / EDIT ATTENDANCE
  // ============================================================

  void showAttendanceDialog({AttendanceModel? attendance}) {
    final courseProvider = context.read<CourseProvider>();
    final studentProvider = context.read<StudentProvider>();

    CourseModel? selectedCourse;

    if (attendance != null) {
      try {
        selectedCourse = courseProvider.courses.firstWhere(
          (course) => course.id == attendance.courseId,
        );
      } catch (_) {
        selectedCourse = null;
      }
    }

    DateTime selectedDate = attendance?.date ?? DateTime.now();

    final Map<String, String> records = Map<String, String>.from(
      attendance?.records ?? {},
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final enrolledStudents = selectedCourse == null
                ? <StudentModel>[]
                : studentProvider.students
                      .where(
                        (student) =>
                            selectedCourse!.studentIds.contains(student.id),
                      )
                      .toList();

            return AlertDialog(
              title: Text(
                attendance == null ? 'Take Attendance' : 'Edit Attendance',
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<CourseModel>(
                        initialValue: selectedCourse,
                        decoration: const InputDecoration(
                          labelText: 'Select Course',
                          border: OutlineInputBorder(),
                        ),
                        items: courseProvider.courses
                            .map(
                              (course) => DropdownMenuItem<CourseModel>(
                                value: course,
                                child: Text(
                                  '${course.courseCode} - '
                                  '${course.courseName}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: attendance != null
                            ? null
                            : (value) {
                                setDialogState(() {
                                  selectedCourse = value;
                                  records.clear();
                                });
                              },
                      ),

                      const SizedBox(height: 15),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today),
                        title: const Text('Attendance Date'),
                        subtitle: Text(formatDate(selectedDate)),
                        onTap: () async {
                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );

                          if (pickedDate != null) {
                            setDialogState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                      ),

                      const SizedBox(height: 10),

                      if (selectedCourse == null)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Please select a course first.'),
                        ),

                      if (selectedCourse != null && enrolledStudents.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('No students enrolled in this course.'),
                        ),

                      if (enrolledStudents.isNotEmpty)
                        Column(
                          children: enrolledStudents.map((student) {
                            final status = records[student.id] ?? 'Absent';

                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person),
                                ),
                                title: Text(
                                  student.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text('ID: ${student.studentId}'),
                                trailing: DropdownButton<String>(
                                  value: status,
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Present',
                                      child: Text('Present'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Absent',
                                      child: Text('Absent'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;

                                    setDialogState(() {
                                      records[student.id] = value;
                                    });
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                    ],
                  ),
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
                  onPressed: selectedCourse == null || enrolledStudents.isEmpty
                      ? null
                      : () async {
                          final provider = context.read<AttendanceProvider>();

                          try {
                            if (attendance == null) {
                              final newAttendance = AttendanceModel(
                                id: '',
                                courseId: selectedCourse!.id,
                                date: selectedDate,
                                records: records,
                              );

                              await provider.addAttendance(newAttendance);
                            } else {
                              final updatedAttendance = AttendanceModel(
                                id: attendance.id,
                                courseId: attendance.courseId,
                                date: selectedDate,
                                records: records,
                              );

                              await provider.updateAttendance(
                                updatedAttendance,
                              );
                            }

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext);
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Failed to save attendance: $e',
                                  ),
                                ),
                              );
                            }
                          }
                        },
                  child: Text(attendance == null ? 'Save' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ============================================================
  // DELETE ATTENDANCE
  // ============================================================

  void confirmDelete(AttendanceModel attendance) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Attendance'),
          content: const Text(
            'Are you sure you want to delete this attendance record?',
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
                try {
                  await context.read<AttendanceProvider>().deleteAttendance(
                    attendance.id,
                  );

                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                  }
                } catch (e) {
                  if (dialogContext.mounted) {
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(
                        content: Text('Failed to delete attendance: $e'),
                      ),
                    );
                  }
                }
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ATTENDANCE SUMMARY
  // ============================================================

  void showAttendanceSummary(
    BuildContext context,
    CourseModel course,
    List<StudentModel> students,
    List<AttendanceModel> attendances,
  ) {
    final courseAttendances = attendances
        .where((attendance) => attendance.courseId == course.id)
        .toList();

    final enrolledStudents = students
        .where((student) => course.studentIds.contains(student.id))
        .toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(
            '${course.courseCode} - Attendance Summary',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: courseAttendances.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No attendance has been taken for this course yet.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: enrolledStudents.map((student) {
                        int present = 0;
                        int absent = 0;

                        for (final attendance in courseAttendances) {
                          final status = attendance.records[student.id];

                          if (status == 'Present') {
                            present++;
                          } else if (status == 'Absent') {
                            absent++;
                          }
                        }

                        final totalClasses = present + absent;

                        final percentage = totalClasses == 0
                            ? 0.0
                            : (present / totalClasses) * 100;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      child: Icon(Icons.person),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            student.name,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'ID: ${student.studentId}',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 15),

                                Row(
                                  children: [
                                    Expanded(
                                      child: _summaryItem(
                                        'Present',
                                        present.toString(),
                                        Colors.green,
                                      ),
                                    ),
                                    Expanded(
                                      child: _summaryItem(
                                        'Absent',
                                        absent.toString(),
                                        Colors.red,
                                      ),
                                    ),
                                    Expanded(
                                      child: _summaryItem(
                                        'Total',
                                        totalClasses.toString(),
                                        Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 12),

                                const Text(
                                  'Attendance Percentage',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),

                                const SizedBox(height: 6),

                                LinearProgressIndicator(
                                  value: totalClasses == 0
                                      ? 0
                                      : present / totalClasses,
                                  minHeight: 8,
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  '${percentage.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: percentage >= 75
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _summaryItem(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(title, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ============================================================
  // ATTENDANCE HISTORY CARD
  // ============================================================

  Widget _buildAttendanceHistoryCard(
    BuildContext context,
    AttendanceModel attendance,
    CourseModel? course,
    List<StudentModel> students,
  ) {
    final enrolledStudents = students
        .where(
          (student) => course != null && course.studentIds.contains(student.id),
        )
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: const CircleAvatar(child: Icon(Icons.fact_check)),
        title: Text(
          course?.courseCode ?? 'Unknown Course',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Date: ${formatDate(attendance.date)}'),
        children: [
          if (enrolledStudents.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No enrolled students found.'),
            ),

          ...enrolledStudents.map((student) {
            final status = attendance.records[student.id] ?? 'Absent';

            final isPresent = status == 'Present';

            return ListTile(
              leading: Icon(
                isPresent ? Icons.check_circle : Icons.cancel,
                color: isPresent ? Colors.green : Colors.red,
              ),
              title: Text(student.name),
              subtitle: Text('ID: ${student.studentId}'),
              trailing: Text(
                status,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPresent ? Colors.green : Colors.red,
                ),
              ),
            );
          }),

          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  tooltip: 'Edit',
                  onPressed: () {
                    showAttendanceDialog(attendance: attendance);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () {
                    confirmDelete(attendance);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAIN SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),

      body: Consumer3<AttendanceProvider, CourseProvider, StudentProvider>(
        builder:
            (
              context,
              attendanceProvider,
              courseProvider,
              studentProvider,
              child,
            ) {
              if (attendanceProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ==================================================
                    // TAKE ATTENDANCE BUTTON
                    // ==================================================
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          showAttendanceDialog();
                        },
                        icon: const Icon(Icons.fact_check),
                        label: const Text(
                          'Take Attendance',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ==================================================
                    // ATTENDANCE SUMMARY
                    // ==================================================
                    const Text(
                      'Attendance Summary',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (courseProvider.courses.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(child: Text('No courses available.')),
                        ),
                      )
                    else
                      ...courseProvider.courses.map((course) {
                        final courseAttendance = attendanceProvider.attendances
                            .where(
                              (attendance) => attendance.courseId == course.id,
                            )
                            .toList();

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.menu_book),
                            ),
                            title: Text(
                              course.courseCode,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${course.courseName}\n'
                              'Classes held: '
                              '${courseAttendance.length}',
                            ),
                            isThreeLine: true,
                            trailing: ElevatedButton(
                              onPressed: courseAttendance.isEmpty
                                  ? null
                                  : () {
                                      showAttendanceSummary(
                                        context,
                                        course,
                                        studentProvider.students,
                                        attendanceProvider.attendances,
                                      );
                                    },
                              child: const Text('View Summary'),
                            ),
                          ),
                        );
                      }),

                    const SizedBox(height: 25),

                    // ==================================================
                    // ATTENDANCE HISTORY
                    // ==================================================
                    const Text(
                      'Attendance History',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    if (attendanceProvider.attendances.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(20),
                          child: Center(
                            child: Text('No attendance records found.'),
                          ),
                        ),
                      )
                    else
                      ...attendanceProvider.attendances.map((attendance) {
                        CourseModel? course;

                        try {
                          course = courseProvider.courses.firstWhere(
                            (item) => item.id == attendance.courseId,
                          );
                        } catch (_) {
                          course = null;
                        }

                        return _buildAttendanceHistoryCard(
                          context,
                          attendance,
                          course,
                          studentProvider.students,
                        );
                      }),
                  ],
                ),
              );
            },
      ),
    );
  }
}
