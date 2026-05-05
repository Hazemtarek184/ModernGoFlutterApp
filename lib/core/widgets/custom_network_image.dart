import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CustomNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final BorderRadius? borderRadius;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
    this.borderRadius,
  });

  String _getImageUrl(String path) {
    if (path.startsWith('http') || path.startsWith('data:image')) {
      return path;
    }
    // Append to base URL and remove leading 'undefined/' if it exists
    final cleanedPath = path.replaceAll('undefined/', '');
    return 'https://modern-go.vercel.app/$cleanedPath';
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildErrorWidget();
    }

    final String processedUrl = _getImageUrl(imageUrl!);

    Widget imageWidget;
    if (processedUrl.startsWith('data:image')) {
      // Decode base64 image
      try {
        final uri = Uri.parse(processedUrl);
        final bytes = uri.data?.contentAsBytes();
        if (bytes != null) {
          imageWidget = Image.memory(
            bytes,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
          );
        } else {
          imageWidget = _buildErrorWidget();
        }
      } catch (e) {
        imageWidget = _buildErrorWidget();
      }
    } else {
      // Regular network image
      imageWidget = CachedNetworkImage(
        imageUrl: processedUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ?? _buildDefaultPlaceholder(),
        errorWidget: (context, url, error) => _buildErrorWidget(),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildDefaultPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade200,
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (errorWidget != null) return errorWidget!;
    return Container(
      width: width,
      height: height,
      color: Colors.grey.shade100,
      child: Icon(
        Icons.image_not_supported_outlined,
        color: Colors.grey.shade400,
        size: (width ?? 50) * 0.5,
      ),
    );
  }
}
