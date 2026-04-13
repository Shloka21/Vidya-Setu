import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
  try {
    final model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
    );
    final response = await model.generateContent([Content.text('Say hello')]);
    print('1.5 works: ${response.text}');
  } catch (e) {
    print('1.5 error: $e');
  }

  try {
    final model2 = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: apiKey,
    );
    final response2 = await model2.generateContent([Content.text('Say hello')]);
    print('2.5 works: ${response2.text}');
  } catch (e) {
    print('2.5 error: $e');
  }
}
