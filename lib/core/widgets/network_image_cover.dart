import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'shimmer_box.dart';

/// Network image with branded shimmer placeholder showing the app SVG icon
/// in soft white/light-grey until fully loaded, and an optional bottom gradient scrim.
class NetworkImageCover extends StatelessWidget {
  final String? url;
  final double? height;
  final double? width;
  final bool scrim;
  final double iconSize;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const NetworkImageCover({
    super.key,
    this.url,
    this.height,
    this.width,
    this.scrim = false,
    this.iconSize = 36,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final validUrl = url != null && url!.trim().isNotEmpty;

    Widget content;
    if (!validUrl) {
      content = _buildPlaceholder();
    } else {
      content = Image.network(
        url!,
        fit: fit,
        height: height,
        width: width,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return _buildLoadingShimmer();
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder();
        },
      );
    }

    if (scrim) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          content,
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.4, 1.0],
                colors: [Colors.transparent, Colors.black87],
              ),
            ),
          ),
        ],
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: SizedBox(
          height: height,
          width: width,
          child: content,
        ),
      );
    }

    return SizedBox(
      height: height,
      width: width,
      child: content,
    );
  }

  /// Shimmering placeholder with the white / light-grey brand SVG icon in center
  Widget _buildLoadingShimmer() {
    return Shimmer(
      child: Container(
        height: height,
        width: width,
        color: const Color(0xFFE8E9EE),
        alignment: Alignment.center,
        child: Opacity(
          opacity: 0.45,
          child: SvgPicture.asset(
            'assets/images/mm_fav.svg',
            width: iconSize,
            height: iconSize,
            colorFilter: const ColorFilter.mode(
              Color(0xFFB0B4BE),
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }

  /// Fallback static placeholder when image is absent or errors
  Widget _buildPlaceholder() {
    return Container(
      height: height,
      width: width,
      color: const Color(0xFFF1F2F6),
      alignment: Alignment.center,
      child: Opacity(
        opacity: 0.35,
        child: SvgPicture.asset(
          'assets/images/mm_fav.svg',
          width: iconSize,
          height: iconSize,
          colorFilter: const ColorFilter.mode(
            Color(0xFF989CA8),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }
}
