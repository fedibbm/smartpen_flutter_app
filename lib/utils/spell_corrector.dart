/// Built-in spell correction for common OCR errors
/// No external server needed - runs entirely in the Flutter app
class SpellCorrector {
  // Common OCR and spelling mistakes (educational/science terms)
  static final Map<String, String> _corrections = {
    // Photosynthesis variations
    'photosynthasis': 'photosynthesis',
    'photosinthesis': 'photosynthesis',
    'fotosynthesis': 'photosynthesis',
    
    // Mitochondria variations
    'mitochundria': 'mitochondria',
    'mithocondria': 'mitochondria',
    'mitocondria': 'mitochondria',
    
    // Responsible variations
    'responsable': 'responsible',
    'responcible': 'responsible',
    'responsibile': 'responsible',
    
    // Cellular variations
    'celluar': 'cellular',
    'celular': 'cellular',
    'cellullar': 'cellular',
    
    // Respiration variations
    'resperation': 'respiration',
    'respration': 'respiration',
    'respiracion': 'respiration',
    
    // Democracy variations
    'democrasy': 'democracy',
    'democricy': 'democracy',
    'democratie': 'democracy',
    
    // Participation variations
    'partisipation': 'participation',
    'participacion': 'participation',
    'particpation': 'participation',
    
    // Citizens variations
    'citezens': 'citizens',
    'citizins': 'citizens',
    'citizans': 'citizens',
    
    // Government variations
    'goverment': 'government',
    'govenment': 'government',
    'govermnent': 'government',
    
    // Environment variations
    'enviroment': 'environment',
    'enviorment': 'environment',
    'environement': 'environment',
    
    // Sustainable variations
    'sustainible': 'sustainable',
    'sustanable': 'sustainable',
    'sustaineable': 'sustainable',
    
    // Development variations
    'developement': 'development',
    'developmnt': 'development',
    'devlopment': 'development',
    
    // Approximately variations
    'aproximately': 'approximately',
    'aproximatly': 'approximately',
    'approximatly': 'approximately',
    
    // Biodiversity variations
    'biodivercity': 'biodiversity',
    'biodiverity': 'biodiversity',
    'bio-diversity': 'biodiversity',
    
    // Ecosystem variations
    'ecosistem': 'ecosystem',
    'ecosytem': 'ecosystem',
    'ecossystem': 'ecosystem',
    
    // Nervous variations
    'nervus': 'nervous',
    'nervouse': 'nervous',
    'nervious': 'nervous',
    
    // Gravity variations
    'gravitie': 'gravity',
    'gravty': 'gravity',
    'gravitiy': 'gravity',
    
    // Renewable variations
    'renuwable': 'renewable',
    'renewible': 'renewable',
    'reneweble': 'renewable',
    
    // Transmits variations
    'transmitts': 'transmits',
    'transmitss': 'transmits',
    'trasmits': 'transmits',
    
    // Phenomenon variations
    'phenominon': 'phenomenon',
    'phenomemon': 'phenomenon',
    'phenomenom': 'phenomenon',
    
    // Fundamental variations
    'fundmental': 'fundamental',
    'fundemental': 'fundamental',
    'fundamentel': 'fundamental',
    
    // Common OCR errors
    'teh': 'the',
    'thier': 'their',
    'recieve': 'receive',
    'beleive': 'believe',
    'occured': 'occurred',
    'occuring': 'occurring',
    'seperete': 'separate',
    'definately': 'definitely',
    'independant': 'independent',
    'existance': 'existence',
  };

  /// Correct spelling in text
  static String correctText(String text) {
    if (text.isEmpty) return text;

    final words = text.split(RegExp(r'\s+'));
    final correctedWords = <String>[];

    for (final word in words) {
      // Remove punctuation for matching
      final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
      final lowerWord = cleanWord.toLowerCase();
      
      if (_corrections.containsKey(lowerWord)) {
        // Found a correction
        final corrected = _corrections[lowerWord]!;
        
        // Preserve original capitalization
        final result = _preserveCapitalization(word, cleanWord, corrected);
        correctedWords.add(result);
      } else {
        correctedWords.add(word);
      }
    }

    return correctedWords.join(' ');
  }

  /// Preserve original capitalization pattern
  static String _preserveCapitalization(String original, String clean, String corrected) {
    // Extract punctuation
    final punctuation = original.substring(clean.length);
    
    // Check capitalization pattern
    if (clean.isEmpty) return corrected + punctuation;
    
    if (clean == clean.toUpperCase()) {
      // ALL CAPS
      return corrected.toUpperCase() + punctuation;
    } else if (clean[0] == clean[0].toUpperCase()) {
      // First letter capitalized
      return corrected[0].toUpperCase() + corrected.substring(1).toLowerCase() + punctuation;
    } else {
      // lowercase
      return corrected.toLowerCase() + punctuation;
    }
  }

  /// Get list of corrections made
  static List<SpellCorrection> getCorrections(String originalText) {
    final corrections = <SpellCorrection>[];
    final words = originalText.split(RegExp(r'\s+'));
    int position = 0;

    for (final word in words) {
      final cleanWord = word.replaceAll(RegExp(r'[^\w]'), '');
      final lowerWord = cleanWord.toLowerCase();
      
      if (_corrections.containsKey(lowerWord)) {
        corrections.add(SpellCorrection(
          original: cleanWord,
          corrected: _corrections[lowerWord]!,
          position: position,
          type: 'spelling',
        ));
      }
      
      position += word.length + 1; // +1 for space
    }

    return corrections;
  }
}

/// Individual spell correction record
class SpellCorrection {
  final String original;
  final String corrected;
  final int position;
  final String type;

  SpellCorrection({
    required this.original,
    required this.corrected,
    required this.position,
    required this.type,
  });
}
