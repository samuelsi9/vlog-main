
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vlog/Models/delivery_address_model.dart';
import 'package:vlog/presentation/screen/checkout_confirmation_page.dart';

const Color _primaryColor = Color(0xFFE53E3E);
const Color _primaryColorLight = Color(0xFFFC8181);
const Color _bgColor = Color(0xFFF7F7F7);
const Color _textDark = Color(0xFF2D3436);
const Color _textGrey = Color(0xFF636E72);

class PaymentMethodSelectionPage extends StatefulWidget {
  final DeliveryAddressModel selectedAddress;
  final DateTime initialDate;
  final String initialTimeSlot;

  const PaymentMethodSelectionPage({
    super.key,
    required this.selectedAddress,
    required this.initialDate,
    required this.initialTimeSlot,
  });

  @override
  State<PaymentMethodSelectionPage> createState() =>
      _PaymentMethodSelectionPageState();
}

class _PaymentMethodSelectionPageState
    extends State<PaymentMethodSelectionPage> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String formatDate(DateTime date) {
      final y = date.year;
      final m = date.month.toString().padLeft(2, '0');
      final d = date.day.toString().padLeft(2, '0');
      return '$y-$m-$d';
    }

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment Method',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Step indicator
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        _StepDot(
                          label: 'Address',
                          icon: Icons.home_outlined,
                          isDone: true,
                          isCurrent: false,
                        ),
                        const Expanded(child: _StepLine()),
                        _StepDot(
                          label: 'Delivery',
                          icon: Icons.schedule_outlined,
                          isDone: true,
                          isCurrent: false,
                        ),
                        const Expanded(child: _StepLine()),
                        _StepDot(
                          label: 'Payment',
                          icon: Icons.payment_outlined,
                          isDone: false,
                          isCurrent: true,
                        ),
                        const Expanded(child: _StepLine(fade: true)),
                        _StepDot(
                          label: 'Confirm',
                          icon: Icons.check_circle_outline,
                          isDone: false,
                          isCurrent: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ✅ Beautiful Lottie + Cash on Delivery hero card
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _primaryColor,
                          _primaryColorLight,
                          const Color(0xFFFF8A65),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Background decorative circles
                        Positioned(
                          top: -20,
                          right: -20,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.07),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: -30,
                          left: -10,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                        // Content
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // ✅ Lottie animation
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Lottie.asset(
                                  'assets/lottie/money.json',
                                  fit: BoxFit.contain,
                                  repeat: true,
                                  errorBuilder: (context, error, stack) =>
                                      const Icon(
                                    Icons.money_rounded,
                                    color: Colors.white,
                                    size: 48,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Text(
                                        'SELECTED METHOD',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Cash on\nDelivery',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                        height: 1.1,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Pay when your order arrives at your door',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info banner
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3CD),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFFE082),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: Color(0xFFF57F17), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'For now, we only support Cash on Delivery. More payment methods coming soon!',
                            style: TextStyle(
                              fontSize: 13,
                              color: const Color(0xFF5D4037),
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Delivery summary card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 20,
                              color: _primaryColor,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Order Summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: _textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                        // Address row
                        _SummaryRow(
                          icon: Icons.location_on,
                          iconBg: _primaryColor.withOpacity(0.1),
                          iconColor: _primaryColor,
                          title: widget.selectedAddress.label,
                          subtitle: widget.selectedAddress.buildingNumber
                                  .isNotEmpty
                              ? '${widget.selectedAddress.buildingNumber} ${widget.selectedAddress.street}'
                              : widget.selectedAddress.street,
                        ),
                        const SizedBox(height: 12),
                        // Time slot row
                        _SummaryRow(
                          icon: Icons.schedule,
                          iconBg: Colors.blue.withOpacity(0.1),
                          iconColor: Colors.blue[700]!,
                          title: formatDate(widget.initialDate),
                          subtitle: widget.initialTimeSlot,
                        ),
                        const SizedBox(height: 12),
                        // Payment row
                        _SummaryRow(
                          icon: Icons.payments_outlined,
                          iconBg: Colors.green.withOpacity(0.1),
                          iconColor: Colors.green[700]!,
                          title: 'Cash on Delivery',
                          subtitle: 'Pay when delivered',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_primaryColor, _primaryColorLight],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            // ✅ Logic unchanged
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CheckoutConfirmationPage(
                                  selectedAddress: widget.selectedAddress,
                                  initialDate: widget.initialDate,
                                  initialTimeSlot: widget.initialTimeSlot,
                                ),
                              ),
                            );
                          },
                          child: const Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Continue to checkout',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded,
                                    color: Colors.white, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ✅ New summary row widget
class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _SummaryRow({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: _textGrey,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isDone;
  final bool isCurrent;

  const _StepDot({
    required this.label,
    required this.icon,
    required this.isDone,
    required this.isCurrent,
  });

  @override
  Widget build(BuildContext context) {
    final Color dotColor;
    final Color iconColor;

    if (isCurrent) {
      dotColor = _primaryColor;
      iconColor = Colors.white;
    } else if (isDone) {
      dotColor = _primaryColor.withOpacity(0.35);
      iconColor = _primaryColor;
    } else {
      dotColor = Colors.grey[300]!;
      iconColor = Colors.grey[700]!;
    }

    return SizedBox(
      width: 72,
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: dotColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: isCurrent ? _primaryColor : Colors.grey[600],
              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepLine extends StatelessWidget {
  final bool fade;

  const _StepLine({this.fade = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          color: fade ? Colors.grey[200] : _primaryColor.withOpacity(0.35),
        ),
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:vlog/Models/delivery_address_model.dart';
// import 'package:vlog/presentation/screen/checkout_confirmation_page.dart';

// const Color _primaryColor = Color(0xFFE53E3E);
// const Color _primaryColorLight = Color(0xFFFC8181);
// const Color _bgColor = Color(0xFFF7F7F7);
// const Color _textDark = Color(0xFF2D3436);
// const Color _textGrey = Color(0xFF636E72);

// // This screen is only informational for now.
// // It keeps your API/payment logic in CheckoutConfirmationPage unchanged.
// class PaymentMethodSelectionPage extends StatelessWidget {
//   final DeliveryAddressModel selectedAddress;
//   final DateTime initialDate;
//   final String initialTimeSlot;

//   const PaymentMethodSelectionPage({
//     super.key,
//     required this.selectedAddress,
//     required this.initialDate,
//     required this.initialTimeSlot,
//   });

//   @override
//   Widget build(BuildContext context) {
//     String formatDate(DateTime date) {
//       final y = date.year;
//       final m = date.month.toString().padLeft(2, '0');
//       final d = date.day.toString().padLeft(2, '0');
//       return '$y-$m-$d';
//     }

//     return Scaffold(
//       backgroundColor: _bgColor,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         automaticallyImplyLeading: false,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Payment Method',
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.w800,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // Step indicator
//               Container(
//                 padding: const EdgeInsets.all(14),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(18),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.04),
//                       blurRadius: 10,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: Column(
//                   children: [
//                     Row(
//                       children: [
//                         _StepDot(
//                           label: 'Address',
//                           icon: Icons.home_outlined,
//                           isDone: true,
//                           isCurrent: false,
//                         ),
//                         const Expanded(child: _StepLine()),
//                         _StepDot(
//                           label: 'Delivery',
//                           icon: Icons.schedule_outlined,
//                           isDone: true,
//                           isCurrent: false,
//                         ),
//                         const Expanded(child: _StepLine()),
//                         _StepDot(
//                           label: 'Payment',
//                           icon: Icons.payment_outlined,
//                           isDone: false,
//                           isCurrent: true,
//                         ),
//                         const Expanded(child: _StepLine(fade: true)),
//                         _StepDot(
//                           label: 'Confirm',
//                           icon: Icons.check_circle_outline,
//                           isDone: false,
//                           isCurrent: false,
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),

//               // Cash on Delivery card
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(18),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.04),
//                       blurRadius: 10,
//                       offset: const Offset(0, 4),
//                     ),
//                   ],
//                 ),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Container(
//                       width: 48,
//                       height: 48,
//                       decoration: BoxDecoration(
//                         color: _primaryColor.withOpacity(0.12),
//                         borderRadius: BorderRadius.circular(16),
//                       ),
//                       child: Icon(Icons.money_rounded,
//                           color: _primaryColor, size: 26),
//                     ),
//                     const SizedBox(width: 14),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           const Text(
//                             'Cash on Delivery',
//                             style: TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.w800,
//                               color: _textDark,
//                             ),
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             'For now, we only support Cash on Delivery.',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: _textGrey,
//                               height: 1.5,
//                             ),
//                           ),
//                           const SizedBox(height: 10),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                                 horizontal: 12, vertical: 8),
//                             decoration: BoxDecoration(
//                               color: _primaryColor.withOpacity(0.06),
//                               borderRadius: BorderRadius.circular(14),
//                               border: Border.all(
//                                 color: _primaryColor.withOpacity(0.15),
//                               ),
//                             ),
//                             child: const Text(
//                               'You will pay in cash when your order is delivered.',
//                               style: TextStyle(
//                                 fontSize: 13,
//                                 fontWeight: FontWeight.w600,
//                                 color: _textDark,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 16),

//               // Delivery summary card
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(18),
//                   border: Border.all(color: Colors.grey[200]!),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(
//                           Icons.location_on_outlined,
//                           size: 20,
//                           color: _primaryColor,
//                         ),
//                         const SizedBox(width: 8),
//                         const Text(
//                           'Delivery summary',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w800,
//                             color: _textDark,
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 14),
//                     Row(
//                       children: [
//                         Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             color: _primaryColor.withOpacity(0.12),
//                             borderRadius: BorderRadius.circular(14),
//                           ),
//                           child: const Icon(Icons.location_on,
//                               color: _primaryColor, size: 22),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 selectedAddress.label,
//                                 style: const TextStyle(
//                                   fontSize: 14,
//                                   fontWeight: FontWeight.w800,
//                                   color: _textDark,
//                                 ),
//                               ),
//                               const SizedBox(height: 4),
//                               Text(
//                                 selectedAddress.buildingNumber.isNotEmpty
//                                     ? '${selectedAddress.buildingNumber} ${selectedAddress.street}'
//                                     : selectedAddress.street,
//                                 maxLines: 2,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: TextStyle(
//                                   fontSize: 13,
//                                   color: _textGrey,
//                                   height: 1.35,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 12),
//                     Row(
//                       children: [
//                         Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             color: _primaryColor.withOpacity(0.12),
//                             borderRadius: BorderRadius.circular(14),
//                           ),
//                           child: const Icon(Icons.schedule,
//                               color: _primaryColor, size: 22),
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Text(
//                             '${formatDate(initialDate)} • $initialTimeSlot',
//                             style: const TextStyle(
//                               fontSize: 14,
//                               fontWeight: FontWeight.w700,
//                               color: _textDark,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 22),

//               // Continue button
//               SizedBox(
//                 width: double.infinity,
//                 height: 56,
//                 child: DecoratedBox(
//                   decoration: BoxDecoration(
//                     gradient: LinearGradient(
//                       colors: [_primaryColor, _primaryColorLight],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(16),
//                     boxShadow: [
//                       BoxShadow(
//                         color: _primaryColor.withOpacity(0.35),
//                         blurRadius: 14,
//                         offset: const Offset(0, 6),
//                       ),
//                     ],
//                   ),
//                   child: Material(
//                     color: Colors.transparent,
//                     borderRadius: BorderRadius.circular(16),
//                     child: InkWell(
//                       borderRadius: BorderRadius.circular(16),
//                       onTap: () {
//                         Navigator.pushReplacement(
//                           context,
//                           MaterialPageRoute(
//                             builder: (_) => CheckoutConfirmationPage(
//                               selectedAddress: selectedAddress,
//                               initialDate: initialDate,
//                               initialTimeSlot: initialTimeSlot,
//                             ),
//                           ),
//                         );
//                       },
//                       child: const Center(
//                         child: Text(
//                           'Continue to checkout',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.w900,
//                             color: Colors.white,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _StepDot extends StatelessWidget {
//   final String label;
//   final IconData icon;
//   final bool isDone;
//   final bool isCurrent;

//   const _StepDot({
//     required this.label,
//     required this.icon,
//     required this.isDone,
//     required this.isCurrent,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final Color dotColor;
//     final Color iconColor;

//     if (isCurrent) {
//       dotColor = _primaryColor;
//       iconColor = Colors.white;
//     } else if (isDone) {
//       dotColor = _primaryColor.withOpacity(0.35);
//       iconColor = _primaryColor;
//     } else {
//       dotColor = Colors.grey[300]!;
//       iconColor = Colors.grey[700]!;
//     }

//     return SizedBox(
//       width: 72,
//       child: Column(
//         children: [
//           Container(
//             width: 34,
//             height: 34,
//             decoration: BoxDecoration(
//               color: dotColor,
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Icon(icon, size: 18, color: iconColor),
//           ),
//           const SizedBox(height: 6),
//           Text(
//             label,
//             maxLines: 1,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               fontSize: 11,
//               color: isCurrent ? _primaryColor : Colors.grey[600],
//               fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _StepLine extends StatelessWidget {
//   final bool fade;

//   const _StepLine({this.fade = false});

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 6),
//       child: Container(
//         height: 2,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(2),
//           color: fade ? Colors.grey[200] : _primaryColor.withOpacity(0.35),
//         ),
//       ),
//     );
//   }
// }

