import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/network/backend_config.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

class AdBanner {
  const AdBanner({
    required this.id,
    required this.name,
    this.imageUrl,
    this.link,
    required this.order,
  });

  final int id;
  final String name;
  final String? imageUrl;
  final String? link;
  final int order;

  factory AdBanner.fromJson(Map<String, dynamic> json) {
    return AdBanner(
      id: (json['id'] as num).toInt(),
      name: json['name']?.toString() ?? '',
      imageUrl: json['image_url']?.toString(),
      link: json['link']?.toString(),
      order: (json['order'] as num?)?.toInt() ?? 0,
    );
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final adBannersProvider =
    AsyncNotifierProvider<AdBannersNotifier, List<AdBanner>>(
      AdBannersNotifier.new,
    );

class AdBannersNotifier extends AsyncNotifier<List<AdBanner>> {
  @override
  Future<List<AdBanner>> build() async {
    return _fetchAds();
  }

  Future<List<AdBanner>> _fetchAds() async {
    try {
      final dio = Dio(BaseOptions(baseUrl: BackendConfig.apiBaseUrl));

      // Public endpoint – no auth required
      final response = await dio.get<Map<String, dynamic>>(
        '/publicities',
        queryParameters: {'per_page': 20, 'only_active': true},
      );

      final raw = response.data;
      if (raw == null) return const [];

      // Handle Laravel envelope { status, data: { data: [...] } }
      List<dynamic>? items;
      if (raw['status'] == 'success') {
        final inner = raw['data'];
        if (inner is Map && inner['data'] is List) {
          items = inner['data'] as List;
        } else if (inner is List) {
          items = inner;
        }
      } else if (raw['data'] is List) {
        items = raw['data'] as List;
      }

      if (items == null) return const [];

      return items
          .whereType<Map<String, dynamic>>()
          .map(AdBanner.fromJson)
          .where((b) => b.imageUrl != null && b.imageUrl!.isNotEmpty)
          .toList();
    } catch (_) {
      // Silently fail – ads are non-critical
      return const [];
    }
  }
}

// ─── Widget ───────────────────────────────────────────────────────────────────

/// A smooth auto-scrolling ad banner carousel.
/// Shows nothing when there are no active ads or when the fetch fails.
class AdBannerWidget extends ConsumerStatefulWidget {
  const AdBannerWidget({super.key, this.height = 110});

  final double height;

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _startAutoPlay(int count) {
    _autoPlayTimer?.cancel();
    if (count <= 1) return;
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final next = (_currentPage + 1) % count;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _openLink(String link) async {
    final uri = Uri.tryParse(link);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(adBannersProvider);

    return bannersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();

        // Start/restart auto-play when data arrives
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _startAutoPlay(banners.length);
        });

        return FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: widget.height,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: banners.length,
                  onPageChanged: (index) =>
                      setState(() => _currentPage = index),
                  itemBuilder: (context, index) {
                    final ad = banners[index];
                    return _AdCard(
                      ad: ad,
                      onTap: ad.link != null && ad.link!.isNotEmpty
                          ? () => _openLink(ad.link!)
                          : null,
                    );
                  },
                ),
              ),
              if (banners.length > 1) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(banners.length, (index) {
                    final active = index == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: active ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFEFAB00)
                            : const Color(0xFFCCC5A8),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

// ─── Ad Card ─────────────────────────────────────────────────────────────────

class _AdCard extends StatelessWidget {
  const _AdCard({required this.ad, this.onTap});

  final AdBanner ad;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Banner image
              Image.network(
                ad.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: const Color(0xFFF5F0E8),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFEFAB00),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: const Color(0xFFF5F0E8),
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: Color(0xFFBBB29A),
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
              // Subtle gradient overlay at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 32,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0x33000000)],
                    ),
                  ),
                ),
              ),
              // Clickable indicator
              if (onTap != null)
                Positioned(
                  bottom: 6,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.open_in_new_rounded,
                          color: Colors.white,
                          size: 11,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Ver mais',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
