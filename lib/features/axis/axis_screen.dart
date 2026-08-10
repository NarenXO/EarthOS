/*
|--------------------------------------------------------------------------
| EarthOS
| File: axis_screen.dart
| Feature: AXIS AI Assistant
| Author: Naren
|--------------------------------------------------------------------------
| Full-screen AI assistant with tool-calling capability & TTS voice reply
|--------------------------------------------------------------------------
*/
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:earthos/core/constants/app_colors.dart';
import 'package:earthos/core/services/user_identity_service.dart';
import 'package:earthos/core/services/vision_service.dart';
import 'package:earthos/core/services/carbon_engine.dart';
import 'package:earthos/core/services/sensitive_zone_service.dart';
import 'package:earthos/core/services/risk_engine.dart';
import 'package:earthos/core/services/recommendation_engine.dart';
import 'package:earthos/core/services/trend_service.dart';
import 'package:earthos/features/report/services/report_service.dart';
import 'package:earthos/features/axis/services/axis_service.dart';
import 'package:earthos/features/axis/services/product_service.dart';
import 'package:earthos/features/axis/services/system_context_service.dart';
import 'package:earthos/features/axis/widgets/axis_avatar.dart';
import 'package:earthos/features/axis/widgets/mlkit_barcode_scanner.dart';

class AxisScreen extends StatefulWidget {
  const AxisScreen({super.key});

  @override
  State<AxisScreen> createState() => _AxisScreenState();
}

class _AxisScreenState extends State<AxisScreen> {
  final AxisService _axisService = AxisService();
  final UserIdentityService _userIdentityService = UserIdentityService();
  final SensitiveZoneService _sensitiveZoneService = SensitiveZoneService();
  final ReportService _reportService = ReportService();
  final ProductService _productService = ProductService();
  final SystemContextService _systemContextService = SystemContextService();
  final TrendService _trendService = TrendService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _tts = FlutterTts();

  late stt.SpeechToText _speech;
  bool _isListening = false;

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  Position? _currentPosition;
  String _avatarState = 'idle';
  bool _showKeypad = false;

  static const String _chatHistoryKey = 'axis_chat_history';

  @override
  void initState() {
    super.initState();

    _speech = stt.SpeechToText();
    _tts.setLanguage("en-US");
    _tts.setSpeechRate(0.5);
    _tts.setPitch(1.0);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _avatarState = 'idle');
    });

    _initializeLocation();
    _loadChatHistory();
  }

  @override
  void dispose() {
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getStringList(_chatHistoryKey);
      if (historyJson != null && historyJson.isNotEmpty) {
        final loadedMessages = historyJson.map((item) {
          final Map<String, dynamic> jsonMap = jsonDecode(item);
          return ChatMessage.fromJson(jsonMap);
        }).toList();
        setState(() {
          _messages.clear();
          _messages.addAll(loadedMessages);
        });
      } else {
        await _loadSystemContext();
      }
    } catch (e) {
      await _loadSystemContext();
    }
  }

  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson = _messages.map((m) => jsonEncode(m.toJson())).toList();
      await prefs.setStringList(_chatHistoryKey, historyJson);
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }

  Future<void> _speakResponse(String text) async {
    if (text.isEmpty) return;
    setState(() => _avatarState = 'speaking');
    await _tts.speak(text);
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      setState(() {
        _isListening = false;
        _avatarState = 'idle';
      });
    } else {
      bool available = await _speech.initialize();
      if (available) {
        setState(() {
          _isListening = true;
          _avatarState = 'listening';
        });

        _speech.listen(
          onResult: (result) {
            setState(() {
              _messageController.text = result.recognizedWords;
            });

            if (result.finalResult) {
              setState(() => _avatarState = 'processing');
              _toggleListening();
              _sendMessage();
            }
          },
        );
      }
    }
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const MLKitBarcodeScanner(),
      ),
    );

    if (barcode != null && barcode.isNotEmpty) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Scanned barcode: $barcode',
          isUser: true,
        ));
        _isLoading = true;
        _avatarState = 'processing';
      });
      _scrollToBottom();

      final productData = await _productService.fetchProductData(barcode);
      final productName = productData['product_name'] ?? 'Unknown Product';
      final brands = productData['brands'] ?? 'Unknown';
      final packaging = productData['packaging'] ?? 'Unknown';
      final explanation = productData['gemini_explanation'] ?? '';

      final reply = '''
📦 Product: $productName
🏷️ Brand: $brands
♻️ Packaging: $packaging

🌍 Environmental Analysis:
$explanation
''';

      setState(() {
        _messages.add(ChatMessage(
          text: reply,
          isUser: false,
          executedAction: true,
        ));
        _isLoading = false;
      });

      _saveChatHistory();
      _scrollToBottom();
      await _speakResponse(reply);
    }
  }

  void _executePredefinedCommand(String command) {
    _messageController.text = command;
    _sendMessage();
  }

  Future<void> _loadSystemContext() async {
    try {
      final user = await _userIdentityService.getOrCreateUser();
      final context = await _systemContextService.fetchSystemContext(user.id);
      
      final userImpact = context['userImpact'] as Map<String, dynamic>? ?? {};
      final rank = context['rank'] as int? ?? 0;
      final nearbyOpenReports = context['nearbyOpenReports'] as int? ?? 0;
      final forestAlerts = context['forestAlerts'] as Map<String, dynamic>? ?? {};
      final highConfidence = forestAlerts['highConfidence'] as int? ?? 0;

      final globalStats = await _reportService.fetchImpactStats();
      final sensitiveReports = globalStats['totalSensitiveReports'] as int? ?? 0;
      final riskScore = RiskEngine.calculateRiskScore(
        nearbyOpenReports: nearbyOpenReports,
        sensitiveReports: sensitiveReports,
        highForestAlerts: highConfidence,
        daysSinceLastCleanup: 30,
      );

      final reports = await _reportService.fetchReports();
      final reportsJson = reports.map((r) => r.toJson()).toList();
      final trends = await _trendService.calculateTrends(
        reports: reportsJson,
        forestAlerts: [],
      );

      final recommendations = RecommendationEngine.generateRecommendations(
        riskScore: riskScore,
        trends: trends,
        nearbyOpenReports: nearbyOpenReports,
        forestHighConfidence: highConfidence,
        userRank: rank,
      );

      final greetingParts = <String>[];
      greetingParts.add('Hello! I\'m AXIS, your environmental assistant.');

      if (nearbyOpenReports > 0) {
        greetingParts.add('📍 There are $nearbyOpenReports open cleanup reports within 1km of you. Consider helping out!');
      }

      if (rank <= 3 && rank > 0) {
        greetingParts.add('🏆 Amazing! You\'re ranked #$rank on the global leaderboard. Keep up the great work!');
      }

      if (highConfidence > 5) {
        greetingParts.add('🌲 Warning: High forest loss activity detected in your area. Stay alert.');
      }

      final totalCarbon = userImpact['totalVerifiedCarbon'] as double? ?? 0.0;
      if (totalCarbon > 0) {
        greetingParts.add('🌱 You\'ve diverted ${totalCarbon.toStringAsFixed(1)} kg CO₂e through verified cleanups.');
      }

      if (recommendations.isNotEmpty) {
        greetingParts.add('\n${RecommendationEngine.formatRecommendations(recommendations)}');
      }

      if (greetingParts.length == 1) {
        greetingParts.add('How can I help you make an environmental impact today?');
      }

      final greeting = greetingParts.join('\n\n');

      setState(() {
        _messages.add(ChatMessage(
          text: greeting,
          isUser: false,
        ));
      });
      _saveChatHistory();
    } catch (e) {
      const fallbackGreeting = 'Hello! I\'m AXIS, your environmental assistant. How can I help you today?';
      setState(() {
        _messages.add(ChatMessage(
          text: fallbackGreeting,
          isUser: false,
        ));
      });
      _saveChatHistory();
    }
  }

  Future<void> _initializeLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentPosition = position;
    });
  }

  Future<void> _captureAndReport() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() {
        _isLoading = true;
        _avatarState = 'processing';
      });

      final classificationResult =
          await VisionService.classifyWaste(File(image.path));
      final wasteType = classificationResult['waste_type'] as String?;
      final severity = classificationResult['severity'] as int?;

      if (_currentPosition == null) {
        await _initializeLocation();
      }

      if (_currentPosition == null) {
        const errorText = 'Unable to get location. Please enable location services.';
        setState(() {
          _messages.add(ChatMessage(
            text: errorText,
            isUser: false,
          ));
          _isLoading = false;
        });
        _saveChatHistory();
        _scrollToBottom();
        await _speakResponse(errorText);
        return;
      }

      final isSensitive = await _sensitiveZoneService.isNearSensitiveZone(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
      );

      var adjustedSeverity = severity ?? 1;
      if (isSensitive) {
        adjustedSeverity = (adjustedSeverity + 1).clamp(1, 5);
      }

      final carbonImpact = CarbonEngine.calculateImpact(
        wasteType: wasteType ?? 'unknown',
        severity: adjustedSeverity,
      );

      final user = await _userIdentityService.getOrCreateUser();
      await _reportService.createReport(
        type: wasteType ?? 'unknown',
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        createdBy: user.id,
        createdByName: user.name,
        photoBefore: image.path,
        aiClassification: wasteType,
        severity: adjustedSeverity,
        carbonEstimate: carbonImpact,
        isSensitive: isSensitive,
      );

      final resultMessage = '''
Waste detected: ${wasteType ?? 'unknown'} (severity $adjustedSeverity)
Estimated impact: ${carbonImpact.toStringAsFixed(1)} kg CO₂e
Sensitive zone nearby: ${isSensitive ? 'Yes' : 'No'}
Report submitted successfully.
''';

      setState(() {
        _messages.add(ChatMessage(
          text: resultMessage,
          isUser: false,
          executedAction: true,
        ));
        _isLoading = false;
      });

      _saveChatHistory();
      _scrollToBottom();
      await _speakResponse(resultMessage);
    } catch (e) {
      final errText = 'Error capturing report: $e';
      setState(() {
        _messages.add(ChatMessage(
          text: errText,
          isUser: false,
        ));
        _isLoading = false;
      });
      _saveChatHistory();
      _scrollToBottom();
      await _speakResponse(errText);
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: message,
        isUser: true,
      ));
      _isLoading = true;
      _avatarState = 'processing';
      _messageController.clear();
    });

    _scrollToBottom();

    try {
      final user = await _userIdentityService.getOrCreateUser();
      final response = await _axisService.processMessage(
        message: message,
        user: user,
      );

      setState(() {
        _messages.add(ChatMessage(
          text: response.message,
          isUser: false,
          executedAction: response.executedAction,
        ));
        _isLoading = false;
      });

      _saveChatHistory();
      _scrollToBottom();
      await _speakResponse(response.message);
    } catch (e) {
      final errText = 'Error: $e';
      setState(() {
        _messages.add(ChatMessage(
          text: errText,
          isUser: false,
        ));
        _isLoading = false;
      });
      _saveChatHistory();
      _scrollToBottom();
      await _speakResponse(errText);
    }
  }

  void _showChatHistoryModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF141a24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "📜 Chat History",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: AppColors.border),
              Expanded(
                child: _messages.isEmpty
                    ? const Center(
                        child: Text(
                          "No chat history available",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final timeStr =
                              "${msg.timestamp.hour.toString().padLeft(2, '0')}:${msg.timestamp.minute.toString().padLeft(2, '0')}";
                          return ListTile(
                            leading: Icon(
                              msg.isUser ? Icons.person : Icons.smart_toy,
                              color: msg.isUser ? AppColors.primary : Colors.cyan,
                            ),
                            title: Text(
                              msg.text,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              "${msg.isUser ? 'You' : 'AXIS'} • $timeStr",
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0e14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0a0e14),
        title: const Text(
          'AXIS',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Avatar Area
          Expanded(
            flex: 2,
            child: IgnorePointer(
              ignoring: true,
              child: Center(
                child: AxisAvatar(state: _avatarState),
              ),
            ),
          ),
          // Command Chips
          _buildCommandChips(),
          // Chat Messages
          Expanded(
            flex: 3,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),
          // Interaction Dock
          _buildInteractionDock(),
        ],
      ),
    );
  }

  Widget _buildCommandChips() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCommandChip('Report Waste', () => _executePredefinedCommand('report waste')),
          _buildCommandChip('Cleanup Event', () => _executePredefinedCommand('create cleanup event')),
          _buildCommandChip('Risk Status', () => _executePredefinedCommand('risk')),
          _buildCommandChip('Trends', () => _executePredefinedCommand('trends')),
          _buildCommandChip('Recommend', () => _executePredefinedCommand('recommend')),
          _buildCommandChip('Forest Status', () => _executePredefinedCommand('forest status')),
          _buildCommandChip('Weekly Summary', () => _executePredefinedCommand('weekly summary')),
        ],
      ),
    );
  }

  Widget _buildCommandChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(label),
        onPressed: onTap,
        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
        labelStyle: const TextStyle(color: AppColors.primary),
      ),
    );
  }

  Widget _buildInteractionDock() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF141a24),
          border: Border(
            top: BorderSide(color: AppColors.border),
          ),
        ),
        child: Column(
          children: [
            if (_showKeypad) _buildKeypad(),
            Row(
              children: [
                IconButton(
                  onPressed: _isLoading ? null : _captureAndReport,
                  icon: const Icon(Icons.camera_alt),
                  color: AppColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _toggleListening,
                  icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                  color: _isListening ? Colors.red : AppColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: (_isListening ? Colors.red : AppColors.primary).withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _scanBarcode,
                  icon: const Icon(Icons.qr_code_scanner),
                  color: AppColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _showKeypad = !_showKeypad;
                    });
                  },
                  icon: Icon(_showKeypad ? Icons.keyboard_arrow_down : Icons.keyboard),
                  color: AppColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _showChatHistoryModal,
                  icon: const Icon(Icons.history),
                  color: AppColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Ask AXIS anything...',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: AppColors.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  icon: const Icon(Icons.send),
                  color: AppColors.primary,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 16),
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          _buildKeypadButton('1', '1'),
          _buildKeypadButton('2', 'ABC'),
          _buildKeypadButton('3', 'DEF'),
          _buildKeypadButton('4', 'GHI'),
          _buildKeypadButton('5', 'JKL'),
          _buildKeypadButton('6', 'MNO'),
          _buildKeypadButton('7', 'PQRS'),
          _buildKeypadButton('8', 'TUV'),
          _buildKeypadButton('9', 'WXYZ'),
          _buildKeypadButton('*', ''),
          _buildKeypadButton('0', 'SPACE'),
          _buildKeypadButton('#', '⌫'),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String mainLabel, String subLabel) {
    return InkWell(
      onTap: () {
        if (mainLabel == '#') {
          if (_messageController.text.isNotEmpty) {
            _messageController.text = _messageController.text.substring(0, _messageController.text.length - 1);
          }
        } else if (mainLabel == '0' && subLabel == 'SPACE') {
          _messageController.text += ' ';
        } else {
          _messageController.text += mainLabel;
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              mainLabel,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            if (subLabel.isNotEmpty)
              Text(
                subLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool executedAction;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.executedAction = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'text': text,
        'isUser': isUser,
        'executedAction': executedAction,
        'timestamp': timestamp.toIso8601String(),
      };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        text: json['text'] as String? ?? '',
        isUser: json['isUser'] as bool? ?? false,
        executedAction: json['executedAction'] as bool? ?? false,
        timestamp: json['timestamp'] != null
            ? (DateTime.tryParse(json['timestamp'] as String) ?? DateTime.now())
            : DateTime.now(),
      );
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? AppColors.primary
                    : const Color(0xFF1e2532),
                borderRadius: BorderRadius.circular(16),
                border: message.isUser
                    ? null
                    : Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUser ? Colors.white : Colors.white70,
                    ),
                  ),
                  if (message.executedAction && !message.isUser) ...[
                    const SizedBox(height: 4),
                    const Text(
                      '✓ Action executed',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
