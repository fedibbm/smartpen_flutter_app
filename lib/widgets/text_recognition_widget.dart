import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/smart_pen_models.dart';
import '../providers/smart_pen_provider.dart';
import '../services/text_to_speech_service.dart';
import '../utils/simple_translator.dart';
import '../utils/spell_corrector.dart';

class TextRecognitionWidget extends StatelessWidget {
  final List<RecognizedText> recognizedTexts;
  final RecognitionStatus recognitionStatus;
  final VoidCallback? onClear;
  final bool showLatestOnly;

  const TextRecognitionWidget({
    Key? key,
    required this.recognizedTexts,
    required this.recognitionStatus,
    this.onClear,
    this.showLatestOnly = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.text_fields,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  showLatestOnly ? 'Latest Scan' : 'Recognized Text',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const Spacer(),
                if (recognitionStatus == RecognitionStatus.processing)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                if (onClear != null && recognizedTexts.isNotEmpty && !showLatestOnly)
                  IconButton(
                    onPressed: onClear,
                    icon: const Icon(Icons.clear_all),
                    tooltip: 'Clear all text',
                  ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: recognizedTexts.isEmpty && recognitionStatus != RecognitionStatus.processing
                ? _buildEmptyState()
                : _buildTextList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.edit_note,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Start writing to see text recognition',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Connect your smart pen and begin writing',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: recognizedTexts.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final text = recognizedTexts[index];
        return TextRecognitionCard(text: text);
      },
    );
  }
}

class TextRecognitionCard extends StatefulWidget {
  final RecognizedText text;

  const TextRecognitionCard({
    Key? key,
    required this.text,
  }) : super(key: key);

  @override
  State<TextRecognitionCard> createState() => _TextRecognitionCardState();
}

class _TextRecognitionCardState extends State<TextRecognitionCard> {
  bool _showSimplified = false;
  bool _showDefinitions = false;
  bool _showTranslation = false;
  String _selectedLanguage = 'fr';
  bool _showWordByWord = false;
  Future? _translationFuture;
  String? _cachedLanguage;

  void _startTranslation() {
    final provider = context.read<SmartPenProvider>();
    if (_cachedLanguage != _selectedLanguage || _translationFuture == null) {
      setState(() {
        _cachedLanguage = _selectedLanguage;
        _translationFuture = provider.translationService.translate(
          text: widget.text.originalText,
          targetLang: _selectedLanguage,
          sourceLang: 'en',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with timestamp and confidence
            Row(
              children: [
                Icon(
                  _getComplexityIcon(),
                  color: _getComplexityColor(),
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  _getComplexityText(),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getComplexityColor(),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${(widget.text.confidence * 100).round()}% confident',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Original Text
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Original Text',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: widget.text.originalText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Text copied to clipboard')),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 16),
                        tooltip: 'Copy text',
                      ),
                      Consumer<SmartPenProvider>(
                        builder: (context, provider, child) {
                          final isSpeaking = provider.ttsState == TtsState.playing;
                          final isPaused = provider.ttsState == TtsState.paused;
                          
                          return IconButton(
                            onPressed: provider.ttsEnabled
                                ? () async {
                                    if (isSpeaking) {
                                      await provider.stopSpeech();
                                    } else if (isPaused) {
                                      await provider.resumeSpeech();
                                    } else {
                                      await provider.speakText(widget.text.originalText);
                                    }
                                  }
                                : null,
                            icon: Icon(
                              isSpeaking
                                  ? Icons.stop
                                  : isPaused
                                      ? Icons.play_arrow
                                      : Icons.volume_up,
                              size: 16,
                              color: isSpeaking
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                            ),
                            tooltip: isSpeaking
                                ? 'Stop reading'
                                : isPaused
                                    ? 'Resume reading'
                                    : 'Read aloud',
                          );
                        },
                      ),
                    ],
                  ),
                  Text(
                    widget.text.originalText,
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            
            // Show corrections made (if any)
            if (_hasCorrections()) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.auto_fix_high, size: 14, color: Colors.amber.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${_getCorrectionsCount()} spelling corrections applied',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.amber.shade900,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => _showCorrectionsDialog(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(40, 20),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('View', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            
            // Action buttons
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  label: const Text('Simplified'),
                  selected: _showSimplified,
                  onSelected: (selected) {
                    setState(() {
                      _showSimplified = selected;
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Translate'),
                  avatar: Icon(Icons.translate, size: 16),
                  selected: _showTranslation,
                  onSelected: (selected) {
                    setState(() {
                      _showTranslation = selected;
                      if (selected) {
                        _startTranslation(); // Start translation when enabled
                      }
                    });
                  },
                ),
                FilterChip(
                  label: const Text('Definitions'),
                  selected: _showDefinitions,
                  onSelected: (selected) {
                    setState(() {
                      _showDefinitions = selected;
                    });
                  },
                ),
                ActionChip(
                  label: const Text('Key Words'),
                  avatar: const Icon(Icons.highlight, size: 16),
                  onPressed: () {
                    _showKeyWordsDialog();
                  },
                ),
              ],
            ),
            
            // Simplified text
            if (_showSimplified) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Simplified Version',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.text.simplifiedText,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ],
            
            // Translation
            if (_showTranslation) ...[
              const SizedBox(height: 12),
              // Language selector
              Row(
                children: [
                  const Text('Language: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'fr', label: Text('Français')),
                      ButtonSegment(value: 'ar', label: Text('العربية')),
                    ],
                    selected: {_selectedLanguage},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _selectedLanguage = newSelection.first;
                        _startTranslation(); // Trigger new translation
                      });
                    },
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(_showWordByWord ? Icons.view_list : Icons.view_module, size: 20),
                    tooltip: _showWordByWord ? 'Full text' : 'Word-by-word',
                    onPressed: () {
                      setState(() {
                        _showWordByWord = !_showWordByWord;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.translate, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Translation (${SimpleTranslator.getLanguageName(_selectedLanguage)})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _showWordByWord
                        ? _buildWordByWordTranslation()
                        : _buildHybridTranslation(context),
                  ],
                ),
              ),
            ],
            
            // Definitions
            if (_showDefinitions) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Word Definitions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.text.definitions.map((definition) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $definition',
                        style: const TextStyle(fontSize: 14),
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getComplexityIcon() {
    switch (widget.text.complexity) {
      case TextComplexity.simple:
        return Icons.check_circle;
      case TextComplexity.medium:
        return Icons.warning;
      case TextComplexity.complex:
        return Icons.error;
    }
  }

  Color _getComplexityColor() {
    switch (widget.text.complexity) {
      case TextComplexity.simple:
        return Colors.green;
      case TextComplexity.medium:
        return Colors.orange;
      case TextComplexity.complex:
        return Colors.red;
    }
  }

  String _getComplexityText() {
    switch (widget.text.complexity) {
      case TextComplexity.simple:
        return 'Easy to read';
      case TextComplexity.medium:
        return 'Moderate difficulty';
      case TextComplexity.complex:
        return 'Complex text';
    }
  }

  void _showKeyWordsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Key Words'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: widget.text.keyWords.map((word) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Chip(
              label: Text(word),
              backgroundColor: Colors.yellow.shade100,
            ),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildWordByWordTranslation() {
    final pairs = SimpleTranslator.translateWithAnnotations(
      widget.text.originalText,
      targetLang: _selectedLanguage,
    );

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: pairs.map((pair) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: pair.wasTranslated ? Colors.green.shade100 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: pair.wasTranslated ? Colors.green.shade400 : Colors.grey.shade400,
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                pair.original,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (pair.wasTranslated) ...[
                Icon(Icons.arrow_downward, size: 12, color: Colors.blue.shade700),
                Text(
                  pair.translated,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade900,
                    fontWeight: FontWeight.w500,
                  ),
                  textDirection: _selectedLanguage == 'ar' 
                      ? TextDirection.rtl 
                      : TextDirection.ltr,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHybridTranslation(BuildContext context) {
    if (_translationFuture == null) {
      _startTranslation();
    }
    
    return FutureBuilder(
      future: _translationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              const Text('Translating...'),
            ],
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Translation error: ${snapshot.error}',
            style: TextStyle(color: Colors.red.shade700, fontSize: 14),
          );
        }

        if (snapshot.hasData) {
          final result = snapshot.data!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.translatedText,
                style: const TextStyle(fontSize: 16),
                textDirection: _selectedLanguage == 'ar' 
                    ? TextDirection.rtl 
                    : TextDirection.ltr,
              ),
              const SizedBox(height: 4),
              Text(
                'Source: ${result.source} • Coverage: ${(result.coverage * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          );
        }

        return const Text('Translation not available');
      },
    );
  }

  bool _hasCorrections() {
    final corrections = SpellCorrector.getCorrections(widget.text.originalText);
    return corrections.isNotEmpty;
  }

  int _getCorrectionsCount() {
    return SpellCorrector.getCorrections(widget.text.originalText).length;
  }

  void _showCorrectionsDialog() {
    final corrections = SpellCorrector.getCorrections(widget.text.originalText);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_fix_high, color: Colors.amber.shade700),
            const SizedBox(width: 8),
            const Text('Spelling Corrections'),
          ],
        ),
        content: SizedBox(
          width: 300,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: corrections.length,
            separatorBuilder: (context, index) => const Divider(),
            itemBuilder: (context, index) {
              final correction = corrections[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: Colors.red.shade100,
                  child: Icon(Icons.close, color: Colors.red.shade700, size: 16),
                ),
                title: Text(
                  correction.original,
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.red,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_forward, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.green.shade100,
                      child: Icon(Icons.check, color: Colors.green.shade700, size: 16),
                    ),
                  ],
                ),
                subtitle: Text(
                  correction.corrected,
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
