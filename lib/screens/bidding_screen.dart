import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class BiddingScreen extends StatefulWidget {
  const BiddingScreen({super.key});

  @override
  State<BiddingScreen> createState() => _BiddingScreenState();
}

class _BiddingScreenState extends State<BiddingScreen> {
  static const _categories = [
    'Electrician',
    'Plumber',
    'AC Repair',
    'Painting',
    'Carpenter',
  ];
  String _category = 'Electrician';
  final _date = TextEditingController();

  @override
  void dispose() {
    _date.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      _date.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.screenBg,
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            const Text(
              'Publish a Bidding Request',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                gradient: AppGradients.banner,
                borderRadius: BorderRadius.circular(17),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Let providers compete for your job',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Describe your requirement, set a preferred budget and receive offers from nearby verified professionals.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.5,
                      color: Color(0xD9FFFFFF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            AppCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Service Category',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFDCE5ED)),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _category,
                        isExpanded: true,
                        items: _categories
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _category = v ?? _category),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            AppCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'What do you need?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    maxLines: 4,
                    decoration: appInputDecoration(
                      'Example: Need complete kitchen electrical rewiring...',
                    ),
                  ),
                ],
              ),
            ),

            AppCard(
              margin: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Budget & Schedule',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  LabeledField(
                    label: 'EXPECTED BUDGET',
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: appInputDecoration('₹ e.g. 2500'),
                    ),
                  ),
                  LabeledField(
                    label: 'PREFERRED DATE',
                    child: TextField(
                      controller: _date,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: appInputDecoration('Select a date').copyWith(
                        suffixIcon: const FaIcon(
                          FontAwesomeIcons.calendar,
                          size: 15,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            PrimaryButton(
              label: 'Publish Request',
              onTap: () => showAppToast(
                context,
                'Bidding request published. Providers can now send offers.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
