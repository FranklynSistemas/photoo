import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

class PhotoViewer extends StatelessWidget {
  const PhotoViewer({
    super.key,
    required this.imageFile,
  });

  final File imageFile;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageWidth = constraints.maxWidth;
        final imageHeight = constraints.maxHeight;

        // Checking aspect ratio to differentiate between horizontal and vertical images
        final aspectRatio = imageWidth / imageHeight;

        return Stack(
          children: [
            // Blurred Background
            Positioned.fill(
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Image.file(
                  imageFile,
                  fit: BoxFit.cover, // Background fills the entire screen
                ),
              ),
            ),
            // Animated Image handling vertical vs horizontal
            Center(
              child: TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(
                    milliseconds: 600), // Set transition duration
                curve: Curves.easeInOut,
                builder: (context, double opacity, child) {
                  return Opacity(
                    opacity: opacity,
                    child: (aspectRatio > 1) // Horizontal image
                        ? Image.file(
                            imageFile,
                            fit: BoxFit.cover, // Fill screen without stretching
                          )
                        : Image.file(
                            imageFile,
                            fit: BoxFit
                                .contain, // Vertical image centered and scaled
                          ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
