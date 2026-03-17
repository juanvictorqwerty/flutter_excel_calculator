import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel;
import '../models/student.dart';

class FileBrowserPage extends StatefulWidget {
  const FileBrowserPage({super.key});

  @override
  State<FileBrowserPage> createState() => _FileBrowserPageState();
}

class _FileBrowserPageState extends State<FileBrowserPage> {
  String? _selectedFileName;
  bool _isLoading = false;
  List<String> _sheetNames = [];
  bool _hasExamTable = false;
  List<Student> _students = [];
  List<String> _subjectColumns = [];
  String? _errorMessage;

  /// Get cell value as string
  String _getCellValueAsString(excel.Data? cell) {
    if (cell == null || cell.value == null) return '';
    return cell.value.toString();
  }

  /// Get cell value as double
  double? _getCellValueAsDouble(excel.Data? cell) {
    if (cell == null || cell.value == null) return null;
    return double.tryParse(cell.value.toString());
  }

  /// Calculate GPA based on average grade
  String _calculateGPA(double average) {
    if (average >= 0 && average < 35) return 'F';
    if (average >= 35 && average < 50) return 'D';
    if (average >= 50 && average < 60) return 'C';
    if (average >= 60 && average < 70) return 'C+';
    if (average >= 70 && average < 80) return 'B';
    if (average >= 80 && average <= 100) return 'A';
    return 'F';
  }

  /// Opens file picker to browse for Excel files
  Future<void> _pickExcelFile() async {
    setState(() {
      _isLoading = true;
      _sheetNames = [];
      _hasExamTable = false;
      _students = [];
      _subjectColumns = [];
      _errorMessage = null;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
        withData: true,
      );

      if (result != null) {
        final fileName = result.files.single.name;
        final bytes = result.files.single.bytes;

        // On web, filePath is always null for security reasons
        // We can only rely on bytes
        if (bytes != null) {
          setState(() {
            _selectedFileName = fileName;
          });
          _processExcelFile(bytes);
        } else {
          _showErrorDialog('Could not read file data');
        }
      }
    } catch (e) {
      _showErrorDialog('Error picking file: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Process Excel file and look for any sheet with a "Name" column
  void _processExcelFile(Uint8List bytes) {
    try {
      final spreadsheet = excel.Excel.decodeBytes(bytes);
      _sheetNames = spreadsheet.tables.keys.toList();

      // Search all sheets for one with a "Name" column
      String? targetSheetName;
      int? nameColumnIndex;
      List<String>? headers;

      for (final sheetName in _sheetNames) {
        final sheet = spreadsheet.tables[sheetName];
        if (sheet == null || sheet.rows.isEmpty) continue;

        // Check first row for "Name" column
        final firstRow = sheet.rows[0];
        for (int i = 0; i < firstRow.length; i++) {
          final header = _getCellValueAsString(firstRow[i]).trim().toLowerCase();
          if (header == 'name' || header == 'student' || header == 'student name') {
            targetSheetName = sheetName;
            nameColumnIndex = i;
            headers = firstRow.map((cell) => _getCellValueAsString(cell).trim()).toList();
            break;
          }
        }
        if (targetSheetName != null) break;
      }

      if (targetSheetName == null || nameColumnIndex == null || headers == null) {
        setState(() {
          _errorMessage = 'No sheet with a "Name" column found.\nAvailable sheets: ${_sheetNames.join(", ")}\n\nNote: One column should be named "Name", "Student", or "Student Name"';
        });
        return;
      }

      setState(() {
        _hasExamTable = true;
      });
      _parseSheet(spreadsheet, targetSheetName, nameColumnIndex, headers);
    } catch (e) {
      _showErrorDialog('Error reading Excel file: $e');
    }
  }

  /// Parse sheet to extract student data - all columns except Name are subjects
  void _parseSheet(excel.Excel spreadsheet, String sheetName, int nameColumnIndex, List<String> headers) {
    final sheet = spreadsheet.tables[sheetName];
    if (sheet == null || sheet.rows.isEmpty) {
      setState(() {
        _errorMessage = 'Sheet is empty';
      });
      return;
    }

    final rows = sheet.rows;
    if (rows.length < 2) {
      setState(() {
        _errorMessage = 'Sheet needs at least 2 rows: headers and one data row';
      });
      return;
    }

    // All columns except Name are subjects
    List<int> subjectColumnIndices = [];
    for (int i = 0; i < headers.length; i++) {
      if (i != nameColumnIndex && headers[i].isNotEmpty) {
        subjectColumnIndices.add(i);
      }
    }

    if (subjectColumnIndices.isEmpty) {
      setState(() {
        _errorMessage = 'No subject columns found. Please add at least one subject column.';
      });
      return;
    }

    // Store subject column names
    final subjects = subjectColumnIndices.map((i) => headers[i]).toList();

    // Parse student data (start from row 1, after headers)
    List<Student> students = [];
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      final name = _getCellValueAsString(row[nameColumnIndex]);

      if (name.isEmpty) continue;

      Map<String, double> subjectGrades = {};
      List<double> grades = [];

      // Get grades from ALL subject columns
      for (int colIndex in subjectColumnIndices) {
        final subjectName = headers[colIndex];
        final grade = _getCellValueAsDouble(row[colIndex]);

        if (grade != null) {
          subjectGrades[subjectName] = grade;
          grades.add(grade);
        }
      }

      // Calculate average from all subjects
      double average = grades.isNotEmpty ? grades.reduce((a, b) => a + b) / grades.length : 0;

      // Calculate GPA
      String gpa = _calculateGPA(average);

      students.add(Student(
        name: name,
        subjects: subjectGrades,
        average: average,
        gpa: gpa,
      ));
    }

    setState(() {
      _students = students;
      _subjectColumns = subjects;
    });
  }

  /// Navigate to results page
  void _viewResults() {
    if (_students.isEmpty) return;
    
    Navigator.pushNamed(
      context,
      '/results',
      arguments: {
        'students': _students,
        'subjectColumns': _subjectColumns,
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Browse Excel File'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Browse Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickExcelFile,
              icon: _isLoading 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.folder_open),
              label: Text(_isLoading ? 'Loading...' : 'Browse for Excel File'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 24),
            
            // Selected File Info
            if (_selectedFileName != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected File:',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedFileName!,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_sheetNames.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Sheets: ${_sheetNames.join(", ")}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Error Message
            if (_errorMessage != null) ...[
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red.shade700),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Exam Table Found
            if (_hasExamTable && _students.isNotEmpty) ...[
              Card(
                color: Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Student data found!',
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Students found: ${_students.length}'),
                      Text('Subjects: ${_subjectColumns.join(", ")}'),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _viewResults,
                        icon: const Icon(Icons.visibility),
                        label: const Text('View GPA Results'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            
            // Empty State
            if (!_hasExamTable && _errorMessage == null && _selectedFileName == null && !_isLoading)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.table_chart_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Excel file selected',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap "Browse for Excel File" to select a file',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Expected format:\n• Row 1: Headers with a "Name" column\n• Row 2+: Student data\n• All other columns are treated as subjects',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
