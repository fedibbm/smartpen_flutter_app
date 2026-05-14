import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/smart_pen_provider.dart';
import '../models/smart_pen_models.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';

class ScanHistoryScreen extends StatelessWidget {
  const ScanHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('scanHistory')),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          Consumer<SmartPenProvider>(
            builder: (context, provider, child) {
              if (provider.recognizedTexts.isEmpty) return const SizedBox.shrink();
              
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: context.tr('clearAllHistory'),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.tr('clearHistory')),
                      content: Text(context.tr('clearHistoryConfirm')),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(context.tr('cancel')),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(context.tr('delete'), style: const TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  
                  if (confirmed == true) {
                    provider.clearRecognizedTexts();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(context.tr('historyCleared'))),
                      );
                    }
                  }
                },
              );
            },
          ),
        ],
      ),
      body: Consumer<SmartPenProvider>(
        builder: (context, provider, child) {
          if (provider.recognizedTexts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    context.tr('noScanHistory'),
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.tr('startScanningToSee'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          // Show most recent first
          final reversedTexts = provider.recognizedTexts.reversed.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reversedTexts.length,
            itemBuilder: (context, index) {
              final text = reversedTexts[index];
              return _buildHistoryCard(context, text, index);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, RecognizedText text, int index) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final timeAgo = _getTimeAgo(context, text.timestamp);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          text.originalText.length > 50 
              ? '${text.originalText.substring(0, 50)}...' 
              : text.originalText,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text(
                  timeAgo,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            if (text.confidence > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    text.confidence > 0.8 ? Icons.check_circle : Icons.warning,
                    size: 14,
                    color: text.confidence > 0.8 
                        ? Colors.green.shade600 
                        : Colors.orange.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${(text.confidence * 100).toStringAsFixed(0)}% ${context.tr('confidence')}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full text
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SelectableText(
                    text.originalText,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Metadata
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: Icon(Icons.calendar_today, size: 16, color: Theme.of(context).colorScheme.primary),
                      label: Text(
                        dateFormat.format(text.timestamp),
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                    Chip(
                      avatar: Icon(Icons.text_fields, size: 16, color: Colors.green.shade700),
                      label: Text(
                          '${text.originalText.split(' ').length} ${context.tr('words')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.green.shade50,
                    ),
                    Chip(
                      avatar: Icon(Icons.abc, size: 16, color: Colors.purple.shade700),
                      label: Text(
                          '${text.originalText.length} ${context.tr('characters')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.purple.shade50,
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: text.originalText));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.tr('copiedToClipboard'))),
                          );
                        },
                        icon: const Icon(Icons.copy, size: 18),
                        label: Text(context.tr('copy')),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(context.tr('shareFeatureComingSoon'))),
                          );
                        },
                        icon: const Icon(Icons.share, size: 18),
                        label: Text(context.tr('share')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(BuildContext context, DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return context.tr('justNow');
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${context.tr('minutesAgo')}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${context.tr('hoursAgo')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}${context.tr('daysAgo')}';
    } else {
      return DateFormat('MMM dd, yyyy').format(timestamp);
    }
  }
}
