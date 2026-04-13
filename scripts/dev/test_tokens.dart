import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

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

  final model = GenerativeModel(
    model: 'gemini-3-flash-preview',
    apiKey: apiKey,
    generationConfig: GenerationConfig(
      maxOutputTokens: 65536,
    ),
  );

  final prompt = 'Print the numbers 1 to 5000 one per line.';

  try {
    print('Testing 65536 output tokens limit...');
    final response = await model.generateContent([Content.text(prompt)]);
    print('Response length: \${response.text?.length}');
    print('Last characters: \${response.text?.substring((response.text?.length ?? 50) - 50)}');
  } catch (e) {
    print('ERROR:\n\$e');
  }
}
