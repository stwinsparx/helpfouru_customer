import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../l10n/app_localizations.dart';
import '../models/current_user.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Editable account details reached from Profile → Personal Information.
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController(text: 'e 27 Adarsh nagar');
  final _landmark = TextEditingController();
  final _city = TextEditingController(text: 'Udaipur');
  final _state = TextEditingController(text: 'Rajasthan');
  final _pin = TextEditingController(text: '313001');

  bool _dirty = false;
  String _initials = '?';

  List<TextEditingController> get _controllers => [
    _name,
    _mobile,
    _email,
    _address,
    _landmark,
    _city,
    _state,
    _pin,
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    for (final c in _controllers) {
      c.addListener(_markDirty);
    }
  }

  Future<void> _loadCurrentUser() async {
    final user = await CurrentUser.load();
    if (!mounted || user == null) return;
    _name.text = user.name;
    _mobile.text = user.phone;
    _email.text = user.email;
    setState(() {
      _initials = user.initials;
      _dirty = false;
    });
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    FocusScope.of(context).unfocus();
    setState(() => _dirty = false);
    showAppToast(context, l10n.profileUpdatedToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            MiniHeader(title: l10n.personalInformationHeader),

            // Avatar with a change-photo affordance.
            Center(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          gradient: AppGradients.avatar,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Positioned(
                        right: -2,
                        bottom: -2,
                        child: GestureDetector(
                          onTap: () =>
                              showAppToast(context, l10n.photoPickerOpenedToast),
                          child: Container(
                            width: 30,
                            height: 30,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.line,
                                width: 2,
                              ),
                            ),
                            child: const FaIcon(
                              FontAwesomeIcons.camera,
                              size: 12,
                              color: AppColors.blue,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Pill(label: l10n.verifiedAccountBadge, fontSize: 9),
                ],
              ),
            ),
            const SizedBox(height: 20),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.basicDetails,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  LabeledField(
                    label: l10n.fullNameLabel,
                    child: TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: appInputDecoration(l10n.enterYourNameHint),
                    ),
                  ),
                  LabeledField(
                    label: l10n.mobileNumberFieldLabel,
                    child: TextField(
                      controller: _mobile,
                      keyboardType: TextInputType.phone,
                      decoration: appInputDecoration(l10n.enterMobileNumberHint)
                          .copyWith(
                            prefixIcon: const Padding(
                              padding: EdgeInsets.only(left: 14, right: 8),
                              child: Text(
                                '+91',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                              ),
                            ),
                            prefixIconConstraints: const BoxConstraints(
                              minWidth: 0,
                              minHeight: 0,
                            ),
                          ),
                    ),
                  ),
                  LabeledField(
                    label: l10n.emailAddressLabel,
                    child: TextField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: appInputDecoration(l10n.emailHint),
                    ),
                  ),
                ],
              ),
            ),

            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.locationDetailsLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8190A1),
                      letterSpacing: 0.9,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _LocationField(
                    label: l10n.addressFieldLabel,
                    icon: FontAwesomeIcons.house,
                    controller: _address,
                    hint: 'e 27 Adarsh nagar',
                  ),
                  _LocationField(
                    label: l10n.landmarkFieldLabel,
                    icon: FontAwesomeIcons.locationDot,
                    controller: _landmark,
                    hint: l10n.nearbyLandmarkHint,
                  ),
                  _LocationField(
                    label: l10n.cityFieldLabel,
                    icon: FontAwesomeIcons.city,
                    controller: _city,
                    hint: 'Udaipur',
                  ),
                  _LocationField(
                    label: l10n.stateFieldLabel,
                    icon: FontAwesomeIcons.map,
                    controller: _state,
                    hint: 'Rajasthan',
                  ),
                  _LocationField(
                    label: l10n.pinCodeFieldLabel,
                    icon: FontAwesomeIcons.mapPin,
                    controller: _pin,
                    hint: '313001',
                    keyboardType: TextInputType.number,
                    isLast: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            PrimaryButton(
              label: _dirty ? l10n.saveChanges : l10n.saved,
              onTap: _dirty ? _save : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// Label + icon-prefixed input used by the LOCATION DETAILS card.
class _LocationField extends StatelessWidget {
  const _LocationField({
    required this.label,
    required this.icon,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.isLast = false,
  });

  final String label;
  final FaIconData icon;
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontSize: 14, color: AppColors.ink),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFFA3AFBD),
                fontSize: 14,
              ),
              filled: true,
              fillColor: const Color(0xFFF7F9FB),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: FaIcon(icon, size: 15, color: AppColors.muted),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.green,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
