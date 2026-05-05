import 'package:flutter/material.dart';
import 'package:modern_go/core/constants/app_colors.dart';

/// Green curved header with search bar — matches the design screenshot.
class HomeHeader extends StatelessWidget {
  final VoidCallback? onSearchTap;

  const HomeHeader({super.key, this.onSearchTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Green background with curved bottom
        ClipPath(
          clipper: _CurvedClipper(),
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
            child: const SizedBox.shrink(),
          ),
        ),

        // Search bar
        Positioned(
          left: 20,
          right: 20,
          top: MediaQuery.of(context).padding.top + 48,
          child: GestureDetector(
            onTap: onSearchTap,
            child: Container(
              height: 52,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: AppColors.primary,
                    size: 26,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Search products & stores',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom clipper for the curved bottom edge of the green header.
class _CurvedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 10,
      size.width,
      size.height - 50,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
