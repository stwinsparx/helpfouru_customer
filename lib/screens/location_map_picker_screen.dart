import 'dart:async';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../core/services/device_info_service.dart';
import '../core/services/places_service.dart';
import '../l10n/app_localizations.dart';
import '../models/picked_location.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Full-screen "search or drop a pin" location picker, shared by the Saved
/// Addresses "Add new address" flow and the registration form's address
/// step. The map always centers a fixed pin; dragging the map re-centers it
/// and reverse-geocodes the new center, while picking a search result snaps
/// the map straight to that place. Pops with a [PickedLocation], or `null`
/// if backed out without confirming.
///
/// TODO: this screen needs a real Google Maps API key (see
/// AndroidManifest.xml / AppDelegate.swift / [PlacesService]) — until one is
/// set, the map tiles and search box won't work, only the device's live GPS
/// fallback for the initial position.
class LocationMapPickerScreen extends StatefulWidget {
  const LocationMapPickerScreen({super.key, this.initialLocation});

  /// Centers the map here instead of live GPS — e.g. re-opening the picker
  /// to edit an already-picked address.
  final LatLng? initialLocation;

  @override
  State<LocationMapPickerScreen> createState() =>
      _LocationMapPickerScreenState();
}

class _LocationMapPickerScreenState extends State<LocationMapPickerScreen> {
  static const _fallbackCenter = LatLng(20.5937, 78.9629); // India, roughly.

  final _placesService = PlacesService();
  final _searchController = TextEditingController();
  GoogleMapController? _mapController;
  Timer? _debounce;

  LatLng _center = _fallbackCenter;
  PickedLocation? _resolvedLocation;
  bool _isResolvingAddress = false;
  bool _isSearching = false;
  List<PlaceSuggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      _center = widget.initialLocation!;
      _resolveAddressForCenter();
    } else {
      _useDeviceLocation();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _useDeviceLocation() async {
    final (status, coordinates) =
        await DeviceInfoService.currentLocationStatus();
    if (status != LocationStatus.available || coordinates == null) {
      await _resolveAddressForCenter();
      return;
    }
    final parts = coordinates.split(',');
    final lat = double.tryParse(parts[0]);
    final lng = double.tryParse(parts[1]);
    if (lat == null || lng == null) {
      await _resolveAddressForCenter();
      return;
    }
    if (!mounted) return;
    setState(() => _center = LatLng(lat, lng));
    _mapController?.animateCamera(CameraUpdate.newLatLng(_center));
    await _resolveAddressForCenter();
  }

  Future<void> _resolveAddressForCenter() async {
    setState(() => _isResolvingAddress = true);
    final location = await DeviceInfoService.reverseGeocode(
      _center.latitude,
      _center.longitude,
    );
    if (!mounted) return;
    setState(() {
      _resolvedLocation = location;
      _isResolvingAddress = false;
    });
  }

  void _onCameraIdle() {
    _resolveAddressForCenter();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      setState(() => _isSearching = true);
      final results = await _placesService.autocomplete(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _isSearching = false;
      });
    });
  }

  Future<void> _selectSuggestion(PlaceSuggestion suggestion) async {
    setState(() {
      _suggestions = [];
      _searchController.text = suggestion.description;
      _isResolvingAddress = true;
    });
    final location = await _placesService.placeDetails(suggestion.placeId);
    if (!mounted) return;
    if (location == null) {
      setState(() => _isResolvingAddress = false);
      return;
    }
    final target = LatLng(location.latitude, location.longitude);
    setState(() {
      _center = target;
      _resolvedLocation = location;
      _isResolvingAddress = false;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(target, 16));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: MiniHeader(title: l10n.pickLocationTitle),
                ),
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _center,
                          zoom: 15,
                        ),
                        onMapCreated: (controller) =>
                            _mapController = controller,
                        onCameraMove: (position) => _center = position.target,
                        onCameraIdle: _onCameraIdle,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                      ),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 36),
                        child: FaIcon(
                          FontAwesomeIcons.locationDot,
                          size: 36,
                          color: AppColors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 70, 16, 0),
              child: Column(
                children: [
                  Material(
                    elevation: 3,
                    borderRadius: BorderRadius.circular(12),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: appInputDecoration(l10n.searchLocationHint)
                          .copyWith(
                            prefixIcon: const Icon(
                              Icons.search,
                              size: 20,
                              color: Color(0xFF8391A3),
                            ),
                            suffixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                    ),
                  ),
                  if (_suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A0A2540),
                            blurRadius: 14,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: _suggestions
                            .map(
                              (s) => ListTile(
                                dense: true,
                                leading: const FaIcon(
                                  FontAwesomeIcons.locationDot,
                                  size: 14,
                                  color: AppColors.muted,
                                ),
                                title: Text(
                                  s.description,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                onTap: () => _selectSuggestion(s),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x1A0A2540),
                      blurRadius: 16,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectedLocationLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isResolvingAddress
                          ? l10n.loadingEllipsis
                          : (_resolvedLocation?.formattedAddress.isNotEmpty ==
                                    true
                                ? _resolvedLocation!.formattedAddress
                                : l10n.unknownLocationLabel),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: l10n.confirmLocationButton,
                      onTap: _resolvedLocation == null
                          ? null
                          : () => Navigator.of(context).pop(_resolvedLocation),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
