import 'package:flutter/material.dart';
import 'models/student.dart';
import 'pages/file_browser_page.dart';
import 'pages/results_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Excel Calculator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 0, 111, 175)),
      ),
      home: const HomePage(),
      onGenerateRoute: (settings) {
        if (settings.name == '/results') {
          final args = settings.arguments as Map<String, dynamic>;
          return MaterialPageRoute(
            builder: (context) => ResultsPage(
              students: args['students'] as List<Student>,
              subjectColumns: args['subjectColumns'] as List<String>,
            ),
          );
        }
        return null;
      },
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Excel Calculator'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Browse Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FileBrowserPage(),
                  ),
                );
              },
              icon: const Icon(Icons.folder_open),
              label: const Text('Browse for Excel File'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            
            // Instructions Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How to use:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                      const Text('1. Create an Excel file with student data'),
                    const SizedBox(height: 4),
                    const Text('2. Format your table like this:'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Row 1 (A1): Exam', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Row 2: Name | Math | Physics | Chemistry', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text('Row 3: John | 85   | 78      | 92'),
                          Text('Row 4: Jane | 65   | 70      | 68'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('3. The app will calculate GPA for each student'),
                    const SizedBox(height: 4),
                    const Text('4. Save the results as a new Excel file'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // GPA Scale Info
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GPA Scale:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    _buildGPAScaleRow('A', '80-100', Colors.green),
                    _buildGPAScaleRow('B', '70-80', Colors.blue),
                    _buildGPAScaleRow('C+', '60-70', Colors.teal),
                    _buildGPAScaleRow('C', '50-60', Colors.orange),
                    _buildGPAScaleRow('D', '35-50', Colors.deepOrange),
                    _buildGPAScaleRow('F', '0-35', Colors.red),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGPAScaleRow(String grade, String range, MaterialColor color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 30,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              grade,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Text(range),
        ],
      ),
    );
  }
}
