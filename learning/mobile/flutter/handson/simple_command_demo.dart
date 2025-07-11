// Simple Command Pattern Demo
import 'package:flutter/material.dart';

// ============================================================================
// SIMPLE COMMAND IMPLEMENTATION
// ============================================================================

// Base Command class
abstract class Command<T> extends ChangeNotifier {
  bool _running = false;
  String? _errorMessage;
  T? _result;

  // Getters for current state
  bool get running => _running;
  bool get hasError => _errorMessage != null;
  String? get errorMessage => _errorMessage;
  T? get result => _result;

  // Clear previous results
  void clearResult() {
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }

  // Execute the command
  Future<void> execute() async {
    if (_running) return; // Prevent multiple executions

    _running = true;
    _errorMessage = null;
    _result = null;
    notifyListeners();

    try {
      _result = await performAction();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _running = false;
      notifyListeners();
    }
  }

  // Override this method in subclasses
  Future<T> performAction();
}

// ============================================================================
// EXAMPLE COMMANDS
// ============================================================================

// Command to fetch data from API
class FetchDataCommand extends Command<List<String>> {
  @override
  Future<List<String>> performAction() async {
    // Simulate API call
    await Future.delayed(Duration(seconds: 2));
    
    // Random error simulation (20% chance)
    if (DateTime.now().millisecondsSinceEpoch % 5 == 0) {
      throw Exception('Network error: Failed to fetch data');
    }

    // Return mock data
    return [
      'Item 1: Flutter is awesome',
      'Item 2: Command Pattern rocks',
      'Item 3: Clean Architecture',
      'Item 4: State Management',
      'Item 5: Design Patterns',
    ];
  }
}

// Command to save data
class SaveDataCommand extends Command<String> {
  final String data;

  SaveDataCommand(this.data);

  @override
  Future<String> performAction() async {
    // Simulate save operation
    await Future.delayed(Duration(seconds: 1));

    // Validate data
    if (data.isEmpty) {
      throw Exception('Validation error: Data cannot be empty');
    }

    // Return success message
    return 'Data saved successfully: $data';
  }
}

// ============================================================================
// DEMO SCREEN
// ============================================================================

class SimpleCommandDemo extends StatefulWidget {
  @override
  _SimpleCommandDemoState createState() => _SimpleCommandDemoState();
}

class _SimpleCommandDemoState extends State<SimpleCommandDemo> {
  final FetchDataCommand _fetchCommand = FetchDataCommand();
  final TextEditingController _textController = TextEditingController();
  SaveDataCommand? _saveCommand;

  @override
  void initState() {
    super.initState();
    
    // Listen to command state changes
    _fetchCommand.addListener(_onFetchCommandChanged);
  }

  @override
  void dispose() {
    _fetchCommand.removeListener(_onFetchCommandChanged);
    _fetchCommand.dispose();
    _saveCommand?.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _onFetchCommandChanged() {
    // Show snackbar when command completes
    if (_fetchCommand.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_fetchCommand.errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
    } else if (_fetchCommand.result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Data fetched successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _executeSaveCommand() {
    // Create new save command with current text
    _saveCommand?.dispose();
    _saveCommand = SaveDataCommand(_textController.text);
    
    // Listen to save command
    _saveCommand!.addListener(() {
      if (_saveCommand!.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_saveCommand!.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      } else if (_saveCommand!.result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_saveCommand!.result!),
            backgroundColor: Colors.green,
          ),
        );
        _textController.clear();
      }
    });

    // Execute the command
    _saveCommand!.execute();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simple Command Demo'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fetch Data Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Fetch Data Command',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    
                    // Command Status
                    ListenableBuilder(
                      listenable: _fetchCommand,
                      builder: (context, child) {
                        if (_fetchCommand.running) {
                          return Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 8),
                              Text('Loading data...'),
                            ],
                          );
                        }
                        
                        if (_fetchCommand.hasError) {
                          return Column(
                            children: [
                              Icon(Icons.error, color: Colors.red, size: 48),
                              SizedBox(height: 8),
                              Text(
                                'Error: ${_fetchCommand.errorMessage}',
                                style: TextStyle(color: Colors.red),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          );
                        }
                        
                        if (_fetchCommand.result != null) {
                          return Column(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green, size: 48),
                              SizedBox(height: 8),
                              Text('Data loaded successfully!'),
                              SizedBox(height: 16),
                              // Display fetched data
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: _fetchCommand.result!
                                      .map((item) => Padding(
                                            padding: EdgeInsets.only(bottom: 4),
                                            child: Text(item),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ],
                          );
                        }
                        
                        return Text('Press button to fetch data');
                      },
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Fetch Button
                    ElevatedButton(
                      onPressed: () => _fetchCommand.execute(),
                      child: Text('Fetch Data'),
                    ),
                    
                    // Clear Button
                    if (_fetchCommand.result != null || _fetchCommand.hasError)
                      TextButton(
                        onPressed: () => _fetchCommand.clearResult(),
                        child: Text('Clear'),
                      ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Save Data Section
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Save Data Command',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    SizedBox(height: 16),
                    
                    // Input Field
                    TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        labelText: 'Enter data to save',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // Save Command Status
                    if (_saveCommand != null)
                      ListenableBuilder(
                        listenable: _saveCommand!,
                        builder: (context, child) {
                          if (_saveCommand!.running) {
                            return Column(
                              children: [
                                LinearProgressIndicator(),
                                SizedBox(height: 8),
                                Text('Saving data...'),
                              ],
                            );
                          }
                          return SizedBox.shrink();
                        },
                      ),
                    
                    // Save Button
                    ElevatedButton(
                      onPressed: _saveCommand?.running == true 
                          ? null 
                          : _executeSaveCommand,
                      child: Text('Save Data'),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 20),
            
            // Info Section
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Command Pattern Benefits:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('✅ Automatic state management (loading, error, success)'),
                    Text('✅ Prevents duplicate executions'),
                    Text('✅ Separates UI from business logic'),
                    Text('✅ Easy to test and maintain'),
                    Text('✅ Consistent error handling'),
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

// ============================================================================
// MAIN APP
// ============================================================================

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Command Pattern Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: SimpleCommandDemo(),
    );
  }
} 