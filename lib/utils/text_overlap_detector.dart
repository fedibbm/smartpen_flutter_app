/// Utility for detecting and merging overlapping text from sequential frames
/// Uses fuzzy string matching to handle OCR errors
class TextOverlapDetector {
  /// Merge multiple text strings by detecting and removing overlaps
  /// Uses fuzzy matching to tolerate OCR errors
  static String mergeTexts(List<String> texts, {double similarityThreshold = 0.8}) {
    if (texts.isEmpty) return '';
    if (texts.length == 1) return texts.first;

    String merged = texts.first;

    for (int i = 1; i < texts.length; i++) {
      final nextText = texts[i];
      final overlap = _findOverlap(merged, nextText, similarityThreshold);

      if (overlap != null) {
        // Remove overlapping portion and append the rest
        merged = merged + nextText.substring(overlap.overlapLength);
        print('🔗 Found overlap: ${overlap.overlapLength} chars (similarity: ${(overlap.similarity * 100).toStringAsFixed(1)}%)');
      } else {
        // No overlap found, add space separator
        merged = merged + ' ' + nextText;
        print('➕ No overlap found, adding with space separator');
      }
    }

    return merged;
  }

  /// Find overlap between end of text1 and beginning of text2
  static _OverlapResult? _findOverlap(String text1, String text2, double threshold) {
    if (text1.isEmpty || text2.isEmpty) return null;

    // Try different overlap sizes, starting from larger overlaps
    final maxOverlap = text1.length < text2.length ? text1.length : text2.length;
    final minOverlap = 5; // Minimum 5 characters to consider

    for (int overlapSize = maxOverlap; overlapSize >= minOverlap; overlapSize--) {
      final suffix = text1.substring(text1.length - overlapSize);
      final prefix = text2.substring(0, overlapSize);

      final similarity = _calculateSimilarity(suffix, prefix);

      if (similarity >= threshold) {
        return _OverlapResult(
          overlapLength: overlapSize,
          similarity: similarity,
        );
      }
    }

    return null;
  }

  /// Calculate similarity between two strings using Levenshtein distance
  /// Returns value between 0.0 (no match) and 1.0 (exact match)
  static double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    // Normalize: lowercase and trim
    final str1 = s1.toLowerCase().trim();
    final str2 = s2.toLowerCase().trim();

    if (str1 == str2) return 1.0;

    final distance = _levenshteinDistance(str1, str2);
    final maxLength = str1.length > str2.length ? str1.length : str2.length;

    return 1.0 - (distance / maxLength);
  }

  /// Calculate Levenshtein distance between two strings
  /// (minimum number of single-character edits to transform one into the other)
  static int _levenshteinDistance(String s1, String s2) {
    final len1 = s1.length;
    final len2 = s2.length;

    // Create distance matrix
    final matrix = List.generate(
      len1 + 1,
      (i) => List.filled(len2 + 1, 0),
    );

    // Initialize first row and column
    for (int i = 0; i <= len1; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    // Fill in the rest of the matrix
    for (int i = 1; i <= len1; i++) {
      for (int j = 1; j <= len2; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;

        matrix[i][j] = _min3(
          matrix[i - 1][j] + 1, // deletion
          matrix[i][j - 1] + 1, // insertion
          matrix[i - 1][j - 1] + cost, // substitution
        );
      }
    }

    return matrix[len1][len2];
  }

  /// Helper to find minimum of three values
  static int _min3(int a, int b, int c) {
    int min = a;
    if (b < min) min = b;
    if (c < min) min = c;
    return min;
  }
}

/// Result of overlap detection
class _OverlapResult {
  final int overlapLength;
  final double similarity;

  _OverlapResult({
    required this.overlapLength,
    required this.similarity,
  });
}
