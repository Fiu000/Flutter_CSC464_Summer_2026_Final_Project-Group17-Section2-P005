import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/routine_model.dart';
import '../models/course_model.dart';
import '../providers/routine_provider.dart';
import '../providers/course_provider.dart';

class RoutineScreen extends StatefulWidget {
  const RoutineScreen({super.key});

  @override
  State<RoutineScreen> createState() => _RoutineScreenState();
}

class _RoutineScreenState extends State<RoutineScreen> {
  final List<String> days = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoutineProvider>().getRoutines();
      context.read<CourseProvider>().getCourses();
    });
  }

  String getCourseName(String courseId, List<CourseModel> courses) {
    try {
      final course = courses.firstWhere((item) => item.id == courseId);

      return '${course.courseCode} - ${course.courseName}';
    } catch (_) {
      return 'Unknown Course';
    }
  }

  void showRoutineDialog({RoutineModel? routine}) {
    final routineProvider = context.read<RoutineProvider>();
    final courseProvider = context.read<CourseProvider>();

    if (courseProvider.courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please create a course first.')),
      );
      return;
    }

    String? selectedCourseId = routine?.courseId;
    String selectedDay = routine?.day ?? 'Sunday';
    TimeOfDay? selectedTime;

    if (routine?.time != null && routine!.time.isNotEmpty) {
      final parts = routine.time.split(':');

      if (parts.length == 2) {
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);

        if (hour != null && minute != null) {
          selectedTime = TimeOfDay(hour: hour, minute: minute);
        }
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                routine == null ? 'Add Class Routine' : 'Edit Class Routine',
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedCourseId,
                      decoration: const InputDecoration(
                        labelText: 'Course',
                        border: OutlineInputBorder(),
                      ),
                      items: courseProvider.courses.map((course) {
                        return DropdownMenuItem<String>(
                          value: course.id,
                          child: Text(
                            '${course.courseCode} - ${course.courseName}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCourseId = value;
                        });
                      },
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      initialValue: selectedDay,
                      decoration: const InputDecoration(
                        labelText: 'Day',
                        border: OutlineInputBorder(),
                      ),
                      items: days.map((day) {
                        return DropdownMenuItem<String>(
                          value: day,
                          child: Text(day),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedDay = value;
                          });
                        }
                      },
                    ),

                    const SizedBox(height: 15),

                    InkWell(
                      onTap: () async {
                        final pickedTime = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
                        );

                        if (pickedTime != null) {
                          setDialogState(() {
                            selectedTime = pickedTime;
                          });
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Class Time',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedTime == null
                                  ? 'Select time'
                                  : selectedTime!.format(context),
                              style: TextStyle(
                                fontSize: 16,
                                color: selectedTime == null
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),
                            const Icon(Icons.access_time),
                          ],
                        ),
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
                  onPressed: selectedCourseId == null || selectedTime == null
                      ? null
                      : () async {
                          final hour = selectedTime!.hour.toString().padLeft(
                            2,
                            '0',
                          );

                          final minute = selectedTime!.minute
                              .toString()
                              .padLeft(2, '0');

                          final time = '$hour:$minute';

                          if (routine == null) {
                            final id = DateTime.now().microsecondsSinceEpoch
                                .toString();

                            final newRoutine = RoutineModel(
                              id: id,
                              courseId: selectedCourseId!,
                              day: selectedDay,
                              time: time,
                            );

                            await routineProvider.addRoutine(newRoutine);
                          } else {
                            final updatedRoutine = RoutineModel(
                              id: routine.id,
                              courseId: selectedCourseId!,
                              day: selectedDay,
                              time: time,
                            );

                            await routineProvider.updateRoutine(updatedRoutine);
                          }

                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext);
                          }
                        },
                  child: Text(routine == null ? 'Add' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void confirmDelete(RoutineModel routine) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Routine'),
          content: const Text(
            'Are you sure you want to delete this class routine?',
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
                await context.read<RoutineProvider>().deleteRoutine(routine.id);

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

  int dayOrder(String day) {
    return days.indexOf(day);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Class Routine',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),

      body: Consumer2<RoutineProvider, CourseProvider>(
        builder: (context, routineProvider, courseProvider, child) {
          if (routineProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (routineProvider.routines.isEmpty) {
            return const Center(
              child: Text(
                'No class routines found.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final sortedRoutines = List<RoutineModel>.from(
            routineProvider.routines,
          );

          sortedRoutines.sort((a, b) {
            final dayComparison = dayOrder(a.day).compareTo(dayOrder(b.day));

            if (dayComparison != 0) {
              return dayComparison;
            }

            return a.time.compareTo(b.time);
          });

          return ListView(
            padding: const EdgeInsets.all(12),
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 4, right: 4, bottom: 12),
                child: Text(
                  'Weekly Schedule',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),

              ...days.map((day) {
                final dayRoutines = sortedRoutines
                    .where((routine) => routine.day == day)
                    .toList();

                if (dayRoutines.isEmpty) {
                  return const SizedBox.shrink();
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 14),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              day,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const Divider(),

                        ...dayRoutines.map((routine) {
                          final course = courseProvider.courses
                              .where((item) => item.id == routine.courseId)
                              .firstOrNull;

                          final courseTitle = course == null
                              ? 'Unknown Course'
                              : course.courseCode;

                          final courseName = course == null
                              ? ''
                              : course.courseName;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                            ),
                            leading: const CircleAvatar(
                              backgroundColor: Colors.orange,
                              child: Icon(Icons.menu_book, color: Colors.white),
                            ),
                            title: Text(
                              courseTitle,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '$courseName\nTime: ${routine.time}',
                            ),
                            isThreeLine: true,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit,
                                    color: Colors.blue,
                                  ),
                                  onPressed: () {
                                    showRoutineDialog(routine: routine);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    confirmDelete(routine);
                                  },
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              }),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showRoutineDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Routine'),
      ),
    );
  }
}
