import 'package:flutter/material.dart';

import 'shimmer_box.dart';

/// Network image with branded shimmer placeholder showing a house & meal icon
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

  /// Shimmering placeholder with house & meal icons in center
  Widget _buildLoadingShimmer() {
    return Shimmer(
      child: Container(
        height: height,
        width: width,
        color: const Color(0xFFEAEBEF),
        alignment: Alignment.center,
        child: _buildBrandedIcon(
          iconColor: const Color(0xFFB4B9C4),
          badgeColor: const Color(0xFFD3D7E0),
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
      child: _buildBrandedIcon(
        iconColor: const Color(0xFFA6ABB6),
        badgeColor: const Color(0xFFE2E4E8),
      ),
    );
  }

  /// Branded house + food emblem matching the MessMax brand concept
  Widget _buildBrandedIcon({
    required Color iconColor,
    required Color badgeColor,
  }) {
    final effectiveSize = iconSize.clamp(20.0, 64.0);
    final badgeSize = effectiveSize * 0.52;

    return SizedBox(
      width: effectiveSize * 1.3,
      height: effectiveSize * 1.3,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main house/apartment icon
          Icon(
            Icons.apartment_rounded,
            size: effectiveSize,
            color: iconColor,
          ),
          // Floating spoon & fork meal badge on bottom right
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.all(effectiveSize * 0.08),
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_rounded,
                size: badgeSize,
                color: iconColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
