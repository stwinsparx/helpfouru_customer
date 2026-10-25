import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../models/app_state.dart';
import '../models/picked_location.dart';
import '../models/register_details.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'location_map_picker_screen.dart';

/// "Add" or "Edit" address form reached from Saved Addresses — same form
/// either way, per the task's "edit open same popup" ask: pass
/// [existingAddress] to edit it in place (fields pre-filled, saves via
/// `PUT /addresses/:addressId`), or leave it `null` to create a new one
/// (`POST /addresses`).
///
/// The customer can type the address/landmark/pincode directly or pick a
/// location on [LocationMapPickerScreen] first (search or drop a pin), which
/// fills the address line and best-effort auto-selects the State/City
/// dropdowns — `city_id`/`state_id` must be one of the backend's fixed ids,
/// not free text, so the dropdowns are always the fields actually submitted;
/// the map only pre-fills them.
class AddSavedAddressScreen extends StatefulWidget {
  const AddSavedAddressScreen({super.key, this.existingAddress});

  /// `null` for "add new"; a real address for "edit".
  final SavedAddress? existingAddress;

  @override
  State<AddSavedAddressScreen> createState() => _AddSavedAddressScreenState();
}

class _AddSavedAddressScreenState extends State<AddSavedAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  late final _addressController = TextEditingController(
    text: widget.existingAddress?.addressText,
  );
  late final _landmarkController = TextEditingController(
    text: widget.existingAddress?.landmark,
  );
  late final _pincodeController = TextEditingController(
    text: widget.existingAddress?.pincode,
  );

  late String _typeOfAddress = widget.existingAddress?.typeKey ?? 'Home';
  String? _coordinates;
  bool _isSubmitting = false;

  RegisterDetails? _registerDetails;
  bool _isLoadingLocations = true;
  int? _selectedStateId;
  int? _selectedCityId;

  bool get _isEditing => widget.existingAddress != null;

  @override
  void initState() {
    super.initState();
    _coordinates = widget.existingAddress?.coordinates;
    _selectedStateId = widget.existingAddress?.stateId;
    _selectedCityId = widget.existingAddress?.cityId;
    _fetchRegisterDetails();
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
    } finally {
      if (mounted) setState(() => _isLoadingLocations = false);
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final location = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(builder: (_) => const LocationMapPickerScreen()),
    );
    if (location == null) return;
    setState(() {
      _coordinates = location.coordinates;
      _addressController.text = location.formattedAddress;
      if (location.postalCode != null) {
        _pincodeController.text = location.postalCode!;
      }
    });
    _autoSelectStateAndCity(location);
  }

  /// Best-effort match of the picked location's reverse-geocoded state/city
  /// names against the backend's fixed state/city id lists — only
  /// pre-selects the dropdowns; the customer can still correct them if the
  /// match is wrong or nothing matched. Same approach as the registration
  /// form's own map picker integration.
  void _autoSelectStateAndCity(PickedLocation location) {
    final details = _registerDetails;
    if (details == null) return;

    final stateName = location.administrativeArea?.toLowerCase();
    final matchedState = stateName == null
        ? null
        : details.states
              .where((s) => s.name.toLowerCase() == stateName)
              .firstOrNull;
    if (matchedState == null) return;

    final cityName = location.locality?.toLowerCase();
    final matchedCity = cityName == null
        ? null
        : details
              .citiesForState(matchedState.id)
              .where((c) => c.name.toLowerCase() == cityName)
              .firstOrNull;

    setState(() {
      _selectedStateId = matchedState.id;
      _selectedCityId = matchedCity?.id;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _isSubmitting = true);

    final body = {
      'address': _addressController.text.trim(),
      'landmark': _landmarkController.text.trim().isEmpty
          ? null
          : _landmarkController.text.trim(),
      'city_id': _selectedCityId,
      'state_id': _selectedStateId,
      'pincode': _pincodeController.text.trim(),
      'coordinates': _coordinates,
      'type_of_address': _typeOfAddress.toUpperCase(),
    };

    var didSucceed = false;
    String? errorMessage;
    try {
      final existing = widget.existingAddress;
      final response = existing == null
          ? await _apiService.post('/addresses', data: body)
          : await _apiService.put('/addresses/${existing.id}', data: body);
      didSucceed = response.data['is_success'] == true;
      if (!didSucceed) errorMessage = response.data['message'] as String?;
    } catch (e) {
      debugPrint('Save address API error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    if (!mounted) return;
    if (!didSucceed) {
      showAppToast(context, errorMessage ?? l10n.couldNotSaveAddressToast);
      return;
    }
    showAppToast(context, l10n.addressSavedToast);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final typeOptions = <String, String>{
      'Home': l10n.addressTypeHome,
      'Office': l10n.addressTypeOffice,
      'Other': l10n.addressTypeOther,
    };

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MiniHeader(
                  title: _isEditing
                      ? l10n.editAddressFormTitle
                      : l10n.addAddressFormTitle,
                ),
                LabeledField(
                  label: l10n.addressTypeLabel,
                  child: Row(
                    children: typeOptions.entries
                        .map(
                          (entry) => FilterChipButton(
                            label: entry.value,
                            selected: _typeOfAddress == entry.key,
                            onTap: () =>
                                setState(() => _typeOfAddress = entry.key),
                          ),
                        )
                        .toList(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: SecondaryButton(
                    label: l10n.chooseOnMapButton,
                    onTap: _openMapPicker,
                  ),
                ),
                LabeledField(
                  label: l10n.addressLabel,
                  child: TextFormField(
                    controller: _addressController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: appInputDecoration(l10n.enterAddressHint),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.addressRequired
                        : null,
                  ),
                ),
                LabeledField(
                  label: l10n.landmarkOptionalLabel,
                  child: TextFormField(
                    controller: _landmarkController,
                    decoration: appInputDecoration(l10n.nearbyLandmarkHint),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: LabeledField(
                        label: l10n.stateLabel,
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedStateId,
                          isExpanded: true,
                          decoration: appInputDecoration(
                            _isLoadingLocations
                                ? l10n.loadingEllipsis
                                : l10n.selectStateHint,
                          ),
                          items: (_registerDetails?.states ?? const [])
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s.id,
                                  child: Text(
                                    s.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() {
                            _selectedStateId = v;
                            _selectedCityId = null;
                          }),
                          validator: (v) =>
                              v == null ? l10n.requiredField : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: LabeledField(
                        label: l10n.cityLabel,
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedCityId,
                          isExpanded: true,
                          decoration: appInputDecoration(
                            _selectedStateId == null
                                ? l10n.selectStateFirstHint
                                : l10n.selectCityHint,
                          ),
                          items: _selectedStateId == null
                              ? const []
                              : (_registerDetails?.citiesForState(
                                          _selectedStateId!,
                                        ) ??
                                        const [])
                                    .map(
                                      (c) => DropdownMenuItem(
                                        value: c.id,
                                        child: Text(
                                          c.name,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                          onChanged: _selectedStateId == null
                              ? null
                              : (v) => setState(() => _selectedCityId = v),
                          validator: (v) =>
                              v == null ? l10n.requiredField : null,
                        ),
                      ),
                    ),
                  ],
                ),
                LabeledField(
                  label: l10n.pincodeLabel,
                  child: TextFormField(
                    controller: _pincodeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: appInputDecoration(
                      l10n.enterPincodeHint,
                    ).copyWith(counterText: ''),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return l10n.pincodeRequired;
                      if (!RegExp(r'^\d{6}$').hasMatch(value)) {
                        return l10n.enterValidPincode;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: _isSubmitting ? l10n.saving : l10n.saveAddressButton,
                  onTap: _isSubmitting ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
