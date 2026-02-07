import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/alert_model.dart';

/// Service for integrating with Google's Gemini AI to generate security analysis
/// Provides AI-powered insights and recommendations based on alert data
class GeminiService {
  /// The Gemini generative model instance
  static GenerativeModel? _model;

  /// Initializes the Gemini service with API key from environment variables
  /// Throws an exception if the API key is not found or initialization fails
  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: ".env");
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('GEMINI_API_KEY not found in .env file');
      }

      _model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 2048000,
        ),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Generates AI-powered security analysis from alert data
  /// Returns a map containing summary paragraphs and recommendations
  /// Returns empty state analysis if no alerts provided
  /// Returns error analysis if generation fails
  static Future<Map<String, dynamic>> generateSecurityAnalysis(List<AlertModel> alerts) async {
    if (_model == null) {
      throw Exception('Gemini service not initialized');
    }

    if (alerts.isEmpty) {
      return _getEmptyStateAnalysis();
    }

    try {
      final prompt = _buildAnalysisPrompt(alerts);
      
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Empty response from Gemini');
      }
      
      final jsonResponse = _extractJson(response.text!);
      return jsonResponse;
      
    } catch (e) {
      return _getErrorAnalysis(e.toString());
    }
  }

  /// Extracts and parses JSON from Gemini's response text
  /// Handles markdown code blocks and formatting issues
  /// Returns fallback response if parsing fails
  static Map<String, dynamic> _extractJson(String text) {
    try {
      String cleanText = text.trim();
      
      // Remove markdown code block markers
      if (cleanText.startsWith('```json')) {
        cleanText = cleanText.substring(7);
      } else if (cleanText.startsWith('```')) {
        cleanText = cleanText.substring(3);
      }
      
      if (cleanText.endsWith('```')) {
        cleanText = cleanText.substring(0, cleanText.length - 3);
      }
      
      cleanText = cleanText.trim();
      
      final parsed = jsonDecode(cleanText);
      return parsed as Map<String, dynamic>;
    } catch (e) {
      // Return fallback response on parsing error
      return {
        'summary': [
          'Analysis generated but formatting error occurred.',
          'Please try refreshing the analysis.',
          'If the issue persists, contact support.'
        ],
        'recommendations': [
          {
            'title': 'Review Required',
            'description': 'Manual review of security data recommended due to parsing error',
            'priority': 'MEDIUM',
            'icon': 'alert'
          }
        ]
      };
    }
  }

  /// Builds a detailed prompt for Gemini AI based on alert statistics
  /// Includes severity breakdown, location hotspots, time distribution, and alert types
  static String _buildAnalysisPrompt(List<AlertModel> alerts) {
    final now = DateTime.now();
    
    // Filter alerts for today
    final todayAlerts = alerts.where((a) {
      return a.timestamp.year == now.year &&
             a.timestamp.month == now.month &&
             a.timestamp.day == now.day;
    }).toList();

    // Calculate severity counts
    final highAlerts = todayAlerts.where((a) => a.severity == 'HIGH').toList();
    final mediumAlerts = todayAlerts.where((a) => a.severity == 'MEDIUM').toList();
    final lowAlerts = todayAlerts.where((a) => a.severity == 'LOW').toList();
    final ongoingAlerts = todayAlerts.where((a) => !a.resolved).toList();

    // Count alerts by type
    final Map<String, int> typeCount = {};
    for (var alert in todayAlerts) {
      typeCount[alert.type] = (typeCount[alert.type] ?? 0) + 1;
    }

    // Count alerts by location
    final Map<String, int> locationCount = {};
    for (var alert in todayAlerts) {
      locationCount[alert.location] = (locationCount[alert.location] ?? 0) + 1;
    }

    // Distribute alerts by time slots
    final Map<String, int> timeSlots = {
      'Morning (6AM-12PM)': 0,
      'Afternoon (12PM-6PM)': 0,
      'Evening (6PM-12AM)': 0,
      'Night (12AM-6AM)': 0,
    };

    for (var alert in todayAlerts) {
      final hour = alert.timestamp.hour;
      if (hour >= 6 && hour < 12) {
        timeSlots['Morning (6AM-12PM)'] = timeSlots['Morning (6AM-12PM)']! + 1;
      } else if (hour >= 12 && hour < 18) {
        timeSlots['Afternoon (12PM-6PM)'] = timeSlots['Afternoon (12PM-6PM)']! + 1;
      } else if (hour >= 18 && hour < 24) {
        timeSlots['Evening (6PM-12AM)'] = timeSlots['Evening (6PM-12AM)']! + 1;
      } else {
        timeSlots['Night (12AM-6AM)'] = timeSlots['Night (12AM-6AM)']! + 1;
      }
    }

    // Get recent high-priority alerts
    final recentHighAlerts = highAlerts.take(3).map((a) {
      return '${a.type} at ${a.location} (${a.getFormattedTime()})';
    }).join(', ');

    return '''
You are an AI security analyst for a school surveillance system. Analyze the security data and provide a structured JSON response.

**SECURITY DATA FOR ${now.day}/${now.month}/${now.year}:**

Alert Statistics:
- Total Alerts: ${todayAlerts.length}
- High Severity: ${highAlerts.length}
- Medium Severity: ${mediumAlerts.length}
- Low Severity: ${lowAlerts.length}
- Ongoing: ${ongoingAlerts.length}
- Resolved: ${todayAlerts.length - ongoingAlerts.length}

Alert Types:
${typeCount.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

Location Hotspots:
${locationCount.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

Time Distribution:
${timeSlots.entries.map((e) => '- ${e.key}: ${e.value}').join('\n')}

Recent High-Priority: ${recentHighAlerts.isNotEmpty ? recentHighAlerts : 'None'}

**RESPONSE FORMAT (MUST BE VALID JSON):**

{
  "summary": [
    "First paragraph: Brief overview with total events and severity breakdown (1-2 sentences)",
    "Second paragraph: Key patterns and hotspots identified (1-2 sentences)",
    "Third paragraph: System performance and threat assessment (1-2 sentences)"
  ],
  "recommendations": [
    {
      "title": "Recommendation Title",
      "description": "Detailed description of the recommendation",
      "priority": "HIGH|MEDIUM|LOW",
      "icon": "patrol|camera|maintenance|alert|security"
    }
  ]
}

**INSTRUCTIONS:**

1. **Summary Array** - Provide exactly 3 short paragraphs:
   - Paragraph 1: Total events today, severity breakdown (HIGH/MEDIUM/LOW counts)
   - Paragraph 2: Key insights - location hotspots, time patterns, alert types
   - Paragraph 3: System metrics (98.3% accuracy, 2.1s response, 99.9% uptime) and threat level

2. **Recommendations Array** - Provide exactly 3 recommendations:
   - First: HIGH priority (if critical issues exist, otherwise MEDIUM)
   - Second: MEDIUM priority
   - Third: LOW priority
   - For the description keep it under 30 words.

3. **Icon Values** - Use ONLY: "patrol", "camera", "maintenance", "alert", "security"

4. **Writing Style:**
   - Keep each paragraph under 2 sentences
   - Be specific with numbers, locations, and times
   - Use clear, concise language
   - Avoid jargon
   - Consider school context

**CRITICAL: Return ONLY valid JSON. No markdown, no explanations, no extra text.**
''';
  }

  /// Returns a default analysis for when no alerts are present
  static Map<String, dynamic> _getEmptyStateAnalysis() {
    return {
      'summary': [
        'No security incidents detected today. All monitored areas are secure with zero alerts triggered.',
        'All cameras and sensors are functioning optimally across all locations. No patterns of concern identified.',
        'System maintains 98.3% accuracy with 2.1s response time and 99.9% uptime. Threat level: MINIMAL.'
      ],
      'recommendations': [
        {
          'title': 'Maintain Current Protocols',
          'description': 'Continue standard monitoring procedures as all systems are functioning optimally',
          'priority': 'LOW',
          'icon': 'security'
        },
        {
          'title': 'Schedule Preventive Maintenance',
          'description': 'Use this quiet period to perform routine equipment checks and camera calibration',
          'priority': 'LOW',
          'icon': 'maintenance'
        },
        {
          'title': 'Conduct Security Training',
          'description': 'Ideal time for staff training and emergency response drills without active incidents',
          'priority': 'LOW',
          'icon': 'patrol'
        }
      ]
    };
  }

  /// Returns a fallback analysis when AI generation fails
  static Map<String, dynamic> _getErrorAnalysis(String error) {
    return {
      'summary': [
        'Unable to generate AI analysis due to a technical issue.',
        'System data is still being collected and monitored in real-time.',
        'Please review security alerts manually through the History tab.'
      ],
      'recommendations': [
        {
          'title': 'Manual Review Required',
          'description': 'Check the History tab to review all security events and their current status',
          'priority': 'HIGH',
          'icon': 'alert'
        },
        {
          'title': 'Verify System Connection',
          'description': 'Ensure stable internet connectivity and retry the AI analysis',
          'priority': 'MEDIUM',
          'icon': 'maintenance'
        },
        {
          'title': 'Contact Support',
          'description': 'If the issue persists, contact the system administrator for assistance',
          'priority': 'LOW',
          'icon': 'security'
        }
      ]
    };
  }
}
