import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Service for stitching multiple frame images into a single panoramic image
class ImageStitchingService {
  /// Stitch a list of frames into a single panoramic image
  /// Uses simple horizontal concatenation with overlap detection
  Future<Uint8List> stitchFrames(List<Uint8List> frames) async {
    if (frames.isEmpty) {
      throw Exception('No frames to stitch');
    }

    if (frames.length == 1) {
      return frames.first;
    }

    print('🖼️ Stitching ${frames.length} frames...');

    // Decode all frames
    List<img.Image> images = [];
    for (var frameData in frames) {
      final image = img.decodeImage(frameData);
      if (image != null) {
        images.add(image);
      }
    }

    if (images.isEmpty) {
      throw Exception('Failed to decode frames');
    }

    // Start with the first image
    img.Image stitched = images.first;

    // Stitch subsequent images with overlap detection
    for (int i = 1; i < images.length; i++) {
      stitched = _stitchTwoImages(stitched, images[i]);
    }

    // Encode to PNG
    final pngBytes = img.encodePng(stitched);
    print('✅ Stitched image size: ${stitched.width}x${stitched.height}');
    
    return Uint8List.fromList(pngBytes);
  }

  /// Stitch two images together with simple horizontal concatenation
  /// Uses basic overlap detection based on edge similarity
  img.Image _stitchTwoImages(img.Image left, img.Image right) {
    // Calculate overlap region (assume 20% overlap)
    final overlapWidth = (left.width * 0.2).round();
    
    // Find best overlap position by comparing pixel similarity
    int bestOffset = _findBestOverlap(left, right, overlapWidth);
    
    // Create new image with combined width
    final newWidth = left.width + right.width - bestOffset;
    final newHeight = left.height > right.height ? left.height : right.height;
    
    final stitched = img.Image(width: newWidth, height: newHeight);
    
    // Copy left image
    img.compositeImage(stitched, left, dstX: 0, dstY: 0);
    
    // Blend right image with overlap
    final rightX = left.width - bestOffset;
    
    if (bestOffset > 0) {
      // Blend the overlap region
      _blendOverlap(stitched, left, right, rightX, bestOffset);
    } else {
      // No overlap, just place side by side
      img.compositeImage(stitched, right, dstX: rightX, dstY: 0);
    }
    
    return stitched;
  }

  /// Find the best overlap position by comparing edge pixels
  int _findBestOverlap(img.Image left, img.Image right, int maxOverlap) {
    int bestOffset = 0;
    double bestScore = double.infinity;
    
    final searchWidth = maxOverlap.clamp(10, 100);
    
    for (int offset = 0; offset < searchWidth; offset += 5) {
      double score = _calculateOverlapScore(left, right, offset);
      if (score < bestScore) {
        bestScore = score;
        bestOffset = offset;
      }
    }
    
    return bestOffset;
  }

  /// Calculate similarity score for a given overlap
  double _calculateOverlapScore(img.Image left, img.Image right, int overlap) {
    if (overlap <= 0) return double.infinity;
    
    double totalDiff = 0;
    int sampleCount = 0;
    
    final height = left.height < right.height ? left.height : right.height;
    
    // Sample pixels in the overlap region
    for (int y = 0; y < height; y += 5) {
      for (int x = 0; x < overlap && x < left.width && x < right.width; x += 5) {
        final leftX = left.width - overlap + x;
        
        if (leftX >= 0 && leftX < left.width && x < right.width) {
          final leftPixel = left.getPixel(leftX, y);
          final rightPixel = right.getPixel(x, y);
          
          // Calculate color difference
          final diff = _colorDifference(leftPixel, rightPixel);
          totalDiff += diff;
          sampleCount++;
        }
      }
    }
    
    return sampleCount > 0 ? totalDiff / sampleCount : double.infinity;
  }

  /// Calculate difference between two pixels
  double _colorDifference(img.Pixel p1, img.Pixel p2) {
    final dr = p1.r - p2.r;
    final dg = p1.g - p2.g;
    final db = p1.b - p2.b;
    return (dr * dr + dg * dg + db * db).toDouble();
  }

  /// Blend the overlap region between two images
  void _blendOverlap(img.Image dest, img.Image left, img.Image right, int rightX, int overlapWidth) {
    final height = left.height < right.height ? left.height : right.height;
    
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < overlapWidth; x++) {
        final destX = rightX + x;
        final leftX = rightX + x;
        final rightXCoord = x;
        
        if (destX >= 0 && destX < dest.width &&
            leftX >= 0 && leftX < left.width &&
            rightXCoord >= 0 && rightXCoord < right.width) {
          
          // Alpha blending based on position in overlap
          final alpha = x / overlapWidth;
          
          final leftPixel = left.getPixel(leftX, y);
          final rightPixel = right.getPixel(rightXCoord, y);
          
          // Blend colors
          final r = ((1 - alpha) * leftPixel.r + alpha * rightPixel.r).round();
          final g = ((1 - alpha) * leftPixel.g + alpha * rightPixel.g).round();
          final b = ((1 - alpha) * leftPixel.b + alpha * rightPixel.b).round();
          
          dest.setPixelRgba(destX, y, r, g, b, 255);
        }
      }
    }
    
    // Copy the non-overlap part of the right image
    for (int y = 0; y < right.height && y < dest.height; y++) {
      for (int x = overlapWidth; x < right.width; x++) {
        final destX = rightX + x;
        if (destX >= 0 && destX < dest.width) {
          final pixel = right.getPixel(x, y);
          dest.setPixelRgba(destX, y, pixel.r.round(), pixel.g.round(), pixel.b.round(), 255);
        }
      }
    }
  }

  /// Preprocess frames before stitching (resize, normalize, etc.)
  List<img.Image> preprocessFrames(List<img.Image> frames, {int targetHeight = 800}) {
    return frames.map((frame) {
      // Resize if too large
      if (frame.height > targetHeight) {
        final aspectRatio = frame.width / frame.height;
        final newWidth = (targetHeight * aspectRatio).round();
        return img.copyResize(frame, width: newWidth, height: targetHeight);
      }
      return frame;
    }).toList();
  }
}
