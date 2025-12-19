import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/smart_pen_models.dart';
import 'translation_widget.dart';

class RecognizedTextWidget extends StatelessWidget {
  final List<RecognizedText> recognizedTexts;
  final RecognitionStatus recognitionStatus;
  final Function(String) onDeleteText;

  const RecognizedTextWidget({
    Key? key,
    required this.recognizedTexts,
    required this.recognitionStatus,
    required this.onDeleteText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          if (recognitionStatus == RecognitionStatus.processing)
            _buildProcessingIndicator()
          else if (recognizedTexts.isEmpty)
            _buildEmptyState()
          else
            _buildTextsList(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Row(
        children: [
          Icon(Icons.text_fields, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          const Text(
            'Recognized Text',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          if (recognitionStatus == RecognitionStatus.processing)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildProcessingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Processing handwritten text...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Padding(
      padding: EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.edit, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Start writing with your smart pen',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Your handwritten text will appear here\nwith simplified versions and definitions',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextsList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: recognizedTexts.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final text = recognizedTexts[index];
        return RecognizedTextTile(
          recognizedText: text,
          onDelete: () => onDeleteText(text.id),
        );
      },
    );
  }
}

class RecognizedTextTile extends StatefulWidget {
  final RecognizedText recognizedText;
  final VoidCallback onDelete;

  const RecognizedTextTile({
    Key? key,
    required this.recognizedText,
    required this.onDelete,
  }) : super(key: key);

  @override
  State<RecognizedTextTile> createState() => _RecognizedTextTileState();
}

class _RecognizedTextTileState extends State<RecognizedTextTile> {
  bool _isExpanded = false;
  bool _showSimplified = true;
  bool _showTranslation = false;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      initiallyExpanded: _isExpanded,
      onExpansionChanged: (expanded) {
        setState(() {
          _isExpanded = expanded;
        });
      },
      leading: _buildComplexityIndicator(),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _formatTime(widget.recognizedText.timestamp),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const Spacer(),
              Text(
                '${(widget.recognizedText.confidence * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showSimplified = !_showSimplified;
                  });
                },
                icon: Icon(
                  _showSimplified ? Icons.visibility : Icons.visibility_off,
                  size: 16,
                ),
                label: Text(
                  _showSimplified ? 'Simple' : 'Original',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
              ),
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showTranslation = !_showTranslation;
                  });
                },
                icon: Icon(
                  _showTranslation ? Icons.translate : Icons.translate_outlined,
                  size: 16,
                ),
                label: Text(
                  _showTranslation ? 'Translated' : 'Translate',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: _showTranslation
            ? TranslationWidget(
                text: _showSimplified 
                    ? widget.recognizedText.simplifiedText 
                    : widget.recognizedText.originalText,
                showTranslation: true,
              )
            : Text(
                _showSimplified 
                    ? widget.recognizedText.simplifiedText 
                    : widget.recognizedText.originalText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
      ),
      trailing: IconButton(
        onPressed: widget.onDelete,
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        iconSize: 20,
      ),
      children: [
        _buildExpandedContent(),
      ],
    );
  }

  Widget _buildComplexityIndicator() {
    Color color;
    String label;
    
    switch (widget.recognizedText.complexity) {
      case TextComplexity.simple:
        color = Colors.green;
        label = 'S';
        break;
      case TextComplexity.medium:
        color = Colors.orange;
        label = 'M';
        break;
      case TextComplexity.complex:
        color = Colors.red;
        label = 'C';
        break;
    }

    return CircleAvatar(
      radius: 12,
      backgroundColor: color,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Both versions
          _buildTextSection('Original Text:', widget.recognizedText.originalText),
          const SizedBox(height: 12),
          _buildTextSection('Simplified Text:', widget.recognizedText.simplifiedText),
          const SizedBox(height: 16),
          
          // Key words
          if (widget.recognizedText.keyWords.isNotEmpty) ...[
            const Text(
              'Key Words:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.recognizedText.keyWords.map((keyword) {
                return Chip(
                  label: Text(keyword),
                  backgroundColor: Colors.blue.shade50,
                  labelStyle: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],
          
          // Definitions
          if (widget.recognizedText.definitions.isNotEmpty) ...[
            const Text(
              'Definitions:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.recognizedText.definitions.map((definition) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '• $definition',
                  style: const TextStyle(fontSize: 14),
                ),
              );
            }),
            const SizedBox(height: 16),
          ],
          
          // Actions
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => _copyToClipboard(widget.recognizedText.simplifiedText),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy Simple'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => _copyToClipboard(widget.recognizedText.originalText),
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy Original'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextSection(String title, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Text copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
