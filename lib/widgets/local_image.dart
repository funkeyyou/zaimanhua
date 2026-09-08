import 'dart:io';

import 'package:flutter/material.dart';

class LocalImage extends StatefulWidget {
  final String path;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final double borderRadius;
  final bool progress;
  final VoidCallback? onLoaded;
  const LocalImage(this.path,
      {this.width,
      this.height,
      this.fit = BoxFit.cover,
      this.borderRadius = 0,
      this.progress = false,
      this.onLoaded,
      super.key});

  @override
  State<LocalImage> createState() => _LocalImageState();
}

class _LocalImageState extends State<LocalImage> {
  String? _notifiedPath;

  @override
  Widget build(BuildContext context) {
    if (widget.path.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: .1),
        ),
        child: const Icon(
          Icons.image,
          color: Colors.grey,
          size: 24,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: Image.file(
        File(widget.path),
        fit: widget.fit,
        height: widget.height,
        width: widget.width,
        errorBuilder: (_, error, stack) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: .1),
            ),
            child: const Icon(
              Icons.broken_image,
              color: Colors.grey,
              size: 24,
            ),
          );
        },
        frameBuilder: (context, child, frame, synchronous) {
          if (frame == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (_notifiedPath != widget.path && widget.onLoaded != null) {
            final path = widget.path;
            _notifiedPath = path;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && widget.path == path) widget.onLoaded?.call();
            });
          }
          return child;
        },
      ),
    );
  }
}
