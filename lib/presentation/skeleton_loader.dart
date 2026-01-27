import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Home screen skeleton loader that displays shimmer loading placeholders
/// matching the layout of the actual home screen.
///
/// Used during app initialization to provide visual feedback while data loads.
class HomeSkeletonLoader extends StatelessWidget {
  const HomeSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 50),
            // Header skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSkeletonBox(70, 70, BoxShape.rectangle),
                  _buildSkeletonBox(28, 28, BoxShape.circle),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Banner skeleton
            _buildSkeletonBox(
              size.width,
              size.height * 0.23,
              BoxShape.rectangle,
            ),
            // Category section title skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSkeletonBox(150, 20, BoxShape.rectangle),
                  _buildSkeletonBox(60, 20, BoxShape.rectangle),
                ],
              ),
            ),
            // Category circles skeleton
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  5,
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      left: index == 0 ? 20 : 16,
                      right: index == 4 ? 20 : 0,
                    ),
                    child: Column(
                      children: [
                        _buildSkeletonBox(60, 60, BoxShape.circle),
                        const SizedBox(height: 10),
                        _buildSkeletonBox(50, 16, BoxShape.rectangle),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Curated section title skeleton
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSkeletonBox(150, 20, BoxShape.rectangle),
                  _buildSkeletonBox(60, 20, BoxShape.rectangle),
                ],
              ),
            ),
            // Curated items skeleton
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(
                  3,
                  (index) => Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 20 : 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSkeletonBox(
                          size.width * 0.5,
                          size.height * 0.25,
                          BoxShape.rectangle,
                        ),
                        const SizedBox(height: 7),
                        _buildSkeletonBox(
                          size.width * 0.5,
                          16,
                          BoxShape.rectangle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonBox(double width, double height, BoxShape shape) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          shape: shape,
          borderRadius: shape == BoxShape.rectangle
              ? BorderRadius.circular(8)
              : null,
        ),
      ),
    );
  }
}

/// Individual skeleton loader widget for specific components.
///
/// A flexible skeleton widget that can be customized with width, height, and border radius.
/// Example usage:
/// ```dart
/// SkeletonLoader(width: 100, height: 50, borderRadius: 8)
/// ```
class SkeletonLoader extends StatelessWidget {
  final double? width;
  final double? height;
  final double? borderRadius;

  const SkeletonLoader({super.key, this.width, this.height, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(borderRadius ?? 8),
        ),
      ),
    );
  }
}
