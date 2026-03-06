import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/student.dart';

/// Service for exporting student GPA results to PDF format
class PdfExportService {
  /// Generate a PDF document with student results
  static Future<Uint8List> generatePdf({
    required List<Student> students,
    required List<String> subjectColumns,
    required double classAverage,
  }) async {
    final pdf = pw.Document();

    // Define color helpers
    PdfColor getGPAColor(String gpa) {
      switch (gpa) {
        case 'A':
          return PdfColors.green700;
        case 'B':
          return PdfColors.blue700;
        case 'C+':
          return PdfColors.teal;
        case 'C':
          return PdfColors.orange;
        case 'D':
          return PdfColors.deepOrange;
        case 'F':
          return PdfColors.red;
        default:
          return PdfColors.grey;
      }
    }

    // Build the PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'GPA Results Report',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.Text(
                    'Generated: ${_formatDate(DateTime.now())}',
                    style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 8),
            ],
          );
        },
        footer: (context) {
          return pw.Column(
            children: [
              pw.Divider(thickness: 0.5),
              pw.SizedBox(height: 4),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'Page ${context.pageNumber} of ${context.pagesCount}',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                  pw.Text(
                    'Excel Calculator App',
                    style: pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                  ),
                ],
              ),
            ],
          );
        },
        build: (context) {
          return [
            // Summary Section
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSummaryBox('Total Students', students.length.toString()),
                  _buildSummaryBox('Class Average', classAverage.toStringAsFixed(2)),
                  _buildSummaryBox(
                    'Report Date',
                    _formatDate(DateTime.now()),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),

            // GPA Scale Legend
            pw.Text(
              'GPA Scale',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildLegend('A (80-100)', PdfColors.green700),
                _buildLegend('B (70-79)', PdfColors.blue700),
                _buildLegend('C+ (60-69)', PdfColors.teal),
                _buildLegend('C (50-59)', PdfColors.orange),
                _buildLegend('D (35-49)', PdfColors.deepOrange),
                _buildLegend('F (0-34)', PdfColors.red),
              ],
            ),
            pw.SizedBox(height: 20),

            // Results Table
            pw.Text(
              'Student Results',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),

            // Main results table
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(2),
                2: const pw.FlexColumnWidth(2),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue100,
                  ),
                  children: [
                    _buildTableHeader('Student Name'),
                    _buildTableHeader('Average'),
                    _buildTableHeader('GPA'),
                  ],
                ),
                // Data rows
                ...students.map((student) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(student.name),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          student.average.toStringAsFixed(2),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Center(
                          child: pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: pw.BoxDecoration(
                              color: getGPAColor(student.gpa),
                              borderRadius: pw.BorderRadius.circular(12),
                            ),
                            child: pw.Text(
                              student.gpa,
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontWeight: pw.FontWeight.bold,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 20),

            // Detailed Subject Grades
            pw.Text(
              'Detailed Subject Grades',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),

            // Detailed table with all subjects
            pw.Table(
              border: pw.TableBorder.all(
                color: PdfColors.grey400,
                width: 0.5,
              ),
              columnWidths: {
                0: const pw.FlexColumnWidth(2),
                ...subjectColumns.asMap().map(
                  (index, _) => MapEntry(
                    index + 1,
                    const pw.FlexColumnWidth(1.5),
                  ),
                ),
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  children: [
                    _buildTableHeader('Name'),
                    ...subjectColumns.map((subject) => _buildTableHeader(subject)),
                    _buildTableHeader('Avg'),
                    _buildTableHeader('GPA'),
                  ],
                ),
                // Data rows
                ...students.map((student) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          student.name,
                          style: pw.TextStyle(fontSize: 9),
                        ),
                      ),
                      ...subjectColumns.map((subject) {
                        final grade = student.subjects[subject] ?? 0.0;
                        return pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            grade.toStringAsFixed(1),
                            style: pw.TextStyle(fontSize: 9),
                            textAlign: pw.TextAlign.center,
                          ),
                        );
                      }),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(
                          student.average.toStringAsFixed(2),
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                          ),
                          textAlign: pw.TextAlign.center,
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Center(
                          child: pw.Text(
                            student.gpa,
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: getGPAColor(student.gpa),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 20),

            // Statistics Section
            pw.Text(
              'Statistics Summary',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 8),
            _buildStatisticsTable(students),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryBox(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildLegend(String label, PdfColor color) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Container(
          width: 12,
          height: 12,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 4),
        pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
      ],
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.blue900,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildStatisticsTable(List<Student> students) {
    // Calculate statistics
    final gpaCounts = <String, int>{};
    for (final student in students) {
      gpaCounts[student.gpa] = (gpaCounts[student.gpa] ?? 0) + 1;
    }

    final sortedGPAs = ['A', 'B', 'C+', 'C', 'D', 'F'];
    final gpaColors = {
      'A': PdfColors.green700,
      'B': PdfColors.blue700,
      'C+': PdfColors.teal,
      'C': PdfColors.orange,
      'D': PdfColors.deepOrange,
      'F': PdfColors.red,
    };

    return pw.Table(
      border: pw.TableBorder.all(
        color: PdfColors.grey400,
        width: 0.5,
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
          ),
          children: [
            _buildTableHeader('GPA Grade'),
            _buildTableHeader('Count'),
            _buildTableHeader('Percentage'),
          ],
        ),
        ...sortedGPAs.map((gpa) {
          final count = gpaCounts[gpa] ?? 0;
          final percentage = students.isNotEmpty
              ? (count / students.length * 100).toStringAsFixed(1)
              : '0.0';
          return pw.TableRow(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Row(
                  children: [
                    pw.Container(
                      width: 16,
                      height: 16,
                      decoration: pw.BoxDecoration(
                        color: gpaColors[gpa] ?? PdfColors.grey,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(gpa),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  count.toString(),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '$percentage%',
                  textAlign: pw.TextAlign.center,
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
