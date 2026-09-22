import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../models/service_category.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'payment_screen.dart';

/// "Review & Schedule" — fetches `GET /customer/service-detail/:serviceId`
/// to populate the service summary card, real add-ons and the total. Once a
/// date is picked, `GET /customer/providers/:providerId/booked-slots` marks
/// which slot chips are already taken for that provider on that date.
class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.serviceId});

  final int serviceId;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  static const _slots = [
    '9:00 AM',
    '10:00 AM',
    '11:30 AM',
    '1:00 PM',
    '3:00 PM',
    '5:30 PM',
  ];

  static const _slotEnd = {
    '9:00 AM': '10:00 AM',
    '10:00 AM': '11:00 AM',
    '11:30 AM': '12:30 PM',
    '1:00 PM': '2:00 PM',
    '3:00 PM': '4:00 PM',
    '5:30 PM': '6:30 PM',
  };

  final _apiService = ApiService();
  bool _isLoading = true;
  ServiceDetail? _service;
  List<ServiceAddOn> _addOns = const [];

  bool _isLoadingSlots = false;
  Set<String> _bookedSlots = const {};
  bool _isInstantBooking = false;

  /// Parses a slot's start time (e.g. `'11:30 AM'`) into minutes-since-
  /// midnight, for comparing against the current time.
  static int _slotStartMinutes(String slot) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(AM|PM)$',
    ).firstMatch(slot.trim());
    if (match == null) return 0;
    var hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    final period = match.group(3)!;
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  /// True when [slot] starts today and its start time has already gone by —
  /// only ever true for today's date, since every other bookable date is
  /// entirely in the future.
  bool _isSlotPast(String slot) {
    final date = AppStateScope.of(context).bookingDate;
    if (date == null) return false;
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    if (!isToday) return false;
    return _slotStartMinutes(slot) <= now.hour * 60 + now.minute;
  }

  @override
  void initState() {
    super.initState();
    _fetchServiceDetail();
  }

  Future<void> _pickDate() async {
    final state = AppStateScope.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: state.bookingDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 60)),
    );
    if (picked == null || !mounted) return;
    state.selectDate(picked);
    await _fetchBookedSlots();
  }

  /// Selects today's date and the nearest slot that's neither already past
  /// nor already booked for this provider, then selects it — one tap to
  /// the earliest bookable moment instead of picking a date and slot by
  /// hand.
  Future<void> _instantBook() async {
    final l10n = AppLocalizations.of(context);
    final state = AppStateScope.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    setState(() => _isInstantBooking = true);
    state.selectDate(today);
    await _fetchBookedSlots();
    if (!mounted) return;

    final nowMinutes = now.hour * 60 + now.minute;
    final available =
        _slots
            .where((slot) => !_bookedSlots.contains(_fullSlot(slot)))
            .where((slot) => _slotStartMinutes(slot) > nowMinutes)
            .toList()
          ..sort(
            (a, b) => _slotStartMinutes(a).compareTo(_slotStartMinutes(b)),
          );

    setState(() => _isInstantBooking = false);
    if (available.isEmpty) {
      if (mounted) showAppToast(context, l10n.noSlotsLeftTodayToast);
      return;
    }
    state.selectSlot(_fullSlot(available.first));
  }

  String _fullSlot(String slot) => '$slot - ${_slotEnd[slot] ?? '11:00 AM'}';

  Future<void> _fetchBookedSlots() async {
    final state = AppStateScope.of(context);
    final providerId = state.bookingProviderId;
    final bookingDate = state.bookingDateApiValue;
    if (providerId == null || bookingDate == null) return;

    setState(() {
      _isLoadingSlots = true;
      _bookedSlots = const {};
    });
    try {
      final response = await _apiService.get(
        '/customer/providers/$providerId/booked-slots',
        queryParameters: {'booking_date': bookingDate},
      );
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        final booked = BookedSlots.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        if (mounted) setState(() => _bookedSlots = booked.slots.toSet());
      }
    } catch (e) {
      debugPrint('Booked slots API error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSlots = false);
    }
  }

  static const _weekdayNames = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  static const _monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _formatDate(DateTime date) =>
      '${_weekdayNames[date.weekday - 1]}, '
      '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

  Future<void> _fetchServiceDetail() async {
    try {
      final response = await _apiService.get(
        '/customer/service-detail/${widget.serviceId}',
      );
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        final result = ServiceDetailResult.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
        if (mounted) {
          final state = AppStateScope.of(context);
          // This service's add-ons replace whatever was left over from a
          // previous booking — AppState.addons is a single shared list, not
          // scoped per-service.
          state.clearAddons();
          setState(() {
            _service = result.service;
            _addOns = result.addOns;
          });
          state.setBookingAmount(result.service.amount);
          state.bookingServiceId = result.service.id;
          state.bookingProviderId = result.service.providerId;
        }
      }
    } catch (e) {
      debugPrint('Service detail API error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final l10n = AppLocalizations.of(context);
    final service = _service;

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isInstantBooking ? null : _instantBook,
        backgroundColor: AppColors.green,
        icon: _isInstantBooking
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.flash_on, size: 18, color: Colors.white),
        label: Text(
          l10n.instantBooking,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12.5,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            MiniHeader(title: l10n.reviewAndSchedule),

            // Service summary.
            AppCard(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service?.displayLabel ??
                                        localizedServiceName(
                                          context,
                                          state.sub,
                                        ),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    service?.providerName != null
                                        ? (service!.isVerifiedProvider
                                              ? l10n.providerNameVerified(
                                                  service.providerName!,
                                                )
                                              : l10n.providerNameOnly(
                                                  service.providerName!,
                                                ))
                                        : l10n.verifiedProDistance,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              service?.displayPrice ?? '₹${state.amount}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        if (service?.additionalDetail != null &&
                            service!.additionalDetail!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            service.additionalDetail!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.muted,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ],
                    ),
            ),

            // Add-ons.
            if (_isLoading)
              const AppCard(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_addOns.isNotEmpty)
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.recommendedAddons,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    for (final addOn in _addOns)
                      _AddOnRow(
                        addOn: addOn,
                        added: state.hasAddon(addOn.itemName),
                        isLast: addOn == _addOns.last,
                        onTap: () => state.toggleAddon(
                          Addon(
                            addOn.itemName,
                            addOn.price,
                            id: addOn.id,
                            source: addOn,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

            // Date picker.
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.selectBookingDate,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: AppColors.line),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: AppColors.greenDark,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            state.bookingDate != null
                                ? _formatDate(state.bookingDate!)
                                : l10n.tapToChooseDate,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: state.bookingDate != null
                                  ? AppColors.ink
                                  : AppColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Slot picker.
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.selectBookingSlot,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (state.bookingDate == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n.pickDateFirstHint,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    )
                  else if (_isLoadingSlots)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _slots.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 2.6,
                          ),
                      itemBuilder: (_, i) {
                        final slot = _slots[i];
                        final fullSlot = _fullSlot(slot);
                        final selected = state.slot == fullSlot;
                        final isBooked = _bookedSlots.contains(fullSlot);
                        final isPast = _isSlotPast(slot);
                        final isDisabled = isBooked || isPast;
                        return GestureDetector(
                          onTap: !isDisabled
                              ? () => state.selectSlot(fullSlot)
                              : () => showAppToast(
                                  context,
                                  l10n.slotUnavailableToast,
                                ),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isDisabled
                                  ? const Color(0xFFF2F4F6)
                                  : (selected ? AppColors.mint : Colors.white),
                              border: Border.all(
                                color: isDisabled
                                    ? const Color(0xFFE2E6EA)
                                    : (selected
                                          ? const Color(0xFFC5EBD8)
                                          : AppColors.line),
                              ),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  slot,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selected
                                        ? FontWeight.w800
                                        : FontWeight.w600,
                                    color: isDisabled
                                        ? const Color(0xFFA6AEB6)
                                        : (selected
                                              ? AppColors.greenDark
                                              : AppColors.ink),
                                    decoration: isDisabled
                                        ? TextDecoration.lineThrough
                                        : TextDecoration.none,
                                  ),
                                ),
                                if (isPast && !isBooked)
                                  Text(
                                    l10n.slotPassedLabel,
                                    style: const TextStyle(
                                      fontSize: 8.5,
                                      color: Color(0xFFA6AEB6),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),

            // Totals.
            AppCard(
              child: Column(
                children: [
                  DetailRow(
                    label: l10n.serviceLabel,
                    value: '₹${state.amount}',
                  ),
                  DetailRow(
                    label: l10n.addonsLabel,
                    value: '₹${state.addonsTotal}',
                    showDivider: false,
                  ),
                  TotalRow(label: l10n.totalLabel, value: '₹${state.subtotal}'),
                ],
              ),
            ),
            const SizedBox(height: 6),

            PrimaryButton(
              label: l10n.proceedToPayment(state.subtotal),
              onTap: (state.bookingDate == null || state.slot.isEmpty)
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const PaymentScreen()),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A single selectable add-on row within the "Recommended Add-ons" card.
class _AddOnRow extends StatelessWidget {
  const _AddOnRow({
    required this.addOn,
    required this.added,
    required this.isLast,
    required this.onTap,
  });

  final ServiceAddOn addOn;
  final bool added;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final details = [
      if (addOn.displayQuantity != null) addOn.displayQuantity!,
      if (addOn.displayWarranty != null)
        l10n.warrantyDurationLabel(addOn.displayWarranty!),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEDF1F4))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(color: AppColors.ink),
                    children: [
                      TextSpan(
                        text: addOn.itemName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: '  ·  ${addOn.displayPrice}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: added ? AppColors.greenDark : const Color(0xFFE6F7EF),
                border: Border.all(color: AppColors.mintBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                added ? l10n.added : l10n.add,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: added ? Colors.white : AppColors.greenDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
