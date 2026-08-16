import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Network image with branded fallback and an optional bottom gradient scrim
/// for overlay text legibility.
class NetworkImageCover extends StatelessWidget {
  final String? url;
  final double? height;
  final double? width;
  final bool scrim;
  final double iconSize;

  const NetworkImageCover({
    super.key,
    this.url,
    this.height,
    this.width,
    this.scrim = false,
    this.iconSize = 36,
  });

  @override
  Widget build(BuildContext context) {
    final image = url != null
        ? Image.network(
            url!,
            fit: BoxFit.cover,
            height: height,
            width: width,
            errorBuilder: (_, _, _) => _fallback(),
          )
        : _fallback();

    if (!scrim) return image;

    return Stack(
      fit: StackFit.expand,
      children: [
        image,
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: [0.45, 1.0],
              colors: [Colors.transparent, Colors.black54],
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallback() {
    return Container(
      height: height,
      width: width,
      color: AppColors.brandSoft,
      child: Icon(
        Icons.home_rounded,
        color: AppColors.inkFaded,
        size: iconSize,
      ),
    );
  }
}
