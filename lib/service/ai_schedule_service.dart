import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/task_model.dart';
import '../models/schedule_analysis.dart';

class AiScheduleService extends ChangeNotifier {
  ScheduleAnalysis? _currentAnalysis;
  bool _isLoading = false;
  String? _errorMessage;

  // ⚠️ Move this to .env in production
  final String _apiKey = 'AIzaSyBihrxPOckd8keevvxRXs76T5KrASxA_oc';

  ScheduleAnalysis? get currentAnalysis => _currentAnalysis;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> analyzeSchedule(List<TaskModel> tasks) async {
    if (_apiKey.isEmpty || tasks.isEmpty) return;

    _isLoading = true;
    _errorMessage = null;
    _currentAnalysis = null;
    notifyListeners();

    try {
      final model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
      );

      final tasksJson = jsonEncode(
        tasks.map((t) => t.toJson()).toList(),
      );

      // ✅ FORCE JSON OUTPUT (much more reliable than markdown parsing)
      final prompt = '''
You are an expert student scheduling assistant.

Analyze the following tasks and return ONLY valid JSON.

Tasks:
$tasksJson

Return format (STRICT JSON ONLY):
{
  "conflicts": "string describing scheduling conflicts",
  "rankedTasks": "string or bullet list of prioritized tasks",
  "recommendedSchedule": "string describing optimized schedule",
  "explanation": "reasoning behind the schedule"
}

Rules:
- Output ONLY JSON
- No markdown
- No explanation outside JSON
- No extra text
''';

      final response = await model.generateContent([
        Content.text(prompt),
      ]);

      final text = response.text;

      if (text == null || text.trim().isEmpty) {
        throw Exception("Empty response from AI");
      }

      final decoded = jsonDecode(text);

      _currentAnalysis = ScheduleAnalysis(
        conflicts: decoded["conflicts"] ?? "",
        rankedTasks: decoded["rankedTasks"] ?? "",
        recommendationSchedule: decoded["recommendedSchedule"] ?? "",
        explanation: decoded["explanation"] ?? "",
      );
    } catch (e) {
      _errorMessage = 'Failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}