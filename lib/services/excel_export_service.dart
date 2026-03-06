import 'dart:typed_data';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import '../models/student.dart';

/// Service for exporting student GPA results to Excel format
class ExcelExportService {
  /// Generate an Excel workbook with student results
  static Future<Uint8List> generateExcel({
    required List<Student> students,
    required List<String> subjectColumns,
    required double classAverage,
  }) async {
    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'GPA Results';

    // Title
    sheet.getRangeByIndex(1, 1).setText('GPA Results Report');
    sheet.getRangeByIndex(1, 1).cellStyle.fontSize = 16;
    sheet.getRangeByIndex(1, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(1, 1).cellStyle.fontColor = '#2E75B6';

    // Metadata
    sheet.getRangeByIndex(2, 1).setText('Generated: ${_formatDateTime(DateTime.now())}');
    sheet.getRangeByIndex(3, 1).setText('Total Students: ${students.length}');
    sheet.getRangeByIndex(3, 2).setText('Class Average: ${classAverage.toStringAsFixed(2)}');

    // Summary row styling
    sheet.getRangeByIndex(3, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(3, 2).cellStyle.bold = true;

    // Empty row
    int currentRow = 5;

    // Summary Section
    sheet.getRangeByIndex(currentRow, 1).setText('SUMMARY');
    sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 12;
    sheet.getRangeByIndex(currentRow, 1).cellStyle.fontColor = '#2E75B6';
    currentRow++;

    // Summary table headers
    sheet.getRangeByIndex(currentRow, 1).setText('Metric');
    sheet.getRangeByIndex(currentRow, 2).setText('Value');
    _applyHeaderStyle(sheet, currentRow, 1);
    _applyHeaderStyle(sheet, currentRow, 2);
    currentRow++;

    // Summary data
    sheet.getRangeByIndex(currentRow, 1).setText('Total Students');
    sheet.getRangeByIndex(currentRow, 2).setNumber(students.length.toDouble());
    currentRow++;

    sheet.getRangeByIndex(currentRow, 1).setText('Class Average');
    sheet.getRangeByIndex(currentRow, 2).setNumber(classAverage);
    currentRow++;

    final passedCount = students.where((s) => s.gpa != 'F').length;
    sheet.getRangeByIndex(currentRow, 1).setText('Passed');
    sheet.getRangeByIndex(currentRow, 2).setNumber(passedCount.toDouble());
    currentRow++;

    sheet.getRangeByIndex(currentRow, 1).setText('Failed');
    sheet.getRangeByIndex(currentRow, 2).setNumber((students.length - passedCount).toDouble());
    currentRow++;

    sheet.getRangeByIndex(currentRow, 1).setText('Pass Rate (%)');
    final passRate = students.isNotEmpty ? (passedCount / students.length * 100) : 0.0;
    sheet.getRangeByIndex(currentRow, 2).setNumber(passRate);
    currentRow += 2;

    // GPA Distribution
    sheet.getRangeByIndex(currentRow, 1).setText('GPA DISTRIBUTION');
    sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 12;
    sheet.getRangeByIndex(currentRow, 1).cellStyle.fontColor = '#2E75B6';
    currentRow++;

    // Distribution headers
    sheet.getRangeByIndex(currentRow, 1).setText('GPA Grade');
    sheet.getRangeByIndex(currentRow, 2).setText('Count');
    sheet.getRangeByIndex(currentRow, 3).setText('Percentage');
    _applyHeaderStyle(sheet, currentRow, 1);
    _applyHeaderStyle(sheet, currentRow, 2);
    _applyHeaderStyle(sheet, currentRow, 3);
    currentRow++;

    // Calculate distribution
    final gpaCounts = <String, int>{};
    for (final student in students) {
      gpaCounts[student.gpa] = (gpaCounts[student.gpa] ?? 0) + 1;
    }

    final sortedGPAs = ['A', 'B', 'C+', 'C', 'D', 'F'];
    final gpaColors = {
      'A': '#138808',
      'B': '#0066CC',
      'C+': '#008080',
      'C': '#FF8C00',
      'D': '#FF4500',
      'F': '#CC0000',
    };

    for (final gpa in sortedGPAs) {
      final count = gpaCounts[gpa] ?? 0;
      final percentage = students.isNotEmpty ? (count / students.length * 100) : 0.0;

      sheet.getRangeByIndex(currentRow, 1).setText(gpa);
      sheet.getRangeByIndex(currentRow, 1).cellStyle.fontColor = gpaColors[gpa] ?? '#000000';
      sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(currentRow, 2).setNumber(count.toDouble());
      sheet.getRangeByIndex(currentRow, 3).setNumber(percentage);
      currentRow++;
    }

    currentRow += 2;

    // Main Results Table
    sheet.getRangeByIndex(currentRow, 1).setText('STUDENT RESULTS');
    sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 12;
    sheet.getRangeByIndex(currentRow, 1).cellStyle.fontColor = '#2E75B6';
    currentRow++;

    // Headers - Name, Average, GPA
    sheet.getRangeByIndex(currentRow, 1).setText('Name');
    sheet.getRangeByIndex(currentRow, 2).setText('Average');
    sheet.getRangeByIndex(currentRow, 3).setText('GPA');
    _applyHeaderStyle(sheet, currentRow, 1);
    _applyHeaderStyle(sheet, currentRow, 2);
    _applyHeaderStyle(sheet, currentRow, 3);
    currentRow++;

    // Data rows
    for (final student in students) {
      sheet.getRangeByIndex(currentRow, 1).setText(student.name);
      sheet.getRangeByIndex(currentRow, 2).setNumber(student.average);
      sheet.getRangeByIndex(currentRow, 3).setText(student.gpa);
      sheet.getRangeByIndex(currentRow, 3).cellStyle.fontColor = gpaColors[student.gpa] ?? '#000000';
      sheet.getRangeByIndex(currentRow, 3).cellStyle.bold = true;
      currentRow++;
    }

    currentRow += 2;

    // Subject Averages
    if (students.isNotEmpty) {
      sheet.getRangeByIndex(currentRow, 1).setText('SUBJECT AVERAGES');
      sheet.getRangeByIndex(currentRow, 1).cellStyle.bold = true;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.fontSize = 12;
      sheet.getRangeByIndex(currentRow, 1).cellStyle.fontColor = '#2E75B6';
      currentRow++;

      // Headers
      sheet.getRangeByIndex(currentRow, 1).setText('Subject');
      sheet.getRangeByIndex(currentRow, 2).setText('Average Grade');
      _applyHeaderStyle(sheet, currentRow, 1);
      _applyHeaderStyle(sheet, currentRow, 2);
      currentRow++;

      for (final subject in subjectColumns) {
        final avg = students
                .map((s) => s.subjects[subject] ?? 0.0)
                .reduce((a, b) => a + b) /
            students.length;
        sheet.getRangeByIndex(currentRow, 1).setText(subject);
        sheet.getRangeByIndex(currentRow, 2).setNumber(avg);
        currentRow++;
      }
    }

    // Auto-fit columns
    sheet.getRangeByIndex(1, 1, currentRow, 10).autoFitColumns();

    // Save workbook
    final bytes = workbook.saveAsStream();
    workbook.dispose();

    return Uint8List.fromList(bytes);
  }

  static void _applyHeaderStyle(xlsio.Worksheet sheet, int row, int col) {
    final cell = sheet.getRangeByIndex(row, col);
    cell.cellStyle.bold = true;
    cell.cellStyle.backColor = '#B4C6E7';
    cell.cellStyle.fontColor = '#1F4E79';
  }

  static String _formatDateTime(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}
