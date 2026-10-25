import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../l10n/app_localizations.dart';
import '../../models/current_user.dart';
import 'api_service.dart';
import 'razorpay_service.dart';

/// Runs the same "create → pay via Razorpay → confirm" dance
/// `PaymentScreen` uses for placing a brand-new order, but for a follow-on
/// charge against an existing order — adding a sub-order or paying for
/// newly-added add-ons. A create/update call that returns Razorpay fields
/// (`razorpay_order_id`, `razorpay_key`) is treated as "payment required":
/// checkout opens and [onDone] only fires once it succeeds. A response
/// without those fields (e.g. the change was free, or the backend hasn't
/// been updated to require payment for it yet) is treated as already
/// complete and [onDone] fires immediately — this mirrors `PaymentScreen`'s
/// own best-effort field-name guessing, since neither contract is
/// confirmed yet.
///
/// Owned by the widget that creates it — call [dispose] from that widget's
/// own `dispose()`.
class InlineCheckout {
  InlineCheckout({required this.apiService});

  final ApiService apiService;
  RazorpayService? _razorpay;
  String? _pendingRazorpayOrderId;

  /// True when [response] carries Razorpay fields that mean payment is
  /// required before the create/update this response answers is considered
  /// final.
  static bool needsPayment(Map<String, dynamic> data) =>
      (data['razorpay_order_id'] as String?) != null &&
      (data['razorpay_key'] as String?) != null;

  /// Opens Razorpay checkout for [data] (the `data` object of a create/
  /// update response that [needsPayment]) and calls [onDone] once the
  /// payment succeeds, or [onError] if it fails/is cancelled. [payableAmount]
  /// is the amount in rupees to charge.
  Future<void> pay({
    required BuildContext context,
    required Map<String, dynamic> data,
    required int payableAmount,
    required VoidCallback onDone,
    required void Function(String message) onError,
  }) async {
    final l10n = AppLocalizations.of(context);
    final keyId = data['razorpay_key'] as String?;
    final razorpayOrderId = data['razorpay_order_id'] as String?;
    if (keyId == null || razorpayOrderId == null) {
      onError(l10n.razorpayOrderMissing);
      return;
    }
    final user = await CurrentUser.load();

    _pendingRazorpayOrderId = razorpayOrderId;
    _razorpay?.dispose();
    _razorpay = RazorpayService(
      onSuccess: (response) {
        _confirmStatus(
          status: 'success',
          paymentId: response.paymentId,
          signature: response.signature,
        );
        onDone();
      },
      onError: (response) {
        final isCancelled = response.code == Razorpay.PAYMENT_CANCELLED;
        _confirmStatus(status: isCancelled ? 'pending' : 'failed');
        onError(
          isCancelled
              ? l10n.paymentCancelled
              : l10n.paymentFailedWithReason(response.message ?? ''),
        );
      },
    );
    _razorpay!.open(
      keyId: keyId,
      razorpayOrderId: razorpayOrderId,
      amountInPaise: payableAmount * 100,
      name: user?.name,
      email: user?.email,
      contact: user?.phone,
    );
  }

  /// Reports the checkout outcome per `POST /customer/orders/razorpay/status`
  /// — best-effort, matching `PaymentScreen`'s own version.
  Future<void> _confirmStatus({
    required String status,
    String? paymentId,
    String? signature,
  }) async {
    final orderId = _pendingRazorpayOrderId;
    if (orderId == null) return;
    try {
      await apiService.post(
        '/customer/orders/razorpay/status',
        data: {
          'razorpay_order_id': orderId,
          'status': status,
          'razorpay_payment_id': ?paymentId,
          'razorpay_signature': ?signature,
        },
      );
    } catch (e) {
      debugPrint('Razorpay status confirmation error: $e');
    }
  }

  void dispose() => _razorpay?.dispose();
}
