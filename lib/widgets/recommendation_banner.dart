import 'package:flutter/material.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';
import 'package:zai_x/widgets/net_image.dart';

class RecommendationBanner extends StatelessWidget {
  const RecommendationBanner({
    super.key,
    required this.images,
    required this.titles,
    required this.onSelected,
    required this.autoplay,
  });

  final List<String> images;
  final List<String> titles;
  final ValueChanged<int> onSelected;
  final bool autoplay;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: LayoutBuilder(builder: (context, constraints) {
        // Preserve the original artwork ratio while showing more cards on wide screens.
        final height = (constraints.maxWidth / (75 / 40)).clamp(0.0, 280.0);
        final fraction = constraints.maxWidth == 0
            ? 1.0
            : height * (75 / 40) / constraints.maxWidth;
        return SizedBox(
          height: height,
          child: Swiper(
            itemCount: images.length,
            loop: images.length > 1,
            autoplay: autoplay && images.length > 1,
            viewportFraction: fraction,
            onTap: onSelected,
            itemBuilder: (context, index) => Padding(
              padding: EdgeInsets.symmetric(horizontal: fraction < 1 ? 6 : 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(fit: StackFit.expand, children: [
                  NetImage(images[index], thumbnail: true),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 24, 12, 26),
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      )),
                      child: Text(titles[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 14)),
                    ),
                  ),
                ]),
              ),
            ),
            pagination: images.length < 2
                ? null
                : const SwiperPagination(
                    margin: EdgeInsets.only(bottom: 8),
                    builder: DotSwiperPaginationBuilder(
                      color: Colors.white38,
                      activeColor: Colors.white,
                      size: 5,
                      activeSize: 7,
                    ),
                  ),
          ),
        );
      }),
    );
  }
}
