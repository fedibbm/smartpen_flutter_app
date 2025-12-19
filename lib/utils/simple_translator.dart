/// Simple built-in translation for common educational terms
/// Supports English to French/Arabic for dyslexic learners
/// No external API needed - runs entirely in the Flutter app
class SimpleTranslator {
  // English to French dictionary (educational terms)
  static final Map<String, String> _enToFr = {
    'photosynthesis': 'photosynthèse',
    'mitochondria': 'mitochondries',
    'cellular': 'cellulaire',
    'respiration': 'respiration',
    'democracy': 'démocratie',
    'participation': 'participation',
    'citizens': 'citoyens',
    'government': 'gouvernement',
    'environment': 'environnement',
    'sustainable': 'durable',
    'development': 'développement',
    'approximately': 'approximativement',
    'biodiversity': 'biodiversité',
    'ecosystem': 'écosystème',
    'nervous': 'nerveux',
    'gravity': 'gravité',
    'renewable': 'renouvelable',
    'transmits': 'transmet',
    'phenomenon': 'phénomène',
    'fundamental': 'fondamental',
    'responsible': 'responsable',
    'the': 'le/la',
    'and': 'et',
    'for': 'pour',
    'with': 'avec',
    'from': 'de',
    'cell': 'cellule',
    'energy': 'énergie',
    'process': 'processus',
    'system': 'système',
    'water': 'eau',
    'light': 'lumière',
    'plants': 'plantes',
    'animals': 'animaux',
    'people': 'gens',
    'world': 'monde',
    'earth': 'terre',
    'nature': 'nature',
    'science': 'science',
    'study': 'étude',
    'important': 'important',
  };

  // English to Arabic dictionary (educational terms)
  static final Map<String, String> _enToAr = {
    'photosynthesis': 'التمثيل الضوئي',
    'mitochondria': 'الميتوكوندريا',
    'cellular': 'خلوي',
    'respiration': 'التنفس',
    'democracy': 'الديمقراطية',
    'participation': 'المشاركة',
    'citizens': 'المواطنون',
    'government': 'الحكومة',
    'environment': 'البيئة',
    'sustainable': 'مستدام',
    'development': 'التنمية',
    'approximately': 'تقريباً',
    'biodiversity': 'التنوع البيولوجي',
    'ecosystem': 'النظام البيئي',
    'nervous': 'عصبي',
    'gravity': 'الجاذبية',
    'renewable': 'متجدد',
    'transmits': 'ينقل',
    'phenomenon': 'ظاهرة',
    'fundamental': 'أساسي',
    'responsible': 'مسؤول',
    'the': 'ال',
    'and': 'و',
    'for': 'لـ',
    'with': 'مع',
    'from': 'من',
    'cell': 'خلية',
    'energy': 'طاقة',
    'process': 'عملية',
    'system': 'نظام',
    'water': 'ماء',
    'light': 'ضوء',
    'plants': 'نباتات',
    'animals': 'حيوانات',
    'people': 'الناس',
    'world': 'العالم',
    'earth': 'الأرض',
    'nature': 'الطبيعة',
    'science': 'علم',
    'study': 'دراسة',
    'important': 'مهم',
  };

  /// Translate text to target language
  static String translate(String text, {String targetLang = 'fr'}) {
    if (text.isEmpty) return text;

    final dictionary = targetLang == 'ar' ? _enToAr : _enToFr;
    final words = text.split(RegExp(r'\s+'));
    final translatedWords = <String>[];

    for (final word in words) {
      // Remove punctuation for matching
      final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
      final lowerWord = cleanWord.toLowerCase();
      
      if (dictionary.containsKey(lowerWord)) {
        // Found a translation
        final translated = dictionary[lowerWord]!;
        
        // Keep punctuation
        final punctuation = word.substring(cleanWord.length);
        translatedWords.add(translated + punctuation);
      } else {
        // No translation found, keep original
        translatedWords.add(word);
      }
    }

    return translatedWords.join(' ');
  }

  /// Translate word-by-word with annotations
  static List<TranslationPair> translateWithAnnotations(String text, {String targetLang = 'fr'}) {
    final pairs = <TranslationPair>[];
    final dictionary = targetLang == 'ar' ? _enToAr : _enToFr;
    final words = text.split(RegExp(r'\s+'));

    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
      final lowerWord = cleanWord.toLowerCase();
      
      pairs.add(TranslationPair(
        original: cleanWord,
        translated: dictionary[lowerWord] ?? cleanWord,
        wasTranslated: dictionary.containsKey(lowerWord),
      ));
    }

    return pairs;
  }

  /// Get available languages
  static List<String> getSupportedLanguages() {
    return ['en', 'fr', 'ar'];
  }

  /// Get language name
  static String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'fr':
        return 'French';
      case 'ar':
        return 'Arabic';
      default:
        return code;
    }
  }
}

/// Translation pair for word-by-word display
class TranslationPair {
  final String original;
  final String translated;
  final bool wasTranslated;

  TranslationPair({
    required this.original,
    required this.translated,
    required this.wasTranslated,
  });
}
