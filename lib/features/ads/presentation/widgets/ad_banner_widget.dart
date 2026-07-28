import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../data/ads_repository.dart';
import '../../domain/ad.dart';
import '../providers/ads_providers.dart';
import 'ad_link_launcher.dart';

/// Carrossel de banners de anúncio com autoplay.
///
/// Consome [adsProvider] para o [placement]/[role] informados e não renderiza
/// nada quando não há anúncios ou quando a busca falha. A impressão é
/// registrada 1× por anúncio por sessão por placement (dedup no repository).
class AdBannerWidget extends ConsumerStatefulWidget {
  const AdBannerWidget({
    super.key,
    required this.placement,
    required this.role,
    this.height = 110,
  });

  final String placement;
  final AdRole role;
  final double height;

  @override
  ConsumerState<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends ConsumerState<AdBannerWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final PageController _pageController;
  Timer? _autoPlayTimer;
  int _currentPage = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  AdQuery get _query => (placement: widget.placement, role: widget.role);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
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
    WidgetsBinding.instance.removeObserver(this);
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      ref.invalidate(adsProvider(_query));
    }
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

  void _trackImpression(Ad ad) {
    ref
        .read(adsRepositoryProvider)
        .trackImpression(
          ad.id,
          placement: widget.placement,
          surface: AdFormat.banner.wireValue,
        );
  }

  Future<void> _onAdTapped(Ad ad) async {
    await ref
        .read(adsRepositoryProvider)
        .trackClick(
          ad.id,
          placement: widget.placement,
          surface: AdFormat.banner.wireValue,
        );
    await openAdLink(ad.linkUrl!);
  }

  @override
  Widget build(BuildContext context) {
    final adsAsync = ref.watch(adsProvider(_query));

    return adsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (ads) {
        final banners = ads
            .where((ad) => ad.format != AdFormat.card)
            .toList(growable: false);
        if (banners.isEmpty) return const SizedBox.shrink();

        // Start/restart auto-play when data arrives
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _startAutoPlay(banners.length);
            _trackImpression(banners[_currentPage % banners.length]);
          }
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
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                    _trackImpression(banners[index]);
                  },
                  itemBuilder: (context, index) {
                    final ad = banners[index];
                    return _AdBannerCard(
                      ad: ad,
                      onTap: ad.isClickable ? () => _onAdTapped(ad) : null,
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
                        color: active ? AppColors.yellow : AppColors.muted,
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

class _AdBannerCard extends StatelessWidget {
  const _AdBannerCard({required this.ad, this.onTap});

  final Ad ad;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Banner image
              Image.network(
                ad.resolvedImageUrl ?? ad.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: AppColors.surfaceSoft,
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.yellow,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.surfaceSoft,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.muted,
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
                      colors: [Colors.transparent, AppColors.shadowMedium],
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
