// Exercise 2: Logger Using Delegation
// Dart has no 'by' keyword like Kotlin — delegation is done via composition.

// Step 1: Abstract class acts as an interface
abstract class Logger {
  void log(String message);
}

// Step 2a: ConsoleLogger — prints to console
class ConsoleLogger implements Logger {
  @override
  void log(String message) => print(message);
}

// Step 2b: FileLogger — simulates writing to a file
class FileLogger implements Logger {
  @override
  void log(String message) => print('File: $message');
}

// Step 3: Application delegates all logging to the injected Logger
class Application {
  final Logger _logger; // private — delegation is explicit

  const Application(this._logger);

  // Forward the call to the delegate
  void log(String message) => _logger.log(message);

  void run() {
    log('App started');
    log('Processing...');
    log('App finished');
  }
}

void main() {
  print('--- ConsoleLogger ---');
  Application(ConsoleLogger()).run();
  // App started
  // Processing...
  // App finished

  print('--- FileLogger ---');
  Application(FileLogger()).run();
  // File: App started
  // File: Processing...
  // File: App finished
}
