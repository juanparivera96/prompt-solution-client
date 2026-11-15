import 'ai_recommendation.dart';
import 'payment_product.dart';

/// What the bank knows about the customer's money at the moment of paying.
/// The app sends it to the recommendation API with every purchase.
///
/// It is derived from the customer's products, which the app loads when the
/// session starts: nobody types a balance.
class CustomerContext {
  /// Money available to pay by debit or transfer, in COP (`saldo_cop`).
  final double balanceCop;

  /// Share of the credit limit in use, 0-1 (`uso_cupo`). It is 1 when the
  /// customer has no credit: the model requires the variable, and 1 tells
  /// it there is no credit left to pay with.
  final double creditUsage;

  /// Payment methods the customer owns a product for (`medios`).
  final Set<PaymentMethod> methods;

  const CustomerContext({
    required this.balanceCop,
    required this.creditUsage,
    required this.methods,
  });

  factory CustomerContext.fromProducts(List<PaymentProduct> products) {
    // The debit card draws from the customer's account, so both show the
    // same money; with several accounts, the fullest one can pay the most.
    var balance = 0.0;
    var limit = 0.0;
    var used = 0.0;
    for (final product in products) {
      final productBalance = product.balanceCop;
      if (productBalance != null && productBalance > balance) {
        balance = productBalance;
      }
      limit += product.creditLimitCop ?? 0;
      used += product.creditUsedCop ?? 0;
    }
    return CustomerContext(
      balanceCop: balance,
      creditUsage: limit > 0 ? (used / limit).clamp(0, 1).toDouble() : 1,
      methods: {for (final p in products) PaymentMethod.ofProduct(p.type)},
    );
  }

  bool get hasCredit => methods.contains(PaymentMethod.credit);

  /// The `cliente` block of `POST /v1/recomendacion`.
  Map<String, dynamic> toJson() => {
        'saldo_cop': balanceCop,
        'uso_cupo': creditUsage,
        'medios': [
          for (final method in PaymentMethod.values)
            if (methods.contains(method)) method.apiCode,
        ],
      };
}
