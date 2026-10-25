import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../models/register_details.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'add_saved_address_screen.dart';

/// Address book reached from Profile → Saved Addresses. Fetches
/// `GET /addresses` on load and writes results into `AppState.addresses` —
/// the same list the home screen's location picker reads — so an edit here
/// (made default, deleted, added) is reflected there too.
class SavedAddressesScreen extends StatefulWidget {
  const SavedAddressesScreen({super.key});

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  final _apiService = ApiService();
  bool _isLoading = true;

  /// City/state id → name, resolved once from `/auth/register-details` so
  /// address cards can show "Udaipur, Rajasthan" instead of the backend's
  /// raw numeric ids.
  RegisterDetails? _registerDetails;

  List<SavedAddress> get _addresses => AppStateScope.of(context).addresses;

  @override
  void initState() {
    super.initState();
    _fetchAddresses();
    _fetchRegisterDetails();
  }

  Future<void> _fetchAddresses() async {
    setState(() => _isLoading = true);
    try {
      final response = await _apiService.get('/addresses');
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        final data = response.data['data'];
        final rows = (data is Map ? data['addresses'] : data) as List<dynamic>;
        final addresses = rows
            .map((e) => SavedAddress.fromJson(e as Map<String, dynamic>))
            .toList();
        if (mounted) AppStateScope.of(context).setAddresses(addresses);
      }
    } catch (e) {
      debugPrint('Addresses API error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchRegisterDetails() async {
    try {
      final response = await _apiService.get(
        '/auth/register-details',
        queryParameters: {'user_type_id': 2},
      );
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        setState(
          () => _registerDetails = RegisterDetails.fromJson(
            response.data['data'] as Map<String, dynamic>,
          ),
        );
      }
    } catch (e) {
      debugPrint('Register details API error: $e');
    }
  }

  /// [SavedAddress.cityName]/[SavedAddress.stateName] come back `null` from
  /// `fromJson` since the backend only sends ids — this resolves the
  /// display names from [_registerDetails] (once it's loaded) for each
  /// card, falling back to the raw address as-is if nothing matches yet.
  SavedAddress _withResolvedNames(SavedAddress address) {
    final details = _registerDetails;
    if (details == null) return address;
    final cityName = address.cityId == null
        ? null
        : details.cities
              .where((c) => c.id == address.cityId)
              .map((c) => c.name)
              .firstOrNull;
    final stateName = address.stateId == null
        ? null
        : details.states
              .where((s) => s.id == address.stateId)
              .map((s) => s.name)
              .firstOrNull;
    return SavedAddress(
      id: address.id,
      addressText: address.addressText,
      landmark: address.landmark,
      cityId: address.cityId,
      stateId: address.stateId,
      cityName: cityName,
      stateName: stateName,
      pincode: address.pincode,
      coordinates: address.coordinates,
      typeOfAddress: address.typeOfAddress,
      isDefault: address.isDefault,
    );
  }

  static String _labelFor(AppLocalizations l10n, String key) => switch (key) {
    'Home' => l10n.addressTypeHome,
    'Office' => l10n.addressTypeOffice,
    _ => l10n.addressTypeOther,
  };

  Future<void> _makeDefault(SavedAddress address) async {
    final l10n = AppLocalizations.of(context);
    try {
      final response = await _apiService.put(
        '/addresses/${address.id}/set-primary',
      );
      if (response.data['is_success'] != true) {
        if (mounted) showAppToast(context, l10n.couldNotSaveAddressToast);
        return;
      }
    } catch (e) {
      debugPrint('Set-primary API error: $e');
      if (mounted) showAppToast(context, l10n.couldNotSaveAddressToast);
      return;
    }
    if (!mounted) return;
    await _fetchAddresses();
    if (!mounted) return;
    showAppToast(
      context,
      l10n.setAsDefaultToast(_labelFor(l10n, address.label)),
    );
  }

  void _confirmDelete(SavedAddress address) {
    final l10n = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          l10n.deleteAddressQuestion,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        ),
        content: Text(
          l10n.deleteAddressConfirmBody(_labelFor(l10n, address.label)),
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              l10n.cancel,
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              try {
                final response = await _apiService.delete(
                  '/addresses/${address.id}',
                );
                if (response.data['is_success'] != true) {
                  if (mounted) {
                    showAppToast(context, l10n.couldNotSaveAddressToast);
                  }
                  return;
                }
              } catch (e) {
                debugPrint('Delete address API error: $e');
                if (mounted) {
                  showAppToast(context, l10n.couldNotSaveAddressToast);
                }
                return;
              }
              if (!mounted) return;
              AppStateScope.of(context).removeAddress(address.id);
              showAppToast(context, l10n.addressDeletedToast);
            },
            child: Text(
              l10n.delete,
              style: const TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddOrEdit({SavedAddress? existingAddress}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddSavedAddressScreen(existingAddress: existingAddress),
      ),
    );
    if (saved == true) _fetchAddresses();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final addresses = _addresses.map(_withResolvedNames).toList();
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                color: AppColors.green,
                onRefresh: _fetchAddresses,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  children: [
                    MiniHeader(
                      title: l10n.savedAddressesHeader,
                      subtitle: l10n.savedCount(addresses.length),
                    ),

                    if (addresses.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 50),
                        child: Column(
                          children: [
                            const FaIcon(
                              FontAwesomeIcons.mapLocationDot,
                              size: 34,
                              color: Color(0xFFB6C2CF),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              l10n.noSavedAddresses,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.ink,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              l10n.addAddressFasterBooking,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ...addresses.map((a) {
                        return AppCard(
                          radius: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppColors.mint,
                                      borderRadius: BorderRadius.circular(11),
                                    ),
                                    child: FaIcon(
                                      a.icon,
                                      size: 14,
                                      color: AppColors.greenDark,
                                    ),
                                  ),
                                  const SizedBox(width: 11),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              _labelFor(l10n, a.label),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                                color: AppColors.ink,
                                              ),
                                            ),
                                            if (a.isDefault) ...[
                                              const SizedBox(width: 7),
                                              Pill(
                                                label: l10n.defaultBadge,
                                                fontSize: 8.5,
                                              ),
                                            ],
                                          ],
                                        ),
                                        const SizedBox(height: 5),
                                        Text(
                                          a.line,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.muted,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 11),
                              Row(
                                children: [
                                  _AddressAction(
                                    icon: FontAwesomeIcons.penToSquare,
                                    label: l10n.editLabel,
                                    onTap: () =>
                                        _openAddOrEdit(existingAddress: a),
                                  ),
                                  const SizedBox(width: 8),
                                  _AddressAction(
                                    icon: FontAwesomeIcons.trashCan,
                                    label: l10n.deleteLabel,
                                    danger: true,
                                    onTap: () => _confirmDelete(a),
                                  ),
                                ],
                              ),
                              // Offered only on non-default addresses; kept
                              // on its own row so the labels never squeeze.
                              if (!a.isDefault) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    _AddressAction(
                                      icon: FontAwesomeIcons.circleCheck,
                                      label: l10n.setAsDefault,
                                      onTap: () => _makeDefault(a),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      }),

                    const SizedBox(height: 6),
                    SecondaryButton(
                      label: l10n.addNewAddress,
                      onTap: () => _openAddOrEdit(),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _AddressAction extends StatelessWidget {
  const _AddressAction({
    required this.icon,
    required this.label,
    this.onTap,
    this.danger = false,
  });

  final FaIconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final colour = danger ? AppColors.danger : AppColors.blue;
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FaIcon(icon, size: 11, color: colour),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: colour,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
