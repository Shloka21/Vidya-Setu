import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/localization_service.dart';

class TranslatedText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final TextOverflow? overflow;
  final int? maxLines;

  const TranslatedText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.overflow,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    
    final loc = Provider.of<LocalizationService>(context);
    
    // If it's English, just show it
    if (loc.locale == 'en') {
      return Text(text, style: style, textAlign: textAlign, overflow: overflow, maxLines: maxLines);
    }

    // Attempt to get from dictionary first (maybe it was mapped)
    final translated = loc.translate(text);
    if (translated != text) {
      return Text(translated, style: style, textAlign: textAlign, overflow: overflow, maxLines: maxLines);
    }

    // Otherwise, use FutureBuilder to do a dynamic translation if model is available
    return FutureBuilder<String>(
      future: loc.translateDynamic(text),
      builder: (context, snapshot) {
        return Text(
          snapshot.data ?? text, 
          style: style, 
          textAlign: textAlign, 
          overflow: overflow, 
          maxLines: maxLines
        );
      },
    );
  }
}
