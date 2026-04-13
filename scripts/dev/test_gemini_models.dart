import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:io';

void main() async {
  final apiKey = 'AIzaSyDsMVRO78QN8nzblS97H5vHib7UcFh5p_c'; // DO NOT COMMIT
  final models = [
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-2.0-flash',
    'gemini-2.0-flash-exp',
    'gemini-2.5-flash',
    'gemini-3.0-flash',
    'gemini-3-flash-preview',
    'gemini-3.0-flash-preview'
  ];

  for (var modelName in models) {
    print('Testing model: $modelName');
    try {
      final model = GenerativeModel(model: modelName, apiKey: apiKey);
      final response = await model.generateContent([Content.text('Hello')]);
      print('SUCCESS $modelName -> ${response.text?.substring(0, 5)}...');
    } catch (e) {
      print('FAILED $modelName: ${e.toString().split('\n').first}');
    }
    print('---');
  }
}
