import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:dcs_app/utils/app_colors.dart';


class AppNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const AppNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  Widget _placeholder() => Container(
    width: width,
    height: height,
    color: AppColors.surface,
    child: const Center(
      child: CircularProgressIndicator(
        strokeWidth: 2,
        color: AppColors.primary,
      ),
    ),
  );

  Widget _error() => Container(
    width: width,
    height: height,
    color: AppColors.surface,
    child: const Center(
      child: Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted, size: 32),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _error();

    // ✅ PERF: image ला screen च्या physical pixel width पेक्षा मोठं decode करू नये.
    // width finite असेल तर तीच वापर, नाहीतर (double.infinity) screen width.
    final screenW = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final logicalW = (width != null && width!.isFinite) ? width! : screenW;
    final cacheW = (logicalW * dpr).round();

    Widget image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      fit: fit,
      memCacheWidth: cacheW,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (_, __) => _placeholder(),
      errorWidget: (_, __, ___) => _error(),
    );

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}