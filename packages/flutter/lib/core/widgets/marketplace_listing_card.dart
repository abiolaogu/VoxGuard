import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';
import '../animations/loading_animations.dart';

/// Beautiful marketplace listing card
class MarketplaceListingCard extends StatefulWidget {
  final String id;
  final String title;
  final String? description;
  final double price;
  final String currency;
  final String? imageUrl;
  final List<String>? images;
  final String? location;
  final String? sellerName;
  final bool isFavorite;
  final bool isDiasporaFriendly;
  final int? views;
  final DateTime? createdAt;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final CardSize size;

  const MarketplaceListingCard({
    super.key,
    required this.id,
    required this.title,
    this.description,
    required this.price,
    this.currency = 'NGN',
    this.imageUrl,
    this.images,
    this.location,
    this.sellerName,
    this.isFavorite = false,
    this.isDiasporaFriendly = false,
    this.views,
    this.createdAt,
    this.onTap,
    this.onFavorite,
    this.size = CardSize.medium,
  });

  @override
  State<MarketplaceListingCard> createState() => _MarketplaceListingCardState();
}

class _MarketplaceListingCardState extends State<MarketplaceListingCard> {
  bool _isPressed = false;

  double get _imageHeight {
    switch (widget.size) {
      case CardSize.small:
        return 100;
      case CardSize.medium:
        return 140;
      case CardSize.large:
        return 180;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()..scale(_isPressed ? 0.98 : 1.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusLg),
          boxShadow: _isPressed ? AppTheme.shadowSm : AppTheme.shadowMd,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            _buildImageSection(),

            // Content section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Price
                  _buildPrice(),
                  const SizedBox(height: 6),

                  // Title
                  Text(
                    widget.title,
                    style: AppTypography.titleSmall,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  if (widget.description != null &&
                      widget.size == CardSize.large) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.description!,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Location and meta
                  _buildMeta(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Stack(
      children: [
        // Main image
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLg),
          ),
          child: widget.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: widget.imageUrl!,
                  height: _imageHeight,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: _imageHeight,
                    color: AppColors.surfaceSecondary,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: _imageHeight,
                    color: AppColors.surfaceSecondary,
                    child: Icon(
                      Icons.image_not_supported,
                      color: AppColors.textTertiary,
                      size: 32,
                    ),
                  ),
                )
              : Container(
                  height: _imageHeight,
                  color: AppColors.surfaceSecondary,
                  child: Icon(
                    Icons.image,
                    color: AppColors.textTertiary,
                    size: 48,
                  ),
                ),
        ),

        // Favorite button
        Positioned(
          top: 8,
          right: 8,
          child: _buildFavoriteButton(),
        ),

        // Diaspora friendly badge
        if (widget.isDiasporaFriendly)
          Positioned(
            top: 8,
            left: 8,
            child: _buildDiasporaBadge(),
          ),

        // Image count indicator
        if (widget.images != null && widget.images!.length > 1)
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.photo_library,
                    size: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${widget.images!.length}',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onFavorite?.call();
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: AppTheme.shadowSm,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            widget.isFavorite ? Icons.favorite : Icons.favorite_border,
            key: ValueKey(widget.isFavorite),
            size: 20,
            color: widget.isFavorite ? AppColors.error : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildDiasporaBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.nigeriaGreen,
            AppColors.nairaGreen,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🇳🇬', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            'Diaspora',
            style: AppTypography.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrice() {
    return Row(
      children: [
        Text(
          widget.currency == 'NGN'
              ? CurrencyFormatter.formatNaira(widget.price, decimals: 0)
              : CurrencyFormatter.formatCurrency(widget.price, widget.currency),
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.nairaGreen,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (widget.currency == 'NGN')
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'NGN',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMeta() {
    return Row(
      children: [
        // Location
        if (widget.location != null) ...[
          Icon(
            Icons.location_on_outlined,
            size: 14,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 2),
          Expanded(
            child: Text(
              widget.location!,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],

        const Spacer(),

        // Views
        if (widget.views != null) ...[
          Icon(
            Icons.visibility_outlined,
            size: 14,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 2),
          Text(
            _formatViews(widget.views!),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ],
    );
  }

  String _formatViews(int views) {
    if (views >= 1000000) {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    } else if (views >= 1000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    }
    return views.toString();
  }
}

/// Card size options
enum CardSize {
  small,
  medium,
  large,
}

/// Grid listing card optimized for grids
class GridListingCard extends StatelessWidget {
  final String title;
  final double price;
  final String? imageUrl;
  final String? location;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;

  const GridListingCard({
    super.key,
    required this.title,
    required this.price,
    this.imageUrl,
    this.location,
    this.isFavorite = false,
    this.onTap,
    this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return MarketplaceListingCard(
      id: '',
      title: title,
      price: price,
      imageUrl: imageUrl,
      location: location,
      isFavorite: isFavorite,
      onTap: onTap,
      onFavorite: onFavorite,
      size: CardSize.medium,
    );
  }
}
