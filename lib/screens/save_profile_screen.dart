import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../core/services/api_service.dart';
import '../core/services/device_info_service.dart';
import '../core/services/token_storage.dart';
import '../l10n/app_localizations.dart';
import '../models/register_details.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

/// Shown right after every successful OTP verification, so the customer's
/// profile is complete before they enter the app. [token] is sent as a
/// Bearer header on the profile-save call; [authData] is the full `data`
/// object from `auth/verify-otp` (token + user), persisted locally once the
/// profile save succeeds so a returning launch can skip onboarding/login.
class SaveProfileScreen extends StatefulWidget {
  const SaveProfileScreen({
    super.key,
    required this.token,
    required this.authData,
    this.initialName,
    this.initialEmail,
  });

  final String token;
  final Map<String, dynamic> authData;
  final String? initialName;
  final String? initialEmail;

  @override
  State<SaveProfileScreen> createState() => _SaveProfileScreenState();
}

class _SaveProfileScreenState extends State<SaveProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  late final _name = TextEditingController(text: widget.initialName);
  late final _email = TextEditingController(text: widget.initialEmail);
  final _address = TextEditingController();
  final _landmark = TextEditingController();
  final _pincode = TextEditingController();

  /// Canonical (non-localized) address type value: `'Home' | 'Office' | 'Other'`.
  /// Sent to the backend lowercased as `type_of_address`; displayed via a
  /// localized label built in [build].
  String _addressType = 'Home';
  bool _isSubmitting = false;

  RegisterDetails? _registerDetails;
  bool _isLoadingLocations = true;
  int? _selectedStateId;
  int? _selectedCityId;

  @override
  void initState() {
    super.initState();
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
    _name.dispose();
    _email.dispose();
    _address.dispose();
    _landmark.dispose();
    _pincode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isSubmitting = true);
    var didSucceed = false;
    String? errorMessage;
    try {
      final coordinates = await DeviceInfoService.loginCoordinates();
      final response = await _apiService.post(
        '/auth/save-detail',
        data: {
          'userDetail': {
            'name': _name.text.trim(),
            'email': _email.text.trim(),
            'isOnboarded': true,
          },
          'addressDetail': {
            'address': _address.text.trim(),
            'landmark': _landmark.text.trim(),
            'city_id': _selectedCityId,
            'state_id': _selectedStateId,
            'pincode': _pincode.text.trim(),
            'coordinates': coordinates,
            'is_primary': true,
            'type_of_address': _addressType.toLowerCase(),
          },
        },
        options: Options(
          headers: {'Authorization': 'Bearer ${widget.token}'},
        ),
      );
      didSucceed = response.data['is_success'] == true;
      if (!didSucceed) {
        errorMessage = response.data['message'] as String?;
      }
    } catch (e) {
      debugPrint('Save profile API error: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
    if (!mounted) return;
    if (!didSucceed) {
      showAppToast(
        context,
        errorMessage ?? AppLocalizations.of(context).couldNotSaveProfile,
      );
      return;
    }
    await TokenStorage.saveToken(widget.token);
    await TokenStorage.saveAuthData(widget.authData);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AppShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final addressTypeLabels = <String, String>{
      'Home': l10n.addressTypeHome,
      'Office': l10n.addressTypeOffice,
      'Other': l10n.addressTypeOther,
    };
    return Scaffold(
      backgroundColor: AppColors.authBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/logo.png',
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.completeYourProfile,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.saveProfileSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
                const SizedBox(height: 26),
                LabeledField(
                  label: l10n.fullNameLabel,
                  child: TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    decoration: appInputDecoration(l10n.enterFullNameHint),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l10n.nameRequired
                        : null,
                  ),
                ),
                LabeledField(
                  label: l10n.emailLabel,
                  child: TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: appInputDecoration(l10n.emailHint),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return l10n.emailRequired;
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                        return l10n.enterValidEmail;
                      }
                      return null;
                    },
                  ),
                ),
                LabeledField(
                  label: l10n.addressTypeLabel,
                  child: Row(
                    children: addressTypeLabels.entries
                        .map(
                          (entry) => FilterChipButton(
                            label: entry.value,
                            selected: _addressType == entry.key,
                            onTap: () => setState(() => _addressType = entry.key),
                          ),
                        )
                        .toList(),
                  ),
                ),
                LabeledField(
                  label: l10n.addressLabel,
                  child: TextFormField(
                    controller: _address,
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
                    controller: _landmark,
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
                            _isLoadingLocations ? l10n.loadingEllipsis : l10n.selectStateHint,
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
                          validator: (v) => v == null ? l10n.requiredField : null,
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
                              : (_registerDetails
                                            ?.citiesForState(_selectedStateId!) ??
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
                          validator: (v) => v == null ? l10n.requiredField : null,
                        ),
                      ),
                    ),
                  ],
                ),
                LabeledField(
                  label: l10n.pincodeLabel,
                  child: TextFormField(
                    controller: _pincode,
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
                  label: _isSubmitting ? l10n.saving : l10n.saveAndContinue,
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
