/*
|--------------------------------------------------------------------------
| EarthOS
| File: axis_screen.dart
| Feature: AXIS AI Assistant
| Author: Naren
|--------------------------------------------------------------------------
| Full-screen AI assistant with tool-calling capability
|--------------------------------------------------------------------------
*/

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
import 'package:earthos/features/axis/models/axis_response.dart';
import 'package:earthos/features/axis/services/product_service.dart';
import 'package:earthos/features/axis/services/system_context_service.dart';
import 'package:earthos/features/axis/widgets/barcode_scanner_screen.dart';

class AxisScreen extends StatefulWidget {
  const AxisScreen({super.key});

  @override
  State<AxisScreen> createState() => _AxisScreenState();
}

class _AxisScreenState extends State<AxisScreen> {
  final AxisService _axisService = AxisService();
  final UserIdentityService _userIdentityService = UserIdentityService();
  final VisionService _visionService = VisionService();
  final SensitiveZoneService _sensitiveZoneService = SensitiveZoneService();
  final ReportService _reportService = ReportService();
  final ProductService _productService = ProductService();
  final SystemContextService _systemContextService = SystemContextService();
  final TrendService _trendService = TrendService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
    _loadSystemContext();
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

      // Calculate risk score
      final globalStats = await _reportService.fetchImpactStats();
      final sensitiveReports = globalStats['totalSensitiveReports'] as int? ?? 0;
      final riskScore = RiskEngine.calculateRiskScore(
        nearbyOpenReports: nearbyOpenReports,
        sensitiveReports: sensitiveReports,
        highForestAlerts: highConfidence,
        daysSinceLastCleanup: 30,
      );

      // Get trends
      final reports = await _reportService.fetchReports();
      final reportsJson = reports.map((r) => r.toJson()).toList();
      final trends = await _trendService.calculateTrends(
        reports: reportsJson,
        forestAlerts: [],
      );

      // Generate recommendations
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

      // Append recommendations
      if (recommendations.isNotEmpty) {
        greetingParts.add('\n${RecommendationEngine.formatRecommendations(recommendations)}');
      }

      if (greetingParts.length == 1) {
        greetingParts.add('How can I help you make an environmental impact today?');
      }

      setState(() {
        _messages.add(ChatMessage(
          text: greetingParts.join('\n\n'),
          isUser: false,
        ));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Hello! I\'m AXIS, your environmental assistant. How can I help you today?',
          isUser: false,
        ));
      });
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
      });

      // AI Classification
      final classificationResult = await _visionService.classifyWaste(image);
      final wasteType = classificationResult['waste_type'] as String?;
      final severity = classificationResult['severity'] as int?;

      // Get location
      if (_currentPosition == null) {
        await _initializeLocation();
      }

      if (_currentPosition == null) {
        setState(() {
          _messages.add(ChatMessage(
            text: 'Unable to get location. Please enable location services.',
            isUser: false,
          ));
          _isLoading = false;
        });
        _scrollToBottom();
        return;
      }

      // Sensitive zone check
      final isSensitive = await _sensitiveZoneService.isNearSensitiveZone(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
      );

      // Carbon calculation
      var adjustedSeverity = severity ?? 1;
      if (isSensitive) {
        adjustedSeverity = (adjustedSeverity + 1).clamp(1, 5);
      }

      final carbonImpact = CarbonEngine.calculateImpact(
        wasteType: wasteType ?? 'unknown',
        severity: adjustedSeverity,
      );

      // Create report
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

      // Show result message
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

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error capturing report: $e',
          isUser: false,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<void> _scanBarcode() async {
    final barcode = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (barcode == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch product data
      final productData = await _productService.fetchProductData(barcode);

      // Get packaging impact
      final packagingImpact = _productService.estimatePackagingImpact(
        productData['packaging'] as String,
      );

      // Build product info string
      final productInfo = '''
Product: ${productData['product_name']}
Brand: ${productData['brands']}
Packaging: ${productData['packaging']}
Categories: ${productData['categories']}
Packaging Impact: $packagingImpact
''';

      // Send to Gemini for environmental impact explanation
      final prompt = '''
Explain the environmental impact of this product in clear, structured text.

Product Information:
$productInfo

Focus on:
- Packaging sustainability
- Material recyclability
- Disposal difficulty
- Environmental footprint

Provide a concise, informative response.
''';

      final explanation = await _axisService.generateExplanation(prompt);

      // Display result in chat
      setState(() {
        _messages.add(ChatMessage(
          text: explanation,
          isUser: false,
          executedAction: true,
        ));
        _isLoading = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error scanning barcode: $e',
          isUser: false,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: 'Error: $e',
          isUser: false,
        ));
        _isLoading = false;
      });
      _scrollToBottom();
    }
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
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: _messages[index]);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141a24),
        border: Border(
          top: BorderSide(color: AppColors.border),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _isLoading ? null : _captureAndReport,
            icon: const Icon(Icons.camera_alt),
            color: AppColors.primary,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _isLoading ? null : _scanBarcode,
            icon: const Icon(Icons.qr_code_scanner),
            color: AppColors.primary,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
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
          const SizedBox(width: 12),
          IconButton(
            onPressed: _isLoading ? null : _sendMessage,
            icon: const Icon(Icons.send),
            color: AppColors.primary,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool executedAction;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.executedAction = false,
  });
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
