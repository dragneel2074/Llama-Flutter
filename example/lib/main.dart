import 'package:flutter/material.dart';
import 'package:chat_app/services/chat_service.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';

// UI Message model for display
class UIChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  UIChatMessage({
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Local Chat App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const ChatScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<UIChatMessage> _messages = [];
  String _currentAIResponse = '';
  bool _isLoading = false;
  double _downloadProgress = 0.0;
  String _statusMessage = 'Initializing...';
  bool _isModelLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    debugPrint('[UI] ===== Initializing app =====');
    
    setState(() {
      _statusMessage = 'Checking for existing model...';
    });

    debugPrint('[UI] Calling chatService.initialize()...');
    final modelExists = await _chatService.initialize();
    debugPrint('[UI] Initialize result: modelExists = $modelExists');

    if (modelExists) {
      debugPrint('[UI] Model exists, ready to load');
      setState(() {
        _statusMessage = 'Model found. Ready to load.';
      });
      _loadModel();
    } else {
      debugPrint('[UI] No valid model found');
      setState(() {
        _statusMessage = 'No valid model found. Tap "Load from Local" to select your downloaded model file.';
      });
    }

    // Listen to message stream
    debugPrint('[UI] Setting up message stream listener');
    _chatService.messageStream.listen((token) {
      setState(() {
        if (token.startsWith('User:')) {
          // Extract user message
          final userMsg = token.replaceFirst('User:', '').replaceFirst('\nAI:', '').trim();
          _messages.add(UIChatMessage(text: userMsg, isUser: true));
          // Start a new AI response
          _currentAIResponse = '';
          _messages.add(UIChatMessage(text: '', isUser: false));
        } else if (token.startsWith('\nError:') || token.startsWith('Error:')) {
          // Error message
          if (_messages.isNotEmpty && !_messages.last.isUser) {
            _messages.removeLast();
          }
          _messages.add(UIChatMessage(text: token.trim(), isUser: false));
          _currentAIResponse = '';
        } else if (token == '\n') {
          // End of AI response
          _currentAIResponse = '';
        } else {
          // Accumulate AI response tokens
          _currentAIResponse += token;
          if (_messages.isNotEmpty && !_messages.last.isUser) {
            _messages.last = UIChatMessage(text: _currentAIResponse, isUser: false);
          }
        }
      });
      _scrollToBottom();
    });
    
    // Listen to generating state changes
    debugPrint('[UI] Setting up generating state listener');
    _chatService.generatingStateStream.listen((isGenerating) {
      debugPrint('[UI] Generation state changed: $isGenerating');
      setState(() {
        // Force UI rebuild when generation state changes
      });
    });
    
    // Listen to model unload events (for auto-unload)
    debugPrint('[UI] Setting up model unload listener');
    _chatService.modelUnloadStream.listen((_) {
      debugPrint('[UI] Model unload event received');
      setState(() {
        _isModelLoaded = false;
        _statusMessage = 'Model unloaded automatically due to inactivity.';
      });
    });
    
    debugPrint('[UI] ===== App initialization complete =====');
  }

  Future<void> _downloadModel() async {
    // Download functionality is disabled
    debugPrint('[UI] Download model triggered but is disabled');
    
    setState(() {
      _statusMessage = 'Download functionality is disabled. Use "Load from Local" to select your model file.';
    });
  }

  Future<void> _loadFromLocal() async {
    debugPrint('[UI] ===== Load from local triggered =====');
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Opening file picker...';
    });

    try {
      debugPrint('[UI] Calling chatService.pickLocalModel()...');
      final modelPath = await _chatService.pickLocalModel();
      debugPrint('[UI] pickLocalModel returned: $modelPath');
      
      if (modelPath != null) {
        final fileName = modelPath.split('/').last.split('\\').last;
        debugPrint('[UI] ✓ Model selected: $fileName');
        debugPrint('[UI] Full path: $modelPath');
        
        setState(() {
          _statusMessage = 'Model selected: $fileName';
        });
        
        // Automatically load the selected model
        debugPrint('[UI] Automatically loading the selected model...');
        await _loadModel();
      } else {
        debugPrint('[UI] ✗ No model file selected');
        setState(() {
          _statusMessage = 'No model file selected';
        });
      }
    } catch (e) {
      debugPrint('[UI] ✗✗✗ Error in _loadFromLocal: $e');
      debugPrint('[UI] Stack trace: ${StackTrace.current}');
      setState(() {
        _statusMessage = 'Error selecting model: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      debugPrint('[UI] ===== Load from local complete =====');
    }
  }

    Future<void> _loadModel() async {
    debugPrint('[UI] ===== Load model triggered =====');
    
    if (_chatService.isLoadingModel) {
      debugPrint('[UI] ⚠ Model is already loading, returning');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading model...';
    });
    
    debugPrint('[UI] Current model path: ${_chatService.modelPath}');

    try {
      debugPrint('[UI] Calling chatService.loadModel()...');
      await _chatService.loadModel(
        onProgress: (progress) {
          debugPrint('[UI] Progress callback: ${progress.toStringAsFixed(1)}%');
          setState(() {
            _downloadProgress = progress;
          });
        },
        onStatus: (status) {
          debugPrint('[UI] Status callback: $status');
          setState(() {
            _statusMessage = status;
          });
        },
      );

      debugPrint('[UI] loadModel completed, checking if model is loaded...');
      final isLoaded = await _chatService.isModelLoaded();
      debugPrint('[UI] isModelLoaded result: $isLoaded');
      
      setState(() {
        _isModelLoaded = isLoaded;
        _statusMessage = _isModelLoaded ? 'Model loaded successfully!' : 'Failed to load model';
      });
      
      if (_isModelLoaded) {
        debugPrint('[UI] ✓✓✓ Model loaded successfully! Ready for chat.');
      } else {
        debugPrint('[UI] ✗ Model failed to load');
      }
    } catch (e) {
      debugPrint('[UI] ✗✗✗ Error in _loadModel: $e');
      debugPrint('[UI] Stack trace: ${StackTrace.current}');
      setState(() {
        _statusMessage = 'Failed to load model: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      debugPrint('[UI] ===== Load model complete =====');
    }
  }

  Future<void> _unloadModel() async {
    debugPrint('[UI] ===== Unload model triggered =====');
    
    setState(() {
      _isLoading = true;
      _statusMessage = 'Unloading model...';
    });

    try {
      debugPrint('[UI] Calling chatService.unloadModel()...');
      await _chatService.unloadModel();
      
      setState(() {
        _isModelLoaded = false;
        _statusMessage = 'Model unloaded. You can load a new model.';
      });
      
      debugPrint('[UI] ✓ Model unloaded successfully');
    } catch (e) {
      debugPrint('[UI] ✗✗✗ Error unloading model: $e');
      setState(() {
        _statusMessage = 'Error unloading model: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
      debugPrint('[UI] ===== Unload model complete =====');
    }
  }

  void _showCustomTemplateEditor(BuildContext context, {String? existingName, String? existingContent}) async {
    final isEditing = existingName != null;
    final nameController = TextEditingController(text: existingName ?? '');
    final contentController = TextEditingController(text: existingContent ?? '');
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit_note, color: Colors.blue[700], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isEditing ? 'Edit Template' : 'Create Template',
                style: TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Template Name Section
              Text('Template Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                'A unique identifier for your template (e.g., "mistral-instruct", "my-llama")',
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: nameController,
                enabled: !isEditing, // Readonly when editing
                decoration: InputDecoration(
                  hintText: 'e.g., mistral-custom',
                  prefixIcon: Icon(Icons.label, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  filled: isEditing,
                  fillColor: isEditing ? Colors.grey[200] : null,
                ),
              ),
              const SizedBox(height: 16),
              
              // Template Content Section
              Text('Template Content', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              const SizedBox(height: 4),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.amber[900]),
                        const SizedBox(width: 6),
                        Text('Placeholders:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.amber[900])),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('• {system} - System message', style: TextStyle(fontSize: 11, color: Colors.grey[800])),
                    Text('• {user} - User input', style: TextStyle(fontSize: 11, color: Colors.grey[800])),
                    Text('• {assistant} - AI response', style: TextStyle(fontSize: 11, color: Colors.grey[800])),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, size: 16, color: Colors.green[900]),
                        const SizedBox(width: 6),
                        Text('Examples:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.green[900])),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildExampleTemplate('Mistral', '<s>[INST]{system}\\n\\n{user}[/INST]{assistant}</s>'),
                    _buildExampleTemplate('Llama 3', '<|begin_of_text|><|start_header_id|>system<|end_header_id|>\\n\\n{system}<|eot_id|><|start_header_id|>user<|end_header_id|>\\n\\n{user}<|eot_id|><|start_header_id|>assistant<|end_header_id|>\\n\\n{assistant}<|eot_id|>'),
                    _buildExampleTemplate('Simple', 'User: {user}\\nAssistant: {assistant}\\n'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentController,
                maxLines: 6,
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                decoration: InputDecoration(
                  hintText: 'Paste or type your template here...\n\nExample:\n<s>[INST]{user}[/INST]{assistant}</s>',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.all(12),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final name = nameController.text.trim();
              final content = contentController.text.trim();
              
              if (name.isNotEmpty && content.isNotEmpty) {
                // If editing, remove old one first if name changed (though we disabled name editing)
                if (isEditing && existingName != name) {
                  await _chatService.removeCustomTemplate(existingName);
                }
                
                await _chatService.addCustomTemplate(name, content);
                
                if (context.mounted) {
                  Navigator.pop(context); // Close editor
                  _showSettingsDialog(); // Reopen settings to show updated list
                  
                  // Show success message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing 
                        ? 'Template "$name" updated' 
                        : 'Template "$name" created'
                      ),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              } else {
                // Show error message
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please provide both name and content'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ],
      ),
    );
  }
  
  // Helper widget to show example templates
  Widget _buildExampleTemplate(String name, String template) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(fontSize: 11, color: Colors.grey[700])),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 11, color: Colors.grey[800]),
                children: [
                  TextSpan(
                    text: '$name: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(
                    text: template.length > 60 ? '${template.substring(0, 60)}...' : template,
                    style: TextStyle(fontFamily: 'monospace'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _showSettingsDialog() {
    // Get current settings
    final config = _chatService.generationConfig;
    final contextSize = _chatService.contextSize;
    final chatTemplate = _chatService.chatTemplate;
    final autoUnloadModel = _chatService.autoUnloadModel;
    final autoUnloadTimeout = _chatService.autoUnloadTimeout;
    final systemMessage = _chatService.settingsService.systemMessage; // Access from chat service
    
    // Controllers for text fields
    final maxTokensController = TextEditingController(text: config.maxTokens.toString());
    final temperatureController = TextEditingController(text: config.temperature.toString());
    final topPController = TextEditingController(text: config.topP.toString());
    final topKController = TextEditingController(text: config.topK.toString());
    final repeatPenaltyController = TextEditingController(text: config.repeatPenalty.toString());
    final contextSizeController = TextEditingController(text: contextSize.toString());
    final autoUnloadTimeoutController = TextEditingController(text: autoUnloadTimeout.toString());
    final systemMessageController = TextEditingController(text: systemMessage);
    
    // Template selection
    String selectedTemplate = chatTemplate;
    bool autoUnloadEnabled = autoUnloadModel;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Settings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Generation Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildSettingField('Max Tokens', maxTokensController, 'e.g., 150, 512'),
              const SizedBox(height: 12),
              _buildSettingField('Temperature', temperatureController, '0.0-2.0 (0.7 default)'),
              const SizedBox(height: 12),
              _buildSettingField('Top-P', topPController, '0.0-1.0 (0.9 default)'),
              const SizedBox(height: 12),
              _buildSettingField('Top-K', topKController, 'e.g., 40'),
              const SizedBox(height: 12),
              _buildSettingField('Repeat Penalty', repeatPenaltyController, '1.0-2.0 (1.1 default)'),
              const SizedBox(height: 16),
              const Text('Model Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildSettingField('Context Size (tokens)', contextSizeController, '128-8192 (default: 2048)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text('Chat Template', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: selectedTemplate,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    isDense: true,
                  ),
                  items: [
                    // Built-in templates with user-friendly names
                    DropdownMenuItem(value: 'auto', child: Text('Auto-Detect')),
                    DropdownMenuItem(value: 'chatml', child: Text('ChatML (Qwen, OpenChat)')),
                    DropdownMenuItem(value: 'llama3', child: Text('Llama 3')),
                    DropdownMenuItem(value: 'llama2', child: Text('Llama 2')),
                    DropdownMenuItem(value: 'phi', child: Text('Phi-2/3')),
                    DropdownMenuItem(value: 'gemma', child: Text('Gemma (default)')),
                    DropdownMenuItem(value: 'gemma2', child: Text('Gemma 2')),
                    DropdownMenuItem(value: 'gemma3', child: Text('Gemma 3')),
                    DropdownMenuItem(value: 'alpaca', child: Text('Alpaca')),
                    DropdownMenuItem(value: 'vicuna', child: Text('Vicuna')),
                    DropdownMenuItem(value: 'mistral', child: Text('Mistral')),
                    DropdownMenuItem(value: 'mixtral', child: Text('Mixtral')),
                    DropdownMenuItem(value: 'qwq', child: Text('QwQ (Thinking Model)')),
                    DropdownMenuItem(value: 'deepseek-r1', child: Text('DeepSeek-R1')),
                    DropdownMenuItem(value: 'deepseek-v3', child: Text('DeepSeek-V3')),
                    DropdownMenuItem(value: 'deepseek-coder', child: Text('DeepSeek Coder')),
                    // Custom templates
                    ..._chatService.customTemplateNames.map((template) => 
                      DropdownMenuItem(value: template, child: Text('$template (custom)'))
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      selectedTemplate = value;
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Custom Templates Section
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  border: Border.all(color: Colors.blue[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.edit_note, size: 18, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Custom Chat Templates',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Colors.blue[900]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Create custom templates with {system}, {user}, and {assistant} placeholders to match your model\'s format.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showCustomTemplateEditor(context);
                        },
                        icon: Icon(Icons.add, size: 18),
                        label: Text('Create New Template'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    if (_chatService.customTemplateNames.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Saved Templates (${_chatService.customTemplateNames.length}):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _chatService.customTemplateNames.map((templateName) {
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Icon(Icons.label, size: 14, color: Colors.blue[700]),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                  child: Text(templateName, style: TextStyle(fontSize: 12)),
                                ),
                                InkWell(
                                  onTap: () {
                                    // Edit template
                                    final content = _chatService.settingsService.getCustomTemplateContent(templateName);
                                    Navigator.pop(context); // Close settings
                                    _showCustomTemplateEditor(context, existingName: templateName, existingContent: content);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(Icons.edit, size: 14, color: Colors.blue[700]),
                                  ),
                                ),
                                InkWell(
                                  onTap: () async {
                                    // Show confirmation dialog
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text('Delete Template?'),
                                        content: Text('Are you sure you want to delete "$templateName"?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: Text('Delete', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    );
                                    
                                    if (confirmed == true) {
                                      await _chatService.removeCustomTemplate(templateName);
                                      
                                      // Refresh the dialog
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        _showSettingsDialog();
                                        
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Template "$templateName" deleted'),
                                            backgroundColor: Colors.orange,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Icon(Icons.close, size: 14, color: Colors.red[700]),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Checkbox(
                    value: autoUnloadEnabled,
                    onChanged: (value) async {
                      final newValue = value ?? false;
                      // Update the service immediately to reflect real-time changes
                      await _chatService.updateAutoUnloadModel(newValue);
                      
                      // Update local state to reflect the change
                      setState(() {
                        autoUnloadEnabled = newValue;
                      });
                    },
                  ),
                  Expanded(
                    child: Text('Auto-unload model when inactive'),
                  ),
                ],
              ),
              if (autoUnloadEnabled) ...[
                const SizedBox(height: 8),
                _buildSettingField('Auto-unload timeout (seconds)', autoUnloadTimeoutController, 'Minimum: 10 seconds'),
              ],
              const SizedBox(height: 16),
              const Text('System Message', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: systemMessageController,
                decoration: InputDecoration(
                  hintText: 'Enter the system message for the AI',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 4,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              // Show confirmation dialog for reset
              bool confirmReset = false;
              if (context.mounted) {
                confirmReset = await showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset Settings'),
                    content: const Text('Are you sure you want to reset all settings to their default values? This will reset generation parameters, model settings, and system message.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Reset', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                ) ?? false;
              }

              if (confirmReset) {
                await _chatService.resetSettingsToDefault();
                if (context.mounted) {
                  Navigator.pop(context); // Close settings dialog
                  
                  // Show confirmation that settings were reset
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Settings reset to default values'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Reset', style: TextStyle(color: Colors.red)),
          ),
          TextButton(
            onPressed: () async {
              // Validate and parse context size
              int parsedContextSize = int.tryParse(contextSizeController.text) ?? 2048;
              parsedContextSize = parsedContextSize.clamp(128, 8192);
              
              // Validate and parse timeout
              int parsedTimeout = int.tryParse(autoUnloadTimeoutController.text) ?? 60;
              parsedTimeout = parsedTimeout.clamp(10, 3600); // Max 1 hour
              
              // Update chat service settings
              await _chatService.updateContextSize(parsedContextSize);
              await _chatService.updateChatTemplate(selectedTemplate);
              await _chatService.updateAutoUnloadModel(autoUnloadEnabled);
              await _chatService.updateAutoUnloadTimeout(parsedTimeout);
              
              // Update system message
              await _chatService.updateSystemMessage(systemMessageController.text);
              
              // Update generation config
              setState(() {
                _chatService.generationConfig = GenerationConfig(
                  maxTokens: int.tryParse(maxTokensController.text) ?? 150,
                  temperature: double.tryParse(temperatureController.text) ?? 0.7,
                  topP: double.tryParse(topPController.text) ?? 0.9,
                  topK: int.tryParse(topKController.text) ?? 40,
                  repeatPenalty: double.tryParse(repeatPenaltyController.text) ?? 1.1,
                );
              });
              
              // Check if context is still valid before navigating
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingField(String label, TextEditingController controller, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
          ),
          style: const TextStyle(fontSize: 13),
        ),
      ],
    );
  }

  void _clearChat() {
    debugPrint('[UI] ===== Clear chat triggered =====');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text('Are you sure you want to clear the conversation history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _messages.clear();
                _currentAIResponse = '';
              });
              _chatService.clearHistory();
              Navigator.pop(context);
              debugPrint('[UI] ✓ Chat cleared');
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _stopGeneration() async {
    debugPrint('[UI] ===== Stop generation triggered =====');
    
    if (!_chatService.isGenerating) {
      debugPrint('[UI] ⚠ No generation in progress');
      return;
    }
    
    try {
      await _chatService.stopGeneration();
      debugPrint('[UI] ✓ Generation stopped successfully');
      
      // Force UI rebuild to update button state
      setState(() {
        debugPrint('[UI] UI state updated after stop');
      });
      
      // Show feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Generation stopped'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('[UI] ✗ Error stopping generation: $e');
      setState(() {
        debugPrint('[UI] UI state updated after error');
      });
    }
    
    debugPrint('[UI] ===== Stop generation complete =====');
  }

  void _sendMessage() async {
    debugPrint('[UI] ===== Send message triggered =====');
    
    final text = _textController.text.trim();
    debugPrint('[UI] Message text: "$text"');
    
    if (text.isEmpty) {
      debugPrint('[UI] ✗ Message is empty, returning');
      return;
    }
    
    if (_chatService.isGenerating) {
      debugPrint('[UI] ⚠ Already generating, returning');
      return;
    }
    
    if (!_isModelLoaded) {
      debugPrint('[UI] ✗ Model not loaded, returning');
      return;
    }

    debugPrint('[UI] Clearing text field and sending message to chatService...');
    _textController.clear();
    _chatService.sendMessage(text);
    debugPrint('[UI] ===== Send message complete =====');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Widget _buildContextIndicator() {
    return StreamBuilder<ContextInfo>(
      stream: _chatService.contextInfoStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || !_isModelLoaded) return const SizedBox.shrink();
        
        final info = snapshot.data!;
        final percent = info.usagePercentage;
        
        Color color;
        IconData icon;
        String text;
        
        if (percent > 85) {
          color = Colors.red;
          icon = Icons.warning_amber;
          text = 'Context: ${percent.toStringAsFixed(0)}% full';
        } else if (percent > 70) {
          color = Colors.orange;
          icon = Icons.info_outline;
          text = 'Context: ${percent.toStringAsFixed(0)}%';
        } else {
          color = Colors.green;
          icon = Icons.check_circle_outline;
          text = '${info.tokensUsed}/${info.contextSize} tokens';
        }
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            border: Border(
              bottom: BorderSide(color: Colors.grey[200]!),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              if (percent > 70)
                TextButton.icon(
                  onPressed: () async {
                    await _chatService.clearContext();
                    _chatService.clearHistory();
                    setState(() {
                      _messages.clear();
                      _currentAIResponse = '';
                    });
                  },
                  icon: Icon(Icons.refresh, size: 14, color: color),
                  label: Text('Clear', style: TextStyle(fontSize: 12, color: color)),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chat_bubble, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Qwen Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                Text('0.6B Model', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w300)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_isModelLoaded)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Generation settings',
              onPressed: _showSettingsDialog,
            ),
          if (_messages.isNotEmpty && _isModelLoaded)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear chat',
              onPressed: _clearChat,
            ),
        ],
      ),
      body: Column(
        children: [
          // Context indicator
          if (_isModelLoaded)
            _buildContextIndicator(),
          
          // Status area
          if (!_isModelLoaded || _isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _isModelLoaded ? Colors.green[50] : Colors.orange[50],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isModelLoaded ? Icons.check_circle : Icons.info_outline,
                        size: 18,
                        color: _isModelLoaded ? Colors.green[700] : Colors.orange[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            fontSize: 13,
                            color: _isModelLoaded ? Colors.green[900] : Colors.orange[900],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (_isLoading)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _downloadProgress > 0 ? _downloadProgress / 100 : null,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _isModelLoaded ? Colors.green : Colors.orange,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          
          // Action buttons - only show when model not loaded
          if (!_isModelLoaded)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: !_isLoading ? _loadFromLocal : null,
                          icon: const Icon(Icons.folder_open, size: 18),
                          label: const Text('Load from Local', style: TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Expanded(
                      //   child: ElevatedButton.icon(
                      //     onPressed: null, // Download button disabled
                      //     icon: Icon(Icons.download, size: 18, color: Colors.grey),
                      //     label: Text('Download (Disabled)', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      //     style: ElevatedButton.styleFrom(
                      //       backgroundColor: Colors.grey[200],
                      //       padding: const EdgeInsets.symmetric(vertical: 12),
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                  if (_chatService.hasModelPath) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (_chatService.hasModelPath && !_isLoading && !_chatService.isLoadingModel)
                                ? _loadModel 
                                : null,
                            icon: const Icon(Icons.memory, size: 18),
                            label: const Text('Load into Memory', style: TextStyle(fontSize: 13)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            )
          else
            // Show unload button when model is loaded
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey[200]!),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isModelLoaded && !_isLoading ? _unloadModel : null,
                      icon: const Icon(Icons.exit_to_app, size: 16),
                      label: const Text('Unload Model', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange[700],
                        side: BorderSide(color: Colors.orange[300]!),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Chat messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start chatting after loading the model!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    color: Colors.grey[50],
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageWidget(_messages[index]);
                      },
                    ),
                  ),
          ),
          
          // Input area
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _textController,
                        decoration: InputDecoration(
                          hintText: _chatService.isGenerating 
                              ? 'Generating...' 
                              : 'Type your message...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        enabled: _isModelLoaded && !_chatService.isGenerating,
                        onSubmitted: _isModelLoaded && !_chatService.isGenerating ? (_) => _sendMessage() : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Send or Stop button
                  Container(
                    decoration: BoxDecoration(
                      color: _isModelLoaded
                          ? (_chatService.isGenerating 
                              ? Colors.red[500] 
                              : Colors.blue[500])
                          : Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _isModelLoaded 
                          ? (_chatService.isGenerating ? _stopGeneration : _sendMessage)
                          : null,
                      icon: Icon(_chatService.isGenerating ? Icons.stop_rounded : Icons.send_rounded),
                      color: Colors.white,
                      iconSize: 22,
                      tooltip: _chatService.isGenerating ? 'Stop generation' : 'Send message',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageWidget(UIChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: Colors.purple[100],
              radius: 18,
              child: Icon(Icons.smart_toy, size: 20, color: Colors.purple[700]),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser ? Colors.blue[500] : Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: message.isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.text.isEmpty
                  ? SizedBox(
                      height: 20,
                      width: 40,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildTypingDot(0),
                          const SizedBox(width: 4),
                          _buildTypingDot(1),
                          const SizedBox(width: 4),
                          _buildTypingDot(2),
                        ],
                      ),
                    )
                  : Text(
                      message.text,
                      style: TextStyle(
                        color: message.isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.blue[100],
              radius: 18,
              child: Icon(Icons.person, size: 20, color: Colors.blue[700]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      builder: (context, value, child) {
        final delay = index * 0.15;
        final adjustedValue = (value - delay).clamp(0.0, 1.0);
        final opacity = (adjustedValue * 2).clamp(0.3, 1.0);
        
        return Opacity(
          opacity: opacity,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              shape: BoxShape.circle,
            ),
          ),
        );
      },
      onEnd: () {
        // Restart animation
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  void dispose() {
    _chatService.dispose();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}