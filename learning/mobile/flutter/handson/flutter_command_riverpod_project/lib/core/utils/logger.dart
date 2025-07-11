import 'package:logger/logger.dart';

class AppLogger {
  static Logger? _logger;
  
  static Logger get logger => _logger ?? Logger();
  
  static void init() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    );
  }
} 