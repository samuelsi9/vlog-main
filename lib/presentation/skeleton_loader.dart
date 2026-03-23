
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class HomeSkeletonLoader extends StatelessWidget {
  const HomeSkeletonLoader({super.key});

  static const Color _appBarColor = Color(0xFF1E3A5F);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // ── App bar skeleton (matches real app bar) ──
          Container(
            decoration: BoxDecoration(
              color: _appBarColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).padding.top),
                // Welcome row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            _shimmer(_buildBox(20, 20, radius: 10)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _shimmer(_buildBox(60, 10)),
                                const SizedBox(height: 4),
                                _shimmer(_buildBox(120, 14)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _shimmer(_buildBox(38, 38, radius: 19)),
                    ],
                  ),
                ),
                // Search bar skeleton
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: _shimmer(
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Scrollable content ──
          Expanded(
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Category title ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: _shimmer(_buildBox(160, 20)),
                  ),

                  // ── Category circles ──
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      children: List.generate(5, (index) {
                        return Padding(
                          padding: EdgeInsets.only(left: index == 0 ? 16 : 12),
                          child: Column(
                            children: [
                              _shimmer(_buildBox(80, 80, radius: 12)),
                              const SizedBox(height: 8),
                              _shimmer(_buildBox(60, 12)),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Banner skeleton ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _shimmer(_buildBox(size.width - 32, 180, radius: 20)),
                  ),

                  const SizedBox(height: 12),

                  // ── Banner dots ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (i) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: _shimmer(_buildBox(8, 8, radius: 4)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Featured deals title ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _shimmer(_buildBox(180, 22)),
                  ),

                  const SizedBox(height: 12),

                  // ── Products grid ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.70,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: 6,
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Image placeholder
                              _shimmer(
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                  child: Container(
                                    height: 118,
                                    width: double.infinity,
                                    color: Colors.grey[300],
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        _shimmer(_buildBox(70, 15)),
                                        _shimmer(_buildBox(34, 34, radius: 10)),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    _shimmer(_buildBox(double.infinity, 13)),
                                    const SizedBox(height: 4),
                                    _shimmer(_buildBox(80, 11)),
                                    const SizedBox(height: 6),
                                    _shimmer(_buildBox(60, 18, radius: 6)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _shimmer(Widget child) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: child,
    );
  }

  Widget _buildBox(double width, double height, {double radius = 8}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:shimmer/shimmer.dart';

// /// Home screen skeleton loader that displays shimmer loading placeholders
// /// matching the layout of the actual home screen.
// ///
// /// Used during app initialization to provide visual feedback while data loads.
// class HomeSkeletonLoader extends StatelessWidget {
//   const HomeSkeletonLoader({super.key});

//   @override
//   Widget build(BuildContext context) {
//     Size size = MediaQuery.of(context).size;
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SingleChildScrollView(
//         child: Column(
//           children: [
//             const SizedBox(height: 50),
//             // Header skeleton
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   _buildSkeletonBox(70, 70, BoxShape.rectangle),
//                   _buildSkeletonBox(28, 28, BoxShape.circle),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//             // Banner skeleton
//             _buildSkeletonBox(
//               size.width,
//               size.height * 0.23,
//               BoxShape.rectangle,
//             ),
//             // Category section title skeleton
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   _buildSkeletonBox(150, 20, BoxShape.rectangle),
//                   _buildSkeletonBox(60, 20, BoxShape.rectangle),
//                 ],
//               ),
//             ),
//             // Category circles skeleton
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: List.generate(
//                   5,
//                   (index) => Padding(
//                     padding: EdgeInsets.only(
//                       left: index == 0 ? 20 : 16,
//                       right: index == 4 ? 20 : 0,
//                     ),
//                     child: Column(
//                       children: [
//                         _buildSkeletonBox(60, 60, BoxShape.circle),
//                         const SizedBox(height: 10),
//                         _buildSkeletonBox(50, 16, BoxShape.rectangle),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//             // Curated section title skeleton
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   _buildSkeletonBox(150, 20, BoxShape.rectangle),
//                   _buildSkeletonBox(60, 20, BoxShape.rectangle),
//                 ],
//               ),
//             ),
//             // Curated items skeleton
//             SingleChildScrollView(
//               scrollDirection: Axis.horizontal,
//               child: Row(
//                 children: List.generate(
//                   3,
//                   (index) => Padding(
//                     padding: EdgeInsets.only(left: index == 0 ? 20 : 20),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         _buildSkeletonBox(
//                           size.width * 0.5,
//                           size.height * 0.25,
//                           BoxShape.rectangle,
//                         ),
//                         const SizedBox(height: 7),
//                         _buildSkeletonBox(
//                           size.width * 0.5,
//                           16,
//                           BoxShape.rectangle,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSkeletonBox(double width, double height, BoxShape shape) {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.grey[100]!,
//       child: Container(
//         width: width,
//         height: height,
//         decoration: BoxDecoration(
//           color: Colors.grey[300],
//           shape: shape,
//           borderRadius: shape == BoxShape.rectangle
//               ? BorderRadius.circular(8)
//               : null,
//         ),
//       ),
//     );
//   }
// }

// /// Individual skeleton loader widget for specific components.
// ///
// /// A flexible skeleton widget that can be customized with width, height, and border radius.
// /// Example usage:
// /// ```dart
// /// SkeletonLoader(width: 100, height: 50, borderRadius: 8)
// /// ```
// class SkeletonLoader extends StatelessWidget {
//   final double? width;
//   final double? height;
//   final double? borderRadius;

//   const SkeletonLoader({super.key, this.width, this.height, this.borderRadius});

//   @override
//   Widget build(BuildContext context) {
//     return Shimmer.fromColors(
//       baseColor: Colors.grey[300]!,
//       highlightColor: Colors.grey[100]!,
//       child: Container(
//         width: width,
//         height: height,
//         decoration: BoxDecoration(
//           color: Colors.grey[300],
//           borderRadius: BorderRadius.circular(borderRadius ?? 8),
//         ),
//       ),
//     );
//   }
// }
