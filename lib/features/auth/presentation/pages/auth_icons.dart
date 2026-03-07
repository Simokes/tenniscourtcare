import 'package:flutter/material.dart';

class FacebookIcon extends StatelessWidget {
  final double size;
  const FacebookIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    // Simple Facebook "f" icon representation
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Color(0xFF1877F2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        'f',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.7,
          fontFamily: 'Roboto', // Fallback font that looks decent
        ),
      ),
    );
  }
}

class GoogleIcon extends StatelessWidget {
  final double size;
  const GoogleIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Simple Google "G" icon representation
    // Using a ShaderMask to give it multi-color look if possible, or just a colored G
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: cs.outlineVariant),
      ),
      alignment: Alignment.center,
      child: ShaderMask(
        shaderCallback: (bounds) {
          return const LinearGradient(
            colors: [
              Color(0xFF4285F4), // Blue
              Color(0xFFEA4335), // Red
              Color(0xFFFBBC05), // Yellow
              Color(0xFF34A853), // Green
            ],
            stops: [0.25, 0.5, 0.75, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(bounds);
        },
        child: Text(
          'G',
          style: TextStyle(
            color: Colors.white, // Required for ShaderMask
            fontWeight: FontWeight.bold,
            fontSize: size * 0.7,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }
}
