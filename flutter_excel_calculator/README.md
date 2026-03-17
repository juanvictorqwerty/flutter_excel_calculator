# Excel Calculator

A Flutter application for calculating student GPA from Excel files. Import student exam data, automatically calculate averages and grades, and export results to various formats.

## Features

- **Excel File Import** - Browse and select `.xlsx` or `.xls` files containing student data
- **Automatic GPA Calculation** - Calculates average scores and assigns letter grades based on a standard scale
- **Multiple Export Formats** - Export results as Excel, PDF, DOCX, or XML files
- **Multi-platform Support** - Runs on Android, iOS, macOS, Linux, and Windows
- **Web Support** - Can be built and deployed as a web application

## GPA Scale

| Grade | Score Range |
|-------|-------------|
| A | 80-100 |
| B | 70-80 |
| C+ | 60-70 |
| C | 50-60 |
| D | 35-50 |
| F | 0-35 |

## Excel File Format

Your Excel file should be formatted as follows:

```
Row 1 (A1): Exam
Row 2: Name | Math | Physics | Chemistry
Row 3: John | 85   | 78      | 92
Row 4: Jane | 65   | 70      | 68
```

- **Row 1**: Header row (title cell in A1)
- **Row 2**: Column headers (Name + subjects)
- **Row 3+**: Student data rows

## Prerequisites

- Flutter SDK 3.11.0 or higher
- Dart SDK 3.11.0 or higher

## Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd flutter_excel_calculator
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

## Building for Web

To build the web application:

```bash
flutter build web
```

The built files will be in `build/web/`. Serve them using a web server:

```bash
cd build/web
python3 -m http.server 8000
```

Then open `http://localhost:8000` in your browser.

## Building for Android

```bash
flutter build apk --debug
```

APK will be at `build/app/outputs/flutter-apk/app-debug.apk`

## Building for iOS

```bash
flutter build ios --simulator --no-codesign
```

## Project Structure

```
lib/
├── main.dart                    # App entry point and home page
├── models/
│   └── student.dart             # Student data model
├── pages/
│   ├── file_browser_page.dart   # Excel file selection and processing
│   └── results_page.dart        # Display calculated results
└── services/
    ├── docx_export_service.dart # DOCX export functionality
    ├── excel_export_service.dart# Excel export functionality
    ├── pdf_export_service.dart # PDF export functionality
    └── xml_export_service.dart # XML export functionality
```

## Dependencies

- `file_picker` - File selection dialog
- `excel` - Excel file parsing
- `syncfusion_flutter_xlsio` - Excel file generation
- `pdf` - PDF document creation
- `path_provider` - File system paths
- `share_plus` - Share files to other apps
- `xml` - XML file generation
- `open_filex` - Open files with system apps

## Usage

1. Launch the application
2. Tap "Browse for Excel File" button
3. Select an Excel file (.xlsx or .xls) with student data
4. View the calculated results with GPA for each student
5. Export results using the export buttons (Excel, PDF, DOCX, XML)

## License

This project is licensed under the MIT License.
