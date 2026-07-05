import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
class AvatarImage extends StatelessWidget {
  final String? photoUrl;
  final double width;
  final double height;
  final BoxFit fit;

  const AvatarImage({
    super.key,
    required this.photoUrl,
    this.width = 40,
    this.height = 40,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (photoUrl == null || photoUrl!.isEmpty) {
      return SizedBox(width: width, height: height);
    }

    // Since we migrated to Cloudinary, all valid URLs should be HTTP
    return CachedNetworkImage(
      imageUrl: photoUrl!,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: (width * 3).toInt(), // Pre-scale for memory efficiency
      memCacheHeight: (height * 3).toInt(),
      errorWidget: (context, url, error) => SizedBox(width: width, height: height),
      placeholder: (context, url) => SizedBox(
        width: width, 
        height: height,
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
