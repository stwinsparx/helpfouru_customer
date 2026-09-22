import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../core/services/api_service.dart';
import '../l10n/app_localizations.dart';
import '../models/bid.dart';
import '../models/service_category.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// The bid-post form. When [editingBid] is supplied, the form is pre-filled
/// with its values and submitting updates it (`id` sent in the payload)
/// instead of creating a new bid.
class BiddingScreen extends StatefulWidget {
  const BiddingScreen({super.key, this.editingBid});

  final BidDetail? editingBid;

  @override
  State<BiddingScreen> createState() => _BiddingScreenState();
}

class _BiddingScreenState extends State<BiddingScreen> {
  final _apiService = ApiService();
  final _picker = ImagePicker();

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _registrationFees = TextEditingController();
  final _budget = TextEditingController();
  final _days = TextEditingController();
  final _penaltyNotes = TextEditingController();
  final _city = TextEditingController();
  final _location = TextEditingController();
  final _date = TextEditingController();
  DateTime? _selectedDate;
  bool _isFeesRefundable = false;
  bool _isPenalty = false;

  List<ServiceCategory> _categories = [];
  bool _isLoadingCategories = true;
  ServiceCategory? _category;

  final List<String> _uploadedImageUrls = [];
  final List<String> _uploadingPaths = [];
  final List<String> _uploadedDocumentUrls = [];
  final List<String> _uploadingDocumentPaths = [];

  bool _isSubmitting = false;

  bool get _isEditing => widget.editingBid != null;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    final bid = widget.editingBid;
    if (bid != null) {
      _title.text = bid.title;
      _description.text = bid.description ?? '';
      _registrationFees.text = bid.bidRegistrationFees ?? '';
      _budget.text = bid.estimateBidPrice ?? '';
      _days.text = bid.estimatedWorkingDays?.toString() ?? '';
      _penaltyNotes.text = bid.penaltyRulesNotes ?? '';
      _city.text = bid.city ?? '';
      _location.text = bid.bidLocation ?? '';
      _isFeesRefundable = bid.isFeesRefundable;
      _isPenalty = bid.isPenalty;
      _uploadedImageUrls.addAll(bid.images);
      _uploadedDocumentUrls.addAll(bid.documents);
      final endDate = bid.bidEndDate;
      if (endDate != null && endDate.isNotEmpty) {
        final parsed = DateTime.tryParse(endDate);
        if (parsed != null) {
          _selectedDate = parsed;
          _date.text =
              '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
        }
      }
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _registrationFees.dispose();
    _budget.dispose();
    _days.dispose();
    _penaltyNotes.dispose();
    _city.dispose();
    _location.dispose();
    _date.dispose();
    super.dispose();
  }

  Future<void> _fetchCategories() async {
    try {
      final response = await _apiService.get('/customer/services');
      if (response.statusCode == 200 && response.data['is_success'] == true) {
        final data = response.data['data'] as Map<String, dynamic>;
        final categories = (data['categories'] as List<dynamic>? ?? [])
            .map((e) => ServiceCategory.fromJson(e as Map<String, dynamic>))
            .toList();
        final editingCategoryId = widget.editingBid?.serviceCategoryId;
        ServiceCategory? selected = categories.isNotEmpty
            ? categories.first
            : null;
        if (editingCategoryId != null) {
          for (final c in categories) {
            if (c.id == editingCategoryId) {
              selected = c;
              break;
            }
          }
        }
        setState(() {
          _categories = categories;
          _category = selected;
        });
      }
    } catch (e) {
      debugPrint('Services API error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingCategories = false);
    }
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
      setState(() {
        _selectedDate = picked;
        _date.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _addPhoto() async {
    final l10n = AppLocalizations.of(context);
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    setState(() => _uploadingPaths.add(picked.path));
    try {
      final path = await _apiService.uploadFile('bids', picked.path);
      if (!mounted) return;
      setState(() {
        _uploadingPaths.remove(picked.path);
        _uploadedImageUrls.add(path);
      });
    } catch (e) {
      debugPrint('Upload error: $e');
      if (!mounted) return;
      setState(() => _uploadingPaths.remove(picked.path));
      showAppToast(context, l10n.photoUploadFailedToast);
    }
  }

  Future<void> _addDocument() async {
    final l10n = AppLocalizations.of(context);
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
      ],
    );
    final path = picked?.files.single.path;
    if (path == null) return;
    setState(() => _uploadingDocumentPaths.add(path));
    try {
      final uploadedPath = await _apiService.uploadFile('bid-documents', path);
      if (!mounted) return;
      setState(() {
        _uploadingDocumentPaths.remove(path);
        _uploadedDocumentUrls.add(uploadedPath);
      });
    } catch (e) {
      debugPrint('Upload error: $e');
      if (!mounted) return;
      setState(() => _uploadingDocumentPaths.remove(path));
      showAppToast(context, l10n.photoUploadFailedToast);
    }
  }

  void _removeImage(String url) {
    setState(() => _uploadedImageUrls.remove(url));
  }

  void _removeDocument(String url) {
    setState(() => _uploadedDocumentUrls.remove(url));
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final response = await _apiService.post(
        '/customer/bids',
        data: {
          if (_isEditing) 'id': widget.editingBid!.id,
          'title': _title.text.trim(),
          if (_description.text.trim().isNotEmpty)
            'description': _description.text.trim(),
          if (_category != null) 'service_category_id': _category!.id,
          'bid_registration_fees':
              num.tryParse(_registrationFees.text.trim()) ?? 0,
          'is_fees_refundable': _isFeesRefundable,
          if (_budget.text.trim().isNotEmpty)
            'estimate_bid_price': num.tryParse(_budget.text.trim()),
          if (_days.text.trim().isNotEmpty)
            'estimated_working_days': int.tryParse(_days.text.trim()),
          'is_penalty': _isPenalty,
          if (_isPenalty && _penaltyNotes.text.trim().isNotEmpty)
            'penalty_rules_notes': _penaltyNotes.text.trim(),
          if (_selectedDate != null)
            'bid_end_date':
                '${_selectedDate!.year.toString().padLeft(4, '0')}-${_selectedDate!.month.toString().padLeft(2, '0')}-${_selectedDate!.day.toString().padLeft(2, '0')}',
          if (_city.text.trim().isNotEmpty) 'city': _city.text.trim(),
          if (_location.text.trim().isNotEmpty)
            'bid_location': _location.text.trim(),
          'images': _uploadedImageUrls,
          'documents': _uploadedDocumentUrls,
        },
      );
      if (!mounted) return;
      if (response.data['is_success'] == true) {
        showAppToast(
          context,
          _isEditing ? l10n.bidUpdatedToast : l10n.biddingPublishedToast,
        );
        Navigator.of(context).pop(true);
      } else {
        showAppToast(context, l10n.bidSubmitFailedToast);
      }
    } catch (e) {
      debugPrint('Post bid API error: $e');
      if (mounted) showAppToast(context, l10n.bidSubmitFailedToast);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        bottom: false,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              MiniHeader(
                title: _isEditing
                    ? l10n.editBidRequest
                    : l10n.publishBiddingRequest,
              ),

              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  gradient: AppGradients.banner,
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.letProvidersCompete,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.describeRequirementBanner,
                      style: const TextStyle(
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
                    LabeledField(
                      label: l10n.bidTitleLabel,
                      child: TextFormField(
                        controller: _title,
                        decoration: appInputDecoration(l10n.bidTitleHint),
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.bidTitleRequiredError
                            : null,
                      ),
                    ),
                    Text(
                      l10n.serviceCategoryLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoadingCategories)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFDCE5ED)),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<ServiceCategory>(
                            value: _category,
                            isExpanded: true,
                            items: _categories
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c.categoryName),
                                  ),
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
                    Text(
                      l10n.whatDoYouNeed,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _description,
                      maxLines: 4,
                      decoration: appInputDecoration(
                        l10n.biddingRequirementHint,
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
                    Text(
                      l10n.budgetAndSchedule,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    LabeledField(
                      label: l10n.registrationFeesLabel,
                      child: TextFormField(
                        controller: _registrationFees,
                        keyboardType: TextInputType.number,
                        decoration: appInputDecoration(
                          l10n.registrationFeesHint,
                        ),
                      ),
                    ),
                    CheckboxListTile(
                      value: _isFeesRefundable,
                      onChanged: (v) =>
                          setState(() => _isFeesRefundable = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        l10n.feesRefundableLabel,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    LabeledField(
                      label: l10n.expectedBudgetLabel,
                      child: TextFormField(
                        controller: _budget,
                        keyboardType: TextInputType.number,
                        decoration: appInputDecoration(l10n.expectedBudgetHint),
                      ),
                    ),
                    LabeledField(
                      label: l10n.expectedDaysLabel,
                      child: TextFormField(
                        controller: _days,
                        keyboardType: TextInputType.number,
                        decoration: appInputDecoration(l10n.expectedDaysHint),
                      ),
                    ),
                    LabeledField(
                      label: l10n.preferredDateLabel,
                      child: TextFormField(
                        controller: _date,
                        readOnly: true,
                        onTap: _pickDate,
                        decoration: appInputDecoration(l10n.selectDateHint)
                            .copyWith(
                              suffixIconConstraints: const BoxConstraints(
                                minWidth: 40,
                                minHeight: 40,
                              ),
                              suffixIcon: const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: FaIcon(
                                  FontAwesomeIcons.calendar,
                                  size: 15,
                                  color: AppColors.muted,
                                ),
                              ),
                            ),
                      ),
                    ),
                    LabeledField(
                      label: l10n.cityLabel,
                      child: TextFormField(
                        controller: _city,
                        decoration: appInputDecoration(l10n.cityHint),
                      ),
                    ),
                    LabeledField(
                      label: l10n.locationLabel,
                      child: TextFormField(
                        controller: _location,
                        decoration: appInputDecoration(l10n.locationHint),
                      ),
                    ),
                    CheckboxListTile(
                      value: _isPenalty,
                      onChanged: (v) => setState(() => _isPenalty = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        l10n.penaltyApplicableLabel,
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ),
                    if (_isPenalty) ...[
                      const SizedBox(height: 6),
                      LabeledField(
                        label: l10n.penaltyRulesLabel,
                        child: TextFormField(
                          controller: _penaltyNotes,
                          maxLines: 3,
                          decoration: appInputDecoration(l10n.penaltyRulesHint),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              AppCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.attachPhotosLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final url in _uploadedImageUrls)
                          _PhotoThumb(
                            imageUrl: url,
                            onRemove: () => _removeImage(url),
                          ),
                        for (final path in _uploadingPaths)
                          _PhotoThumb(localPath: path, isUploading: true),
                        _AddPhotoTile(label: l10n.addPhoto, onTap: _addPhoto),
                      ],
                    ),
                  ],
                ),
              ),

              AppCard(
                margin: const EdgeInsets.only(bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.attachDocumentsLabel,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final url in _uploadedDocumentUrls)
                          _PhotoThumb(
                            imageUrl: url,
                            onRemove: () => _removeDocument(url),
                          ),
                        for (final path in _uploadingDocumentPaths)
                          _PhotoThumb(localPath: path, isUploading: true),
                        _AddPhotoTile(
                          label: l10n.addDocument,
                          onTap: _addDocument,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              PrimaryButton(
                label: _isSubmitting
                    ? '…'
                    : (_isEditing ? l10n.updateRequest : l10n.publishRequest),
                onTap: _isSubmitting ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({
    this.imageUrl,
    this.localPath,
    this.isUploading = false,
    this.onRemove,
  });

  final String? imageUrl;
  final String? localPath;
  final bool isUploading;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading
          ? null
          : () => showImagePreview(
              context,
              imageUrl: imageUrl,
              localPath: localPath,
            ),
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imageUrl != null)
              Image.network(imageUrl!, fit: BoxFit.cover)
            else if (localPath != null)
              Image.file(File(localPath!), fit: BoxFit.cover),
            if (isUploading)
              const ColoredBox(
                color: Color(0x66000000),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            if (onRemove != null)
              Positioned(
                right: 2,
                top: 2,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 18,
                    height: 18,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xCC10253B),
                      shape: BoxShape.circle,
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.xmark,
                      size: 9,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 72,
          height: 72,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFDCE5ED)),
            borderRadius: BorderRadius.circular(12),
            color: const Color(0xFFF6F9FB),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.camera,
                size: 16,
                color: AppColors.muted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 8.5, color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
