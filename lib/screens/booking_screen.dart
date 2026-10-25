import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../core/services/device_info_service.dart';
import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../models/service_category.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/location_picker_sheet.dart';
import 'add_extra_service_screen.dart';
import 'payment_screen.dart';

/// "Review & Schedule" — fetches `GET /customer/service-detail/:serviceId`
/// to populate the service summary card, real add-ons and the total.
///
/// For a **Schedule** order ([isInstantOrder] `false`, the default — e.g.
/// reached from `ProviderProfileScreen`, which has no order-type context),
/// the customer picks a date, which fetches that date's bookable slots from
/// `GET /customer/slots` (admin-configured per zone — never hardcoded) and,
/// alongside it, `GET /customer/providers/:providerId/booked-slots` to mark
/// which of those slots are already taken for this provider.
///
/// For an **Instant** order (picked on `ProvidersScreen`), there's nothing
/// to pick: `GET /customer/providers/:providerId/availability` is fetched
/// automatically once the provider is known, and its nearest slot is
/// applied straight away — no date/slot cards are shown at all, since the
/// whole point of Instant was already deciding "as soon as possible". If
/// that check comes back with nothing bookable soon, the screen falls back
/// to the normal manual date/slot picker rather than leaving the customer
/// stuck with no way to book.
///
/// NOTE: the availability endpoint isn't a confirmed backend contract yet
/// (see the "Instant vs Schedule API" spec) — a failed/404 call is treated
/// as "nothing available", which for a Schedule order just means no banner,
/// and for an Instant order means falling back to manual picking. The slot
/// it names is re-validated against the real `/customer/slots` list before
/// being applied, since the two contracts aren't guaranteed to agree on the
/// exact label string.
class BookingScreen extends StatefulWidget {
  const BookingScreen({
    super.key,
    required this.serviceId,
    this.isInstantOrder = false,
  });

  final int serviceId;

  /// True when this booking started from an Instant pick on
  /// `ProvidersScreen` — skips the manual date/slot cards in favor of
  /// auto-applying the provider's nearest available slot.
  final bool isInstantOrder;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;
  ServiceDetail? _service;
  List<ServiceAddOn> _addOns = const [];

  bool _isLoadingBookedSlots = false;
  Set<String> _bookedSlots = const {};

  /// Admin-configured, per-zone slots for the currently selected date, from
  /// `GET /customer/slots` — never hardcoded, since the set (and its count,
  /// including zero) can change at any time from the admin panel.
  bool _isLoadingSlots = false;
  List<BookingSlot> _bookingSlots = const [];
  String? _bookingSlotsError;

  /// Incremented on every `_fetchBookingSlots` call and captured by each
  /// request — a response is applied only if this still matches when it
  /// resolves, so switching dates quickly can't let a slower, older
  /// response overwrite a newer one ("ignore any response whose date isn't
  /// the currently selected date").
  int _bookingSlotsRequestId = 0;

  bool _isCheckingAvailability = false;
  ProviderAvailability? _availability;

  /// True once an Instant order's availability check comes back with
  /// nothing bookable soon — the screen then shows the normal manual
  /// date/slot cards instead of leaving the customer with nothing to do.
  bool _instantFellBackToManual = false;

  /// The device's live GPS address, shown on the delivery-address card when
  /// `AppState.selectedAddress` is `null` (i.e. "Use current location" is
  /// active) — same text the home screen shows, fetched independently here
  /// since this screen can be reached without having visited Home first in
  /// this session.
  String? _currentAddress;

  @override
  void initState() {
    super.initState();
    _fetchServiceDetail();
    _loadCurrentAddress();
  }

  Future<void> _loadCurrentAddress() async {
    final address = await DeviceInfoService.currentAddress();
    if (mounted) setState(() => _currentAddress = address);
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
    await Future.wait([_fetchBookingSlots(), _fetchBookedSlots()]);
  }

  /// Fetches the admin-configured slots for the currently selected date from
  /// `GET /customer/slots`. Guarded against races: if the date changes again
  /// before this resolves, the stale response is discarded rather than
  /// overwriting what the newer request will return. Clears the selected
  /// slot if its label isn't in the new list.
  ///
  /// NOTE: `zone_id` is intentionally omitted — this app has no zone concept
  /// yet (no field for it in `CurrentUser`/login, no zone-picker UI). Per
  /// the endpoint's own contract this is fine: the backend falls back to
  /// the `zone-id` request header, then the customer's saved zone, then
  /// default slots. Pass it here once the app has a real zone id to offer.
  Future<void> _fetchBookingSlots() async {
    final state = AppStateScope.of(context);
    final bookingDate = state.bookingDateApiValue;
    if (bookingDate == null) return;

    final requestId = ++_bookingSlotsRequestId;
    setState(() {
      _isLoadingSlots = true;
      _bookingSlotsError = null;
    });
    List<BookingSlot>? slots;
    String? errorMessage;
    try {
      final response = await _apiService.get(
        '/customer/slots',
        queryParameters: {'booking_date': bookingDate},
      );
      final isSuccess =
          response.data is Map && response.data['is_success'] == true;
      if (isSuccess) {
        slots = BookingSlotsResult.fromJson(
          response.data['data'] as Map<String, dynamic>,
        ).slots;
      } else {
        errorMessage = response.data is Map
            ? response.data['message'] as String?
            : null;
      }
    } catch (e) {
      debugPrint('Booking slots API error: $e');
    } finally {
      if (mounted && requestId == _bookingSlotsRequestId) {
        setState(() {
          _isLoadingSlots = false;
          if (slots != null) {
            _bookingSlots = slots;
            // The previously selected slot may no longer exist for this
            // date (or ever existed under a different zone's slot set).
            if (!slots.any((s) => s.label == state.slot)) {
              state.selectSlot('');
            }
          } else {
            _bookingSlots = const [];
            _bookingSlotsError =
                errorMessage ??
                AppLocalizations.of(context).somethingWentWrongTryAgain;
          }
        });
      }
    }
  }

  /// Fetches the provider's own availability answer, replacing the old
  /// client-side "Instant Booking" guess — called automatically once
  /// [AppState.bookingProviderId] is known. Any failure (the endpoint
  /// doesn't exist yet, a network error, an unexpected payload) leaves
  /// [_availability] `null` and is otherwise silent: the screen just
  /// behaves as it did before this feature existed.
  ///
  /// For [BookingScreen.isInstantOrder], the nearest slot this returns is
  /// applied immediately — no banner, no manual picker — since Instant
  /// already means "whatever's soonest". If nothing comes back bookable,
  /// [_instantFellBackToManual] is set so the screen falls back to showing
  /// the normal date/slot cards instead of leaving the customer stuck.
  Future<void> _checkAvailability(int providerId) async {
    setState(() {
      _isCheckingAvailability = true;
      _availability = null;
    });
    ProviderAvailability? availability;
    try {
      final response = await _apiService.get(
        '/customer/providers/$providerId/availability',
      );
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        availability = ProviderAvailability.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }
    } catch (e) {
      debugPrint('Provider availability API error: $e');
    } finally {
      // For an Instant order, keep the "checking…" loader up through
      // _useAvailableSlot's own booked-slots confirmation below — that call
      // also updates UI state (date/slot), and dropping the loader here
      // first would leave a blank gap between "no longer checking" and
      // "slot confirmed" with nothing on screen to show work is still
      // happening. A Schedule order has no such follow-up call, so its
      // loader always drops right here.
      final staysLoadingForInstant =
          widget.isInstantOrder &&
          availability?.nextAvailableAt != null &&
          availability?.nextAvailableSlot != null;
      if (mounted) {
        setState(() {
          _availability = availability;
          if (!staysLoadingForInstant) _isCheckingAvailability = false;
        });
      }
    }

    if (!widget.isInstantOrder || !mounted) return;
    if (availability?.nextAvailableAt == null ||
        availability?.nextAvailableSlot == null) {
      setState(() => _instantFellBackToManual = true);
      return;
    }
    // This Instant pick is actually going through — record it as the
    // effective booking type so PaymentScreen's platform-fee fetch and the
    // order-creation call both ask for the instant fee. If nothing bookable
    // comes back above, bookingType stays the AppState default (regular)
    // from clearBookingSchedule(), matching the manual-picking fallback.
    AppStateScope.of(context).setBookingType(BookingType.instant);
    await _useAvailableSlot();
    if (mounted) setState(() => _isCheckingAvailability = false);
  }

  /// Pre-selects the date/slot from [_availability]'s `next_available_at` /
  /// `next_available_slot` — the one-tap action on the availability banner,
  /// replacing the old Instant Booking button. Falls back to leaving the
  /// date/slot untouched if either field is missing (shouldn't happen for a
  /// banner that's showing, but handled defensively since the contract
  /// isn't confirmed yet).
  ///
  /// The availability endpoint's own `next_available_slot` string isn't
  /// guaranteed to match `/customer/slots`' label format character for
  /// character (different, unconfirmed contracts) — rather than trust it
  /// blindly and risk sending the backend a slot label it won't recognise,
  /// this re-fetches the real slot list for that date and only selects the
  /// slot if its label actually appears there.
  Future<void> _useAvailableSlot() async {
    final availability = _availability;
    final nextAt = availability?.nextAvailableAt;
    final nextSlot = availability?.nextAvailableSlot;
    if (nextAt == null || nextSlot == null) return;

    final state = AppStateScope.of(context);
    final local = nextAt.toLocal();
    state.selectDate(DateTime(local.year, local.month, local.day));
    await Future.wait([_fetchBookingSlots(), _fetchBookedSlots()]);
    if (!mounted) return;
    if (_bookingSlots.any((s) => s.label == nextSlot)) {
      state.selectSlot(nextSlot);
    }
  }

  Future<void> _fetchBookedSlots() async {
    final state = AppStateScope.of(context);
    final providerId = state.bookingProviderId;
    final bookingDate = state.bookingDateApiValue;
    if (providerId == null || bookingDate == null) return;

    setState(() {
      _isLoadingBookedSlots = true;
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
      if (mounted) setState(() => _isLoadingBookedSlots = false);
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
          // This service's add-ons/bundled extras/booking date&slot replace
          // whatever was left over from a previous booking — AppState's
          // booking fields are single shared fields, not scoped per-service,
          // so a stale date/slot from a different provider would otherwise
          // carry over and the slot grid would show booked-slots data that
          // doesn't even belong to this provider.
          state.clearAddons();
          state.clearExtraServices();
          state.clearBookingSchedule();
          setState(() {
            _service = result.service;
            _addOns = result.addOns;
            _bookedSlots = const {};
            _bookingSlots = const [];
            _bookingSlotsError = null;
            _availability = null;
            _instantFellBackToManual = false;
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
    final providerId = _service?.providerId;
    if (providerId != null) _checkAvailability(providerId);
  }

  /// Opens the "Add More Services" picker for this order's provider,
  /// excluding the currently-booked service and anything already bundled
  /// in so they can't be picked again. Adds the result to
  /// `AppState.extraServices`, which `PaymentScreen` turns into real
  /// sub-orders once the primary order's payment succeeds.
  Future<void> _addExtraService() async {
    final state = AppStateScope.of(context);
    final providerId = state.bookingProviderId;
    if (providerId == null) return;
    final excludeIds = {
      if (state.bookingServiceId != null) state.bookingServiceId!,
      for (final extra in state.extraServices) extra.serviceId,
    };
    final extra = await Navigator.of(context).push<ExtraService>(
      MaterialPageRoute(
        builder: (_) => AddExtraServiceScreen(
          providerId: providerId,
          excludeServiceIds: excludeIds,
        ),
      ),
    );
    if (extra != null) state.addExtraService(extra);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    final l10n = AppLocalizations.of(context);
    final service = _service;

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            MiniHeader(title: l10n.reviewAndSchedule),

            // For an Instant order there's no manual decision to make — the
            // nearest slot is applied automatically — so this is either a
            // brief "checking…" row or, once it resolves, a plain confirmed-
            // slot summary in place of the banner/date/slot cards a Schedule
            // order shows. Falls through to the normal Schedule UI below if
            // the check found nothing bookable soon.
            if (widget.isInstantOrder && !_instantFellBackToManual) ...[
              if (_isCheckingAvailability)
                AppCard(
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        l10n.checkingAvailability,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                )
              else if (state.bookingDate != null && state.slot.isNotEmpty)
                AppCard(
                  child: Row(
                    children: [
                      const Icon(
                        Icons.flash_on,
                        size: 18,
                        color: AppColors.green,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${_formatDate(state.bookingDate!)} · ${state.slot}',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ]
            // Schedule order — the server's own availability answer, when
            // known, shown as a dismissible banner with a one-tap action;
            // stays hidden entirely if the check failed or hasn't resolved.
            else if (_availability != null)
              _AvailabilityBanner(
                availability: _availability!,
                onUseSlot: _useAvailableSlot,
              ),

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

            // Bundled extra services — added via "Add More Services" below,
            // from the same provider as the primary service. Shown once at
            // least one is added; the button to add more is always visible.
            if (!_isLoading) ...[
              if (state.extraServices.isNotEmpty)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.additionalServicesTitle,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      for (final extra in state.extraServices)
                        _ExtraServiceRow(
                          extra: extra,
                          isLast: extra == state.extraServices.last,
                          onRemove: () =>
                              state.removeExtraService(extra.serviceId),
                        ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SecondaryButton(
                  label: l10n.addMoreServices,
                  onTap: _addExtraService,
                ),
              ),
            ],

            // Date/slot pickers — skipped for an Instant order that
            // successfully auto-selected a slot, since there's nothing left
            // to pick; shown as normal for a Schedule order, or if an
            // Instant order's availability check found nothing bookable
            // soon and fell back to manual picking.
            if (!widget.isInstantOrder || _instantFellBackToManual) ...[
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

              // Slot picker — slots come from GET /customer/slots
              // (admin-configured per zone), never hardcoded.
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
                    else if (_isLoadingSlots || _isLoadingBookedSlots)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                l10n.updatingSlotsLabel,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_bookingSlotsError != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            Text(
                              _bookingSlotsError!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: _fetchBookingSlots,
                              child: Text(
                                l10n.retryLabel,
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_bookingSlots.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          l10n.noSlotsAvailableLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _bookingSlots.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                              // Labels are a full range (e.g. "9:00 AM -
                              // 10:00 AM") and can wrap to 2 lines, plus a
                              // "Passed" caption below for past slots — a
                              // squatter cell than the old single-line,
                              // fixed slot list needed.
                              childAspectRatio: 1.35,
                            ),
                        itemBuilder: (_, i) {
                          final slot = _bookingSlots[i];
                          final selected = state.slot == slot.label;
                          final isBooked = _bookedSlots.contains(slot.label);
                          final isDisabled = isBooked || slot.isPast;
                          return GestureDetector(
                            onTap: !isDisabled
                                ? () => state.selectSlot(slot.label)
                                : () => showAppToast(
                                    context,
                                    l10n.slotUnavailableToast,
                                  ),
                            child: Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isDisabled
                                    ? const Color(0xFFF2F4F6)
                                    : (selected
                                          ? AppColors.mint
                                          : Colors.white),
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
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    slot.label,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.15,
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
                                  if (slot.isPast && !isBooked) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      l10n.slotPassedLabel,
                                      style: const TextStyle(
                                        fontSize: 8.5,
                                        color: Color(0xFFA6AEB6),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],

            // Delivery address — lets the customer verify (and change)
            // where the order will actually be delivered before paying,
            // same source of truth as the home screen's location picker.
            _DeliveryAddressCard(
              selectedAddress: state.selectedAddress,
              currentAddress: _currentAddress,
              onChange: () => showLocationPickerSheet(context),
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
                    showDivider: state.extraServices.isNotEmpty,
                  ),
                  if (state.extraServices.isNotEmpty)
                    DetailRow(
                      label: l10n.additionalServicesTitle,
                      value: '₹${state.extraServicesTotal}',
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

/// Delivery-address card — lets the customer verify where the order will
/// actually be delivered before proceeding to payment, and change it via
/// the same location picker the home screen uses. Mirrors
/// `AppState.selectedAddress`: `null` means "Use current location", shown
/// via [currentAddress] (the device's live GPS text, fetched independently
/// by `BookingScreen` since it can be reached without visiting Home first).
class _DeliveryAddressCard extends StatelessWidget {
  const _DeliveryAddressCard({
    required this.selectedAddress,
    required this.currentAddress,
    required this.onChange,
  });

  final SavedAddress? selectedAddress;
  final String? currentAddress;
  final VoidCallback onChange;

  static String _labelFor(AppLocalizations l10n, String key) => switch (key) {
    'Home' => l10n.addressTypeHome,
    'Office' => l10n.addressTypeOffice,
    _ => l10n.addressTypeOther,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final address = selectedAddress;
    final title = address != null
        ? _labelFor(l10n, address.label)
        : l10n.useCurrentLocation;
    final line = address != null
        ? address.line.replaceAll('\n', ' ')
        : (currentAddress ?? l10n.locationNotAvailable);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.iceBlue,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.location_on_outlined,
              size: 17,
              color: AppColors.blue,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.deliveryAddressLabel,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  line,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.muted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onChange,
            child: Text(
              l10n.changeLabel,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: AppColors.blue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shows the provider's own availability answer — "available now" with a
/// one-tap action to grab that slot, or the provider's actual next opening
/// when nothing is free right away. Replaces the old Instant Booking FAB,
/// which only ever guessed from `booked-slots` for today's date.
class _AvailabilityBanner extends StatelessWidget {
  const _AvailabilityBanner({required this.availability, this.onUseSlot});

  final ProviderAvailability availability;
  final VoidCallback? onUseSlot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasSlot = availability.nextAvailableAt != null;
    final message = availability.availableNow
        ? l10n.providerAvailableNow
        : hasSlot
        ? l10n.providerNextAvailable(availability.nextAvailableSlot!)
        : null;
    if (message == null) return const SizedBox.shrink();

    return AppCard(
      child: Row(
        children: [
          Icon(
            availability.availableNow
                ? Icons.flash_on
                : Icons.schedule_outlined,
            size: 18,
            color: availability.availableNow ? AppColors.green : AppColors.blue,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
          if (hasSlot)
            GestureDetector(
              onTap: onUseSlot,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F7EF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.useThisSlot,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.greenDark,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A single bundled extra service row within the "Additional Services"
/// card — name/price plus a remove action, mirroring the add-on rows'
/// visual weight but with a destructive rather than toggle action.
class _ExtraServiceRow extends StatelessWidget {
  const _ExtraServiceRow({
    required this.extra,
    required this.isLast,
    required this.onRemove,
  });

  final ExtraService extra;
  final bool isLast;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: Color(0xFFEDF1F4))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(color: AppColors.ink),
                    children: [
                      TextSpan(
                        text: extra.label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      TextSpan(
                        text: '  ·  ₹${extra.servicePrice}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onRemove,
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
          // This service's own selected add-ons, shown the same way the
          // primary service's add-ons appear in "Recommended Add-ons" —
          // just indented under the service they belong to, since there can
          // be several bundled services each with their own add-ons.
          if (extra.addons.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final addon in extra.addons)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        '${addon.name}  ·  ₹${addon.price}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
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
