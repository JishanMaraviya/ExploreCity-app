import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  print('Loading app_icon.png...');
  final file = File('assets/app_icon.png');
  final bytes = await file.readAsBytes();
  final originalImage = img.decodeImage(bytes);

  if (originalImage == null) {
    print('Failed to decode image');
    return;
  }

  print('Original size: ${originalImage.width}x${originalImage.height}');

  // Adaptive icons require the actual icon to be within the inner 66% (or roughly 72dp out of 108dp).
  // We'll create a canvas that is larger so the original image acts as the 66% inner circle.
  // 1 / 0.666 = 1.5. Let's make the canvas 1.5x the original size.
  final newWidth = (originalImage.width * 1.5).round();
  final newHeight = (originalImage.height * 1.5).round();

  print('Creating new canvas: ${newWidth}x${newHeight}');
  // Create a transparent image
  final paddedImage = img.Image(width: newWidth, height: newHeight);

  // Calculate position to draw the original image in the center
  final dstX = ((newWidth - originalImage.width) / 2).round();
  final dstY = ((newHeight - originalImage.height) / 2).round();

  // Draw the original image onto the padded canvas
  img.compositeImage(paddedImage, originalImage, dstX: dstX, dstY: dstY);

  print('Saving to assets/ic_launcher_foreground.png...');
  final outputFile = File('assets/ic_launcher_foreground.png');
  await outputFile.writeAsBytes(img.encodePng(paddedImage));

  print('Done!');
}
