import 'dart:io';
import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

void main() async {
  final envFile = File('.env');
  final lines = envFile.readAsLinesSync();
  String apiKey = '';
  for (var line in lines) {
    if (line.startsWith('GEMINI_API_KEY=')) {
      apiKey = line.split('=')[1].trim();
      break;
    }
  }
  
  if (apiKey.isEmpty) {
    print('Error: API key is empty');
    exit(1);
  }

  final modelsToTest = [
    'gemini-1.5-flash',
    'gemini-3.0-flash-preview',
    'gemini-3-flash-preview',
    'gemini-3.0-flash',
    'gemini-2.0-flash',
    'gemini-pro',
  ];

  for (var modelName in modelsToTest) {
    try {
      final model = GenerativeModel(
        model: modelName,
        apiKey: apiKey,
      );
      print('Testing $modelName...');
      final response = await model.generateContent([Content.text('Reply "yes" if you can hear me.')]);
      print('✅ SUCCESS - $modelName works! Response: ${response.text?.trim()}');
    } catch (e) {
      print('❌ FAILED - $modelName: $e');
    }
  }
  exit(0);
}
