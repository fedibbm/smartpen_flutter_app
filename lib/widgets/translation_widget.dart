import 'package:flutter/material.dart';
import '../utils/simple_translator.dart';

/// Widget to display text with optional translation
class TranslationWidget extends StatefulWidget {
  final String text;
  final bool showTranslation;

  const TranslationWidget({
    Key? key,
    required this.text,
    this.showTranslation = false,
  }) : super(key: key);

  @override
  State<TranslationWidget> createState() => _TranslationWidgetState();
}

class _TranslationWidgetState extends State<TranslationWidget> {
  String _selectedLanguage = 'en';
  bool _showWordByWord = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.showTranslation || widget.text.isEmpty) {
      return Text(
        widget.text,
        style: Theme.of(context).textTheme.bodyLarge,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Original text
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.translate, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Original (English)',
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Language selector
        Row(
          children: [
            const Text('Translate to: '),
            const SizedBox(width: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'en',
                  label: Text('English'),
                  icon: Icon(Icons.flag, size: 16),
                ),
                ButtonSegment(
                  value: 'fr',
                  label: Text('Français'),
                  icon: Icon(Icons.flag, size: 16),
                ),
                ButtonSegment(
                  value: 'ar',
                  label: Text('العربية'),
                  icon: Icon(Icons.flag, size: 16),
                ),
              ],
              selected: {_selectedLanguage},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedLanguage = newSelection.first;
                });
              },
            ),
            const Spacer(),
            IconButton(
              icon: Icon(_showWordByWord ? Icons.view_list : Icons.view_module),
              tooltip: _showWordByWord ? 'Show full text' : 'Show word-by-word',
              onPressed: () {
                setState(() {
                  _showWordByWord = !_showWordByWord;
                });
              },
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Translated text
        if (_selectedLanguage != 'en')
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.language, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Translation (${SimpleTranslator.getLanguageName(_selectedLanguage)})',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_showWordByWord)
                    _buildWordByWordView()
                  else
                    Text(
                      SimpleTranslator.translate(
                        widget.text,
                        targetLang: _selectedLanguage,
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                      textDirection: _selectedLanguage == 'ar' 
                          ? TextDirection.rtl 
                          : TextDirection.ltr,
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWordByWordView() {
    final pairs = SimpleTranslator.translateWithAnnotations(
      widget.text,
      targetLang: _selectedLanguage,
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: pairs.map((pair) {
        return Tooltip(
          message: pair.wasTranslated 
              ? '${pair.original} → ${pair.translated}'
              : 'No translation available',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: pair.wasTranslated 
                  ? Colors.green.shade100 
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: pair.wasTranslated 
                    ? Colors.green.shade300 
                    : Colors.grey.shade400,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  pair.original,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (pair.wasTranslated) ...[
                  const Icon(Icons.arrow_downward, size: 10),
                  Text(
                    pair.translated,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade900,
                      fontStyle: FontStyle.italic,
                    ),
                    textDirection: _selectedLanguage == 'ar' 
                        ? TextDirection.rtl 
                        : TextDirection.ltr,
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
