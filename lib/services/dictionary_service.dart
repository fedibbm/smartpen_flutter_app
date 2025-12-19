import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/network_config.dart';

/// Service for fetching word definitions from Free Dictionary API
/// Supports English and French dictionaries - no API key required
class DictionaryService {
  final http.Client _client;
  bool _isAvailable = false;

  DictionaryService({http.Client? client}) 
    : _client = client ?? http.Client();

  bool get isAvailable => _isAvailable;

  /// Check if Dictionary API is available
  Future<bool> checkAvailability() async {
    try {
      // Test with a simple word
      final response = await _client
          .get(Uri.parse(NetworkConfig.dictionaryApiEndpoint('en', 'test')))
          .timeout(const Duration(seconds: 5));
      
      _isAvailable = response.statusCode == 200;
      return _isAvailable;
    } catch (e) {
      _isAvailable = false;
      return false;
    }
  }

  /// Get definition for a word
  /// Supports 'en' (English) and 'fr' (French)
  Future<WordDefinition> getDefinition(String word, {String language = 'en'}) async {
    try {
      final response = await _client
          .get(Uri.parse(NetworkConfig.dictionaryApiEndpoint(language, word)))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        if (data.isNotEmpty) {
          return WordDefinition.fromJson(data[0], language);
        }
        throw DictionaryException('No definition found for "$word"', 404);
      } else if (response.statusCode == 404) {
        throw DictionaryException('Word "$word" not found', 404);
      } else {
        throw DictionaryException(
          'Dictionary request failed with status ${response.statusCode}',
          response.statusCode,
        );
      }
    } on TimeoutException {
      throw DictionaryException('Dictionary request timed out', 408);
    } catch (e) {
      if (e is DictionaryException) rethrow;
      throw DictionaryException('Failed to fetch definition: $e', 500);
    }
  }

  /// Get definitions for multiple words
  Future<List<WordDefinition>> getDefinitions(
    List<String> words, {
    String language = 'en',
  }) async {
    final definitions = <WordDefinition>[];

    for (final word in words) {
      try {
        final definition = await getDefinition(word, language: language);
        definitions.add(definition);
      } catch (e) {
        // Continue with other words if one fails
        definitions.add(WordDefinition.error(word, language, e.toString()));
      }
    }

    return definitions;
  }

  void dispose() {
    _client.close();
  }
}

/// Word definition model
class WordDefinition {
  final String word;
  final String language;
  final String? phonetic;
  final List<String> definitions;
  final List<String> examples;
  final List<String> synonyms;
  final String? partOfSpeech;
  final bool success;
  final String? error;

  WordDefinition({
    required this.word,
    required this.language,
    this.phonetic,
    required this.definitions,
    required this.examples,
    required this.synonyms,
    this.partOfSpeech,
    required this.success,
    this.error,
  });

  factory WordDefinition.fromJson(Map<String, dynamic> json, String language) {
    final meanings = json['meanings'] as List<dynamic>? ?? [];
    final allDefinitions = <String>[];
    final allExamples = <String>[];
    final allSynonyms = <String>[];
    String? firstPartOfSpeech;

    for (final meaning in meanings) {
      if (firstPartOfSpeech == null) {
        firstPartOfSpeech = meaning['partOfSpeech'];
      }

      final defs = meaning['definitions'] as List<dynamic>? ?? [];
      for (final def in defs) {
        final definition = def['definition'];
        if (definition != null) {
          allDefinitions.add(definition);
        }

        final example = def['example'];
        if (example != null) {
          allExamples.add(example);
        }
      }

      final syns = meaning['synonyms'] as List<dynamic>? ?? [];
      allSynonyms.addAll(syns.map((s) => s.toString()));
    }

    return WordDefinition(
      word: json['word'] ?? '',
      language: language,
      phonetic: json['phonetic'],
      definitions: allDefinitions,
      examples: allExamples,
      synonyms: allSynonyms,
      partOfSpeech: firstPartOfSpeech,
      success: true,
    );
  }

  factory WordDefinition.error(String word, String language, String errorMessage) {
    return WordDefinition(
      word: word,
      language: language,
      definitions: [],
      examples: [],
      synonyms: [],
      success: false,
      error: errorMessage,
    );
  }

  /// Get a simple summary for dyslexic-friendly display
  String getSimpleSummary() {
    if (!success || definitions.isEmpty) {
      return '$word: Definition not available';
    }

    final mainDef = definitions.first;
    final pos = partOfSpeech != null ? '($partOfSpeech) ' : '';
    return '$word: $pos$mainDef';
  }

  /// Get detailed explanation
  String getDetailedExplanation() {
    if (!success) return error ?? 'No definition available';

    final buffer = StringBuffer();
    buffer.writeln('$word ${phonetic ?? ''}');
    
    if (partOfSpeech != null) {
      buffer.writeln('($partOfSpeech)');
    }
    
    buffer.writeln('\nDefinitions:');
    for (var i = 0; i < definitions.length && i < 3; i++) {
      buffer.writeln('${i + 1}. ${definitions[i]}');
    }

    if (examples.isNotEmpty) {
      buffer.writeln('\nExample:');
      buffer.writeln('"${examples.first}"');
    }

    if (synonyms.isNotEmpty) {
      buffer.writeln('\nSimilar words: ${synonyms.take(3).join(', ')}');
    }

    return buffer.toString();
  }
}

/// Dictionary exception
class DictionaryException implements Exception {
  final String message;
  final int statusCode;

  DictionaryException(this.message, this.statusCode);

  @override
  String toString() => 'DictionaryException: $message (Status: $statusCode)';
}
