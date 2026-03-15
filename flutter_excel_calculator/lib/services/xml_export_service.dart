import 'dart:convert';
import 'dart:typed_data';
import 'package:xml/xml.dart';
import '../models/student.dart';

/// Service for exporting student GPA results to XML format
class XmlExportService {
  /// Generate XML document with student results
  static Future<Uint8List> generateXml({
    required List<Student> students,
    required List<String> subjectColumns,
    required double classAverage,
  }) async {
    // Create the root element
    final builder = XmlBuilder();

    builder.processing('xml', 'version="1.0" encoding="UTF-8"');
    builder.element('GPAReport', nest: () {
      // Report metadata
      builder.element('Metadata', nest: () {
        builder.element('GeneratedDate', nest: _formatDateTime(DateTime.now()));
        builder.element('TotalStudents', nest: students.length.toString());
        builder.element('ClassAverage', nest: classAverage.toStringAsFixed(2));
        builder.element('Application', nest: 'Excel Calculator App');
        builder.element('Version', nest: '1.0');
      });

      // Subject definitions
      builder.element('Subjects', nest: () {
        for (final subject in subjectColumns) {
          builder.element('Subject', nest: () {
            builder.attribute('name', subject);
          });
        }
      });

      // GPA Scale definitions
      builder.element('GPAScale', nest: () {
        _buildGPAScale(builder);
      });

      // Students data
      builder.element('Students', nest: () {
        for (final student in students) {
          _buildStudentElement(builder, student, subjectColumns);
        }
      });

      // Statistics summary
      builder.element('Statistics', nest: () {
        _buildStatistics(builder, students);
      });
    });

    // Build the XML document
    final xmlDocument = builder.buildDocument();

    // Convert to bytes with pretty printing
    final xmlString = xmlDocument.toXmlString(pretty: true, indent: '  ');
    return Uint8List.fromList(utf8.encode(xmlString));
  }

  static void _buildStudentElement(
    XmlBuilder builder,
    Student student,
    List<String> subjectColumns,
  ) {
    builder.element('Student', nest: () {
      builder.attribute('name', student.name);
      builder.attribute('average', student.average.toStringAsFixed(2));
      builder.attribute('gpa', student.gpa);

      // Subject grades
      builder.element('Subjects', nest: () {
        for (final subject in subjectColumns) {
          final grade = student.subjects[subject] ?? 0.0;
          builder.element('Subject', nest: () {
            builder.attribute('name', subject);
            builder.attribute('grade', grade.toStringAsFixed(2));
          });
        }
      });

      // GPA details
      builder.element('GPADetails', nest: () {
        builder.element('Grade', nest: student.gpa);
        builder.element('GradePoints', nest: _getGradePoints(student.gpa).toString());
        builder.element('Status', nest: _getStatus(student.gpa));
      });
    });
  }

  static void _buildGPAScale(XmlBuilder builder) {
    final scale = [
      {'grade': 'A', 'min': '80', 'max': '100', 'points': '4.0'},
      {'grade': 'B', 'min': '70', 'max': '79', 'points': '3.0'},
      {'grade': 'C+', 'min': '60', 'max': '69', 'points': '2.5'},
      {'grade': 'C', 'min': '50', 'max': '59', 'points': '2.0'},
      {'grade': 'D', 'min': '35', 'max': '49', 'points': '1.0'},
      {'grade': 'F', 'min': '0', 'max': '34', 'points': '0.0'},
    ];

    for (final item in scale) {
      builder.element('Grade', nest: () {
        builder.attribute('letter', item['grade']!);
        builder.attribute('minRange', item['min']!);
        builder.attribute('maxRange', item['max']!);
        builder.attribute('points', item['points']!);
      });
    }
  }

  static void _buildStatistics(XmlBuilder builder, List<Student> students) {
    // Calculate GPA distribution
    final gpaCounts = <String, int>{};
    for (final student in students) {
      gpaCounts[student.gpa] = (gpaCounts[student.gpa] ?? 0) + 1;
    }

    // Overall statistics
    builder.element('Overall', nest: () {
      builder.element('TotalStudents', nest: students.length.toString());
      builder.element('ClassAverage', nest: _calculateClassAverage(students).toStringAsFixed(2));

      final passedCount = students.where((s) => s.gpa != 'F').length;
      builder.element('Passed', nest: passedCount.toString());
      builder.element('Failed', nest: (students.length - passedCount).toString());
      builder.element('PassRate', nest: '${(passedCount / students.length * 100).toStringAsFixed(1)}%');
    });

    // GPA distribution
    builder.element('GPADistribution', nest: () {
      final sortedGPAs = ['A', 'B', 'C+', 'C', 'D', 'F'];
      for (final gpa in sortedGPAs) {
        final count = gpaCounts[gpa] ?? 0;
        final percentage = students.isNotEmpty
            ? (count / students.length * 100).toStringAsFixed(1)
            : '0.0';

        builder.element('Grade', nest: () {
          builder.attribute('letter', gpa);
          builder.attribute('count', count.toString());
          builder.attribute('percentage', percentage);
        });
      }
    });

    // Subject averages
    if (students.isNotEmpty) {
      builder.element('SubjectAverages', nest: () {
        final subjectColumns = students.first.subjects.keys.toList();
        for (final subject in subjectColumns) {
          final avg = students
                  .map((s) => s.subjects[subject] ?? 0.0)
                  .reduce((a, b) => a + b) /
              students.length;
          builder.element('Subject', nest: () {
            builder.attribute('name', subject);
            builder.attribute('average', avg.toStringAsFixed(2));
          });
        }
      });
    }
  }

  static double _calculateClassAverage(List<Student> students) {
    if (students.isEmpty) return 0.0;
    return students.map((s) => s.average).reduce((a, b) => a + b) / students.length;
  }

  static double _getGradePoints(String gpa) {
    switch (gpa) {
      case 'A':
        return 4.0;
      case 'B':
        return 3.0;
      case 'C+':
        return 2.5;
      case 'C':
        return 2.0;
      case 'D':
        return 1.0;
      case 'F':
        return 0.0;
      default:
        return 0.0;
    }
  }

  static String _getStatus(String gpa) {
    return gpa == 'F' ? 'Failed' : 'Passed';
  }

  static String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')}';
  }
}
