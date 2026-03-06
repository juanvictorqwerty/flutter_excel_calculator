import 'dart:convert';
import 'dart:typed_data';
import '../models/student.dart';

class DocxExportService {
  static Future<Uint8List> generateDocx({
    required List<Student> students,
    required List<String> subjectColumns,
    required double classAverage,
  }) async {
    final now = DateTime.now();
    final dateStr = _formatDate(now);
    final dateTimeStr = _formatDateTime(now);

    final buffer = StringBuffer();

    buffer.write('<!DOCTYPE html>');
    buffer.write('<html>');
    buffer.write('<head>');
    buffer.write('<meta charset="UTF-8">');
    buffer.write('<title>GPA Results Report</title>');
    buffer.write('<style>');
    buffer.write('body { font-family: Calibri, Arial, sans-serif; margin: 40px; }');
    buffer.write('.header { text-align: center; border-bottom: 2px solid #2E75B6; padding-bottom: 10px; }');
    buffer.write('.header h1 { color: #2E75B6; font-size: 24pt; margin: 0; }');
    buffer.write('.summary { background-color: #D6E3F8; padding: 15px; border-radius: 8px; margin: 20px 0; }');
    buffer.write('table { width: 100%; border-collapse: collapse; margin: 10px 0; }');
    buffer.write('th { background-color: #B4C6E7; color: #1F4E79; padding: 10px; border: 1px solid #999; }');
    buffer.write('td { padding: 8px; border: 1px solid #999; text-align: center; }');
    buffer.write('.gpa-A { background-color: #138808; color: white; padding: 4px 12px; border-radius: 12px; }');
    buffer.write('.gpa-B { background-color: #0066CC; color: white; padding: 4px 12px; border-radius: 12px; }');
    buffer.write('.gpa-Cplus { background-color: #008080; color: white; padding: 4px 12px; border-radius: 12px; }');
    buffer.write('.gpa-C { background-color: #FF8C00; color: white; padding: 4px 12px; border-radius: 12px; }');
    buffer.write('.gpa-D { background-color: #FF4500; color: white; padding: 4px 12px; border-radius: 12px; }');
    buffer.write('.gpa-F { background-color: #CC0000; color: white; padding: 4px 12px; border-radius: 12px; }');
    buffer.write('.legend-item { display: inline-block; margin: 3px 8px; padding: 4px 10px; border-radius: 12px; font-size: 9pt; color: white; }');
    buffer.write('</style>');
    buffer.write('</head>');
    buffer.write('<body>');

    // Header
    buffer.write('<div class="header">');
    buffer.write('<h1>GPA Results Report</h1>');
    buffer.write('<p>Generated: $dateTimeStr</p>');
    buffer.write('</div>');

    // Summary
    buffer.write('<div class="summary">');
    buffer.write('<table>');
    buffer.write('<tr>');
    buffer.write('<td><strong>${students.length}</strong><br>Total Students</td>');
    buffer.write('<td><strong>${classAverage.toStringAsFixed(2)}</strong><br>Class Average</td>');
    buffer.write('<td><strong>$dateStr</strong><br>Report Date</td>');
    buffer.write('</tr>');
    buffer.write('</table>');
    buffer.write('</div>');

    // Legend
    buffer.write('<h2>GPA Scale</h2>');
    buffer.write('<span class="legend-item gpa-A">A (80-100)</span>');
    buffer.write('<span class="legend-item gpa-B">B (70-79)</span>');
    buffer.write('<span class="legend-item gpa-Cplus">C+ (60-69)</span>');
    buffer.write('<span class="legend-item gpa-C">C (50-59)</span>');
    buffer.write('<span class="legend-item gpa-D">D (35-49)</span>');
    buffer.write('<span class="legend-item gpa-F">F (0-34)</span>');

    // Main Results Table
    buffer.write('<h2>Student Results</h2>');
    buffer.write('<table>');
    buffer.write('<tr><th>Name</th><th>Average</th><th>GPA</th></tr>');
    for (final student in students) {
      buffer.write('<tr>');
      buffer.write('<td>${_escapeHtml(student.name)}</td>');
      buffer.write('<td>${student.average.toStringAsFixed(2)}</td>');
      buffer.write('<td><span class="${_gpaClass(student.gpa)}">${student.gpa}</span></td>');
      buffer.write('</tr>');
    }
    buffer.write('</table>');

    // Subject Grades
    buffer.write('<h2>Detailed Subject Grades</h2>');
    buffer.write('<table>');
    buffer.write('<tr><th>Name</th>');
    for (final subject in subjectColumns) {
      buffer.write('<th>${_escapeHtml(subject)}</th>');
    }
    buffer.write('<th>Avg</th><th>GPA</th></tr>');
    for (final student in students) {
      buffer.write('<tr>');
      buffer.write('<td>${_escapeHtml(student.name)}</td>');
      for (final subject in subjectColumns) {
        final grade = student.subjects[subject] ?? 0.0;
        buffer.write('<td>${grade.toStringAsFixed(1)}</td>');
      }
      buffer.write('<td><strong>${student.average.toStringAsFixed(2)}</strong></td>');
      buffer.write('<td><span class="${_gpaClass(student.gpa)}">${student.gpa}</span></td>');
      buffer.write('</tr>');
    }
    buffer.write('</table>');

    // Statistics
    buffer.write('<h2>Statistics Summary</h2>');
    buffer.write(_buildStatsTable(students));

    buffer.write('</body>');
    buffer.write('</html>');

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  static String _buildStatsTable(List<Student> students) {
    final buffer = StringBuffer();
    final gpaCounts = <String, int>{};
    for (final student in students) {
      gpaCounts[student.gpa] = (gpaCounts[student.gpa] ?? 0) + 1;
    }

    buffer.write('<table>');
    buffer.write('<tr><th>GPA Grade</th><th>Count</th><th>Percentage</th></tr>');
    for (final gpa in ['A', 'B', 'C+', 'C', 'D', 'F']) {
      final count = gpaCounts[gpa] ?? 0;
      final percentage = students.isNotEmpty
          ? (count / students.length * 100).toStringAsFixed(1)
          : '0.0';
      buffer.write('<tr>');
      buffer.write('<td><span class="${_gpaClass(gpa)}">$gpa</span></td>');
      buffer.write('<td>$count</td>');
      buffer.write('<td>$percentage%</td>');
      buffer.write('</tr>');
    }
    buffer.write('</table>');
    return buffer.toString();
  }

  static String _gpaClass(String gpa) {
    switch (gpa) {
      case 'A': return 'gpa-A';
      case 'B': return 'gpa-B';
      case 'C+': return 'gpa-Cplus';
      case 'C': return 'gpa-C';
      case 'D': return 'gpa-D';
      case 'F': return 'gpa-F';
      default: return 'gpa-F';
    }
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&')
        .replaceAll('<', '<')
        .replaceAll('>', '>')
        .replaceAll('"', '"');
  }

  static String _formatDate(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String _formatDateTime(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min';
  }
}
