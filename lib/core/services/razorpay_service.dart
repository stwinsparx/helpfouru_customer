import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Thin wrapper around the `razorpay_flutter` plugin so screens don't touch
/// the SDK directly. Callers must call [dispose] when done (e.g. in the
/// hosting widget's `dispose()`) to release native listeners.
class RazorpayService {
  RazorpayService({
    required void Function(PaymentSuccessResponse response) onSuccess,
    required void Function(PaymentFailureResponse response) onError,
    void Function(ExternalWalletResponse response)? onExternalWallet,
  }) : _razorpay = Razorpay() {
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onError);
    if (onExternalWallet != null) {
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
    }
  }

  final Razorpay _razorpay;

  /// Opens Razorpay checkout for a server-created [razorpayOrderId] using
  /// the [keyId] returned alongside it by `POST /customer/orders`
  /// (`data.razorpay_key`) — the key is per-merchant/environment, so it
  /// always comes from the backend rather than being hardcoded client-side.
  /// [amountInPaise] and [currency] should match what the server used to
  /// create that order. [name]/[email]/[contact] prefill the checkout form
  /// when known.
  void open({
    required String keyId,
    required String razorpayOrderId,
    required int amountInPaise,
    String currency = 'INR',
    String description = 'HelpFourU service booking',
    String? name,
    String? email,
    String? contact,
  }) {
    _razorpay.open({
      'key': keyId,
      'order_id': razorpayOrderId,
      'amount': amountInPaise,
      'currency': currency,
      'name': 'HelpFourU',
      'description': description,
      'prefill': {
        'name': ?name,
        'email': ?email,
        'contact': ?contact,
      },
    });
  }

  void dispose() => _razorpay.clear();
}
