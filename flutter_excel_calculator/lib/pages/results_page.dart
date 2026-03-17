import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/student.dart';
import '../services/excel_export_service.dart';
import '../services/pdf_export_service.dart';
import '../services/xml_export_service.dart';
import '../services/docx_export_service.dart';

/// Enum representing export formats
enum ExportFormat {
  excel('Excel', 'xlsx', Icons.table_chart, Colors.green),
  pdf('PDF', 'pdf', Icons.picture_as_pdf, Colors.red),
  word('Word', 'doc', Icons.description, Colors.blue),
  xml('XML', 'xml', Icons.code, Colors.orange);

  final String label;
  final String extension;
  final IconData icon;
  final Color color;

  const ExportFormat(this.label, this.extension, this.icon, this.color);
}

class ResultsPage extends StatefulWidget {
  final List<Student> students;
  final List<String> subjectColumns;

  const ResultsPage({
    super.key,
    required this.students,
    required this.subjectColumns,
  });

  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  bool _isExporting = false;

  Color _getGPAColor(String gpa) {
    switch (gpa) {
      case 'A':
        return Colors.green.shade700;
      case 'B':
        return Colors.blue.shade700;
      case 'C+':
        return Colors.teal.shade700;
      case 'C':
        return Colors.orange.shade700;
      case 'D':
        return Colors.deepOrange.shade700;
      case 'F':
        return Colors.red.shade700;
      default:
        return Colors.grey;
    }
  }

  /// Show format selection bottom sheet
  Future<void> _showExportOptions(BuildContext context) async {
    final result = await showModalBottomSheet<ExportFormat>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ExportFormatSheet(
        onFormatSelected: (format) => Navigator.pop(context, format),
      ),
    );

    if (result != null && context.mounted) {
      await _exportResults(context, result);
    }
  }

  /// Export results in the selected format
  Future<void> _exportResults(BuildContext context, ExportFormat format) async {
    setState(() => _isExporting = true);

    try {
      final classAverage = widget.students.map((s) => s.average).reduce((a, b) => a + b) /
          widget.students.length;

      // Generate file content based on format
      final bytes = await _generateExportBytes(format, classAverage);

      // Check if we're on web platform
      if (kIsWeb) {
        // On web, use FilePicker to save (triggers browser download)
        await _saveFileWeb(bytes, format);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${format.label} file downloaded successfully')),
          );
        }
      } else {
        // On mobile/desktop, use file system
        // Get save location
        String? outputPath = await _getSavePath(format);

        if (outputPath != null) {
          // Ensure unique filename
          outputPath = await _ensureUniqueFilename(outputPath);

          // Write file
          final file = File(outputPath);
          await file.writeAsBytes(bytes);

          if (context.mounted) {
            // Show success dialog with options
            await _showExportSuccessDialog(context, outputPath, format);
          }
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Export cancelled')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorDialog(context, 'Error exporting file: $e');
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  /// Save file on web platform using FilePicker
  Future<void> _saveFileWeb(List<int> bytes, ExportFormat format) async {
    final timestamp = _formatTimestamp(DateTime.now());
    final fileName = 'GPA_Results_$timestamp.${format.extension}';

    // Convert List<int> to Uint8List
    final uint8List = bytes is Uint8List ? bytes : Uint8List.fromList(bytes);

    await FilePicker.platform.saveFile(
      dialogTitle: 'Save GPA Results as ${format.label}',
      fileName: fileName,
      allowedExtensions: [format.extension],
      type: FileType.custom,
      bytes: uint8List,
    );
  }

  /// Generate export bytes based on format
  Future<List<int>> _generateExportBytes(ExportFormat format, double classAverage) async {
    switch (format) {
      case ExportFormat.excel:
        return await ExcelExportService.generateExcel(
          students: widget.students,
          subjectColumns: widget.subjectColumns,
          classAverage: classAverage,
        );
      case ExportFormat.pdf:
        return await PdfExportService.generatePdf(
          students: widget.students,
          subjectColumns: widget.subjectColumns,
          classAverage: classAverage,
        );
      case ExportFormat.word:
        return await DocxExportService.generateDocx(
          students: widget.students,
          subjectColumns: widget.subjectColumns,
          classAverage: classAverage,
        );
      case ExportFormat.xml:
        return await XmlExportService.generateXml(
          students: widget.students,
          subjectColumns: widget.subjectColumns,
          classAverage: classAverage,
        );
    }
  }

  /// Get save path from user
  Future<String?> _getSavePath(ExportFormat format) async {
    final timestamp = _formatTimestamp(DateTime.now());
    final defaultFileName = 'GPA_Results_$timestamp.${format.extension}';

    // Use FilePicker for all platforms including web
    return await FilePicker.platform.saveFile(
      dialogTitle: 'Save GPA Results as ${format.label}',
      fileName: defaultFileName,
      allowedExtensions: [format.extension],
      type: FileType.custom,
    );
  }

  /// Ensure filename is unique by adding timestamp if needed
  Future<String> _ensureUniqueFilename(String outputPath) async {
    final file = File(outputPath);
    if (await file.exists()) {
      final dir = file.parent.path;
      final ext = path.extension(outputPath);
      final nameWithoutExt = path.basenameWithoutExtension(outputPath);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      return '$dir/${nameWithoutExt}_$timestamp$ext';
    }
    return outputPath;
  }

  /// Show export success dialog with share option
  Future<void> _showExportSuccessDialog(
    BuildContext context,
    String filePath,
    ExportFormat format,
  ) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(format.icon, color: format.color, size: 48),
        title: Text('${format.label} Export Complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('File saved successfully:'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                filePath,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _shareFile(filePath);
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  /// Share the exported file
  Future<void> _shareFile(String filePath) async {
    try {
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'GPA Results',
        text: 'Here are the GPA results exported from Excel Calculator App.',
      );
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, 'Error sharing file: $e');
      }
    }
  }

  /// Show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
        title: const Text('Export Error'),
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

  String _formatTimestamp(DateTime date) {
    return '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}_'
        '${date.hour.toString().padLeft(2, '0')}${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final classAverage =
        widget.students.map((s) => s.average).reduce((a, b) => a + b) / widget.students.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GPA Results'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _isExporting ? null : () => _showExportOptions(context),
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            tooltip: 'Export Results',
          ),
        ],
      ),
      body: Column(
        children: [
          // Collapsible Top Section (Summary + GPA Scale)
          Card(
            margin: const EdgeInsets.all(16),
            child: ExpansionTile(
              title: Row(
                children: [
                  const Icon(Icons.analytics),
                  const SizedBox(width: 8),
                  Text('Summary (${widget.students.length} students)'),
                ],
              ),
              children: [
                // Summary Stats
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStat('Total Students', widget.students.length.toString()),
                      _buildStat('Class Average', classAverage.toStringAsFixed(2)),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // GPA Scale
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'GPA Scale:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildLegend('A (80-100)', Colors.green.shade700),
                          _buildLegend('B (70-80)', Colors.blue.shade700),
                          _buildLegend('C+ (60-70)', Colors.teal.shade700),
                          _buildLegend('C (50-60)', Colors.orange.shade700),
                          _buildLegend('D (35-50)', Colors.deepOrange.shade700),
                          _buildLegend('F (0-35)', Colors.red.shade700),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Students List
          Expanded(
            child: ListView.builder(
              itemCount: widget.students.length,
              itemBuilder: (context, index) {
                final student = widget.students[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            student.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getGPAColor(student.gpa),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            student.gpa,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text('Average: ${student.average.toStringAsFixed(2)}'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Subject Grades:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            ...student.subjects.entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(entry.key),
                                    Text(
                                      entry.value.toStringAsFixed(2),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Export Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _isExporting ? null : () => _showExportOptions(context),
              icon: _isExporting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_isExporting ? 'Exporting...' : 'Export Results'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        radius: 8,
      ),
      label: Text(label, style: const TextStyle(fontSize: 10)),
      backgroundColor: Colors.grey.shade100,
    );
  }
}

/// Widget for displaying export format options
class _ExportFormatSheet extends StatelessWidget {
  final void Function(ExportFormat) onFormatSelected;

  const _ExportFormatSheet({required this.onFormatSelected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'Export Format',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the format for your GPA results export',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 20),

            // Format options
            ...ExportFormat.values.map((format) => _buildFormatTile(context, format)),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFormatTile(BuildContext context, ExportFormat format) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        onTap: () => onFormatSelected(format),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: format.color.withAlpha(25),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(format.icon, color: format.color),
        ),
        title: Text(
          format.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('.${format.extension} file'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
