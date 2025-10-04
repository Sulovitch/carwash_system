import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// تكوين الصور المحسّن
class ImageConfig {
  /// بناء صورة محسّنة من الشبكة
  static Widget buildNetworkImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    Widget? placeholder,
    Widget? errorWidget,
    BorderRadius? borderRadius,
  }) {
    if (imageUrl.isEmpty) {
      return errorWidget ?? _buildDefaultError();
    }

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildDefaultPlaceholder(),
      errorWidget: (context, url, error) => errorWidget ?? _buildDefaultError(),
      memCacheWidth: width?.toInt() ?? 500,
      memCacheHeight: height?.toInt() ?? 500,
      maxWidthDiskCache: 800,
      maxHeightDiskCache: 800,
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: image,
      );
    }

    return image;
  }

  /// بناء Placeholder افتراضي
  static Widget _buildDefaultPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }

  /// بناء Error Widget افتراضي
  static Widget _buildDefaultError() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.broken_image,
        size: 50,
        color: Colors.grey[400],
      ),
    );
  }

  /// أيقونة سيارة افتراضية
  static Widget buildCarIcon({double size = 60}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blue[50],
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.directions_car,
        size: size * 0.6,
        color: Colors.blue,
      ),
    );
  }

  /// أيقونة مغسلة افتراضية
  static Widget buildCarWashIcon({double size = 60}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[100]!, Colors.blue[300]!],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.local_car_wash,
        size: size * 0.6,
        color: Colors.white,
      ),
    );
  }
}
