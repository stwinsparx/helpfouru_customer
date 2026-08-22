import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'booking_screen.dart';

class ProviderProfileScreen extends StatelessWidget {
  const ProviderProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const MiniHeader(title: 'Provider Profile'),

            // Gradient cover with the overlapping avatar tile.
            SizedBox(
              height: 130,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: AppGradients.brand,
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  Positioned(
                    left: 17,
                    top: 62,
                    child: Container(
                      width: 68,
                      height: 68,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.white, width: 5),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Text(
                        'RK',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: AppColors.blueDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Rajesh Kumar',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink),
                ),
                const SizedBox(width: 8),
                const Pill(label: '✓ VERIFIED', fontSize: 9),
              ],
            ),
            const SizedBox(height: 5),
            const Text(
              'AC Specialist · 2.1 km away',
              style: TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 14),

            const Row(
              children: [
                _Stat(value: '4.9 ★', label: 'Rating'),
                SizedBox(width: 8),
                _Stat(value: '128+', label: 'Jobs'),
                SizedBox(width: 8),
                _Stat(value: '6 yrs', label: 'Experience'),
              ],
            ),
            const SizedBox(height: 12),

            AppCard(
              radius: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('About Provider',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                  SizedBox(height: 8),
                  Text(
                    'Certified technician for split/window AC service, installation, repair and gas refill. Background verified by HelpFourU.',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.muted, height: 1.55),
                  ),
                ],
              ),
            ),

            AppCard(
              radius: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Services & Pricing',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w800)),
                  SizedBox(height: 4),
                  DetailRow(label: 'AC Service', value: '₹499'),
                  DetailRow(label: 'Deep Cleaning', value: '₹899'),
                  DetailRow(
                      label: 'Gas Refill',
                      value: '₹1,799',
                      showDivider: false),
                ],
              ),
            ),
            const SizedBox(height: 6),

            PrimaryButton(
              label: 'Book Rajesh Kumar',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BookingScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.line),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 10.5, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
