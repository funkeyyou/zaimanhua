import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:zai_x/app/app_style.dart';
import 'package:zai_x/services/app_settings_service.dart';

class NetImage extends StatefulWidget {
  final String picUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final double borderRadius;
  final bool progress;
  final bool thumbnail;
  final VoidCallback? onLoaded;
  const NetImage(this.picUrl,
      {this.width,
      this.height,
      this.fit = BoxFit.cover,
      this.borderRadius = 0,
      this.progress = false,
      this.thumbnail = false,
      this.onLoaded,
      super.key});

  @override
  State<NetImage> createState() => _NetImageState();
}

class _NetImageState extends State<NetImage>
    with SingleTickerProviderStateMixin {
  late AnimationController animationController;
  String? _notifiedUrl;

  void _notifyLoaded() {
    final url = widget.picUrl;
    if (widget.onLoaded == null || _notifiedUrl == url) return;
    _notifiedUrl = url;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.picUrl == url) widget.onLoaded?.call();
    });
  }

  @override
  void didUpdateWidget(covariant NetImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.picUrl != widget.picUrl) _notifiedUrl = null;
  }

  @override
  void initState() {
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var picUrl = widget.picUrl;

    if (picUrl.isEmpty) {
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
    if (widget.thumbnail) {
      return LayoutBuilder(
          builder: (context, constraints) => _buildImage(
                picUrl,
                cacheWidth: thumbnailDecodeWidth(
                    constraints.constrainWidth(widget.width ?? double.infinity),
                    MediaQuery.devicePixelRatioOf(context)),
              ));
    }
    return _buildImage(picUrl);
  }

  Widget _buildImage(String picUrl, {int? cacheWidth}) => ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: ExtendedImage.network(
          picUrl,
          fit: widget.fit,
          height: widget.height,
          width: widget.width,
          cacheWidth: cacheWidth,
          cache: true,
          shape: BoxShape.rectangle,
          handleLoadingProgress: widget.progress,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          headers: const {'Referer': "http://www.zaimanhua.com/"},
          loadStateChanged: (e) {
            if (e.extendedImageLoadState == LoadState.loading) {
              animationController.reset();
              final double? progress =
                  e.loadingProgress?.expectedTotalBytes != null
                      ? e.loadingProgress!.cumulativeBytesLoaded /
                          e.loadingProgress!.expectedTotalBytes!
                      : null;
              if (widget.progress) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                      ),
                      AppStyle.vGap4,
                      Text(
                        '${((progress ?? 0.0) * 100).toInt()}%',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                );
              }
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
            if (e.extendedImageLoadState == LoadState.failed) {
              animationController.reset();
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
            }
            if (e.extendedImageLoadState == LoadState.completed) {
              _notifyLoaded();
              if (e.wasSynchronouslyLoaded ||
                  AppSettingsService.instance.eInkMode.value) {
                return e.completedWidget;
              }
              animationController.forward();

              return FadeTransition(
                opacity: animationController,
                child: e.completedWidget,
              );
            }
            return null;
          },
        ),
      );

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }
}

/// 按物理像素解码封面，64px 分桶避免分屏尺寸微调时不断产生新快取。
int? thumbnailDecodeWidth(double width, double pixelRatio) {
  if (!width.isFinite ||
      width <= 0 ||
      !pixelRatio.isFinite ||
      pixelRatio <= 0) {
    return null;
  }
  return ((width * pixelRatio / 64).ceil() * 64).clamp(64, 2048);
}
