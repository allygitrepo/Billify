import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';

class FullScreenImageViewer extends StatelessWidget {
  final String? imagePath;
  final String tag;

  const FullScreenImageViewer({
    super.key,
    required this.imagePath,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Center(
        child: Hero(
          tag: tag,
          child: InteractiveViewer(
            panEnabled: true,
            minScale: 0.5,
            maxScale: 4,
            child: imagePath != null && imagePath!.isNotEmpty
                ? (imagePath!.startsWith('data:image') ||
                        imagePath!.length > 100
                    ? Image.memory(
                      base64Decode(imagePath!.split(',').last),
                      fit: BoxFit.contain,
                    )
                    : Image.file(
                      File(imagePath!),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Container(
                        padding: const EdgeInsets.all(40),
                        decoration: BoxDecoration(
                          color: Colors.grey[900],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 200,
                          color: Colors.grey[700],
                        ),
                      ),
                    ))
                : Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.person,
                      size: 200,
                      color: Colors.grey[700],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
